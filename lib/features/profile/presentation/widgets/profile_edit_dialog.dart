import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/data/auth_api.dart';
import '../../../main/presentation/widgets/main_home_icons.dart';
import '../../../main/presentation/widgets/web_dialog_helper.dart';
import '../../logic/profile_actions.dart';

/// Native modal `<dialog>` for editing display name and username (`PATCH /users/me`).
class ProfileEditDialog extends StatefulComponent {
  const ProfileEditDialog({
    required this.open,
    required this.currentName,
    required this.currentUsername,
    required this.onClose,
    required this.onSaved,
    super.key,
  });

  final bool open;
  final String currentName;
  final String currentUsername;
  final VoidCallback onClose;
  final ValueChanged<Map<String, dynamic>> onSaved;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  static const _dialogId = 'eduma-edit-profile-dialog';
  static const _checkDelay = Duration(milliseconds: 300);

  String _name = '';
  String _username = '';
  bool _checking = false;
  bool? _available;
  String? _usernameError;
  bool _saving = false;
  String? _error;
  Timer? _debounce;
  int _checkSeq = 0;

  @override
  void initState() {
    super.initState();
    _resetFromComponent();
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  @override
  void didUpdateComponent(covariant ProfileEditDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!oldComponent.open && component.open) {
      _resetFromComponent();
    }
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _resetFromComponent() {
    _debounce?.cancel();
    _checkSeq++;
    _name = component.currentName;
    _username = component.currentUsername;
    _checking = false;
    _available = null;
    _usernameError = null;
    _saving = false;
    _error = null;
  }

  void _onUsernameInput(String raw) {
    _debounce?.cancel();
    final seq = ++_checkSeq;
    setState(() {
      _username = raw;
      _error = null;
    });

    if (!EditProfileLogic.usernameChanged(raw, component.currentUsername)) {
      setState(() {
        _checking = false;
        _available = null;
        _usernameError = null;
      });
      return;
    }

    final problem = EditProfileLogic.usernameProblem(raw, component.currentUsername);
    if (problem != null) {
      setState(() {
        _checking = false;
        _available = false;
        _usernameError = problem;
      });
      return;
    }

    setState(() {
      _checking = true;
      _available = null;
      _usernameError = null;
    });

    _debounce = Timer(_checkDelay, () async {
      final result = await ProfileActions.checkUsername(raw);
      if (!mounted || seq != _checkSeq) return;
      setState(() {
        _checking = false;
        _available = result == true;
        _usernameError = result == false ? 'Username is already taken.' : null;
      });
    });
  }

  void _dismiss() {
    if (_saving) return;
    WebDialogHelper.resetReturnValue(_dialogId);
    component.onClose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final canSave = EditProfileLogic.canSave(
      name: _name,
      currentName: component.currentName,
      username: _username,
      currentUsername: component.currentUsername,
      usernameAvailable: _available,
      isCheckingUsername: _checking,
    );
    if (!canSave) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final changedUsername = EditProfileLogic.usernameChanged(
        _username,
        component.currentUsername,
      );
      final updated = await ProfileActions.updateProfile(
        name: _name,
        username: changedUsername ? _username : null,
      );
      if (!mounted) return;
      WebDialogHelper.resetReturnValue(_dialogId);
      component.onClose();
      component.onSaved(updated);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not update your profile right now.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Component build(BuildContext context) {
    final canSave = EditProfileLogic.canSave(
      name: _name,
      currentName: component.currentName,
      username: _username,
      currentUsername: component.currentUsername,
      usernameAvailable: _available,
      isCheckingUsername: _checking,
    );

    return dialog(
      id: _dialogId,
      classes: 'eduma-modal',
      attributes: {
        'closedby': 'any',
        'aria-labelledby': 'eduma-edit-profile-title',
      },
      events: {
        'close': (_) {
          if (component.open) _dismiss();
        },
      },
      [
        div(classes: 'eduma-modal__header', [
          div(classes: 'eduma-modal__title', [
            h2(id: 'eduma-edit-profile-title', [.text('Edit profile')]),
            p([.text('Update how your name and handle appear to space members.')]),
          ]),
          button(
            classes: 'eduma-modal__close',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close dialog'},
            onClick: _dismiss,
            [mainHomeIcon(.close, size: 18)],
          ),
        ]),
        form(
          events: {
            'submit': (event) {
              event.preventDefault();
              unawaited(_submit());
            },
          },
          [
            div(classes: 'eduma-modal__body', [
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-profile-name', [.text('Display name')]),
                input<String>(
                  id: 'eduma-profile-name',
                  classes: 'eduma-modal__input',
                  type: InputType.text,
                  value: _name,
                  disabled: _saving,
                  attributes: {'autofocus': 'true'},
                  onInput: (value) => setState(() {
                    _name = value;
                    _error = null;
                  }),
                ),
              ]),
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-profile-username', [.text('Username')]),
                input<String>(
                  id: 'eduma-profile-username',
                  classes: 'eduma-modal__input',
                  type: InputType.text,
                  value: _username,
                  disabled: _saving,
                  attributes: {'placeholder': 'username'},
                  onInput: _onUsernameInput,
                ),
                if (_checking)
                  p(classes: 'eduma-modal__hint', [.text('Checking availability…')])
                else if (_usernameError != null)
                  p(classes: 'eduma-modal__error', [.text(_usernameError!)])
                else if (_available == true)
                  p(classes: 'eduma-profile__hint-ok', [.text('Username is available.')]),
              ]),
              if (_error case final msg?)
                p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(msg)]),
            ]),
            div(classes: 'eduma-modal__footer', [
              button(
                classes: 'eduma-modal__btn',
                type: ButtonType.button,
                disabled: _saving,
                onClick: _dismiss,
                [.text('Cancel')],
              ),
              button(
                classes: 'eduma-modal__btn eduma-modal__btn--primary',
                type: ButtonType.submit,
                disabled: _saving || !canSave,
                [.text(_saving ? 'Saving…' : 'Save changes')],
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
