import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/data/auth_api.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../main/presentation/widgets/web_dialog_helper.dart';
import '../../logic/profile_actions.dart';

/// Native modal `<dialog>` port of `EditProfileSheet` in `../eduma`: the full
/// name (`PATCH /users/me`) over the read-only account email.
class ProfileEditDialog extends StatefulComponent {
  const ProfileEditDialog({
    required this.open,
    required this.currentName,
    required this.currentUsername,
    required this.email,
    required this.onClose,
    required this.onSaved,
    super.key,
  });

  final bool open;
  final String currentName;
  final String currentUsername;
  final String email;
  final VoidCallback onClose;
  final ValueChanged<Map<String, dynamic>> onSaved;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  static const _dialogId = 'eduma-edit-profile-dialog';

  String _name = '';
  bool _saving = false;
  String? _error;

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

  void _resetFromComponent() {
    _name = component.currentName;
    _saving = false;
    _error = null;
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
      username: component.currentUsername,
      currentUsername: component.currentUsername,
      usernameAvailable: null,
      isCheckingUsername: false,
    );
    if (!canSave) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await ProfileActions.updateProfile(name: _name);
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
      username: component.currentUsername,
      currentUsername: component.currentUsername,
      usernameAvailable: null,
      isCheckingUsername: false,
    );

    return dialog(
      id: _dialogId,
      classes: 'eduma-modal',
      attributes: {
        ...WebDialogHelper.openAttr(component.open),
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
            h2(id: 'eduma-edit-profile-title', [.text('Edit Profile')]),
            p([.text('Update your name as it appears to instructors and space members')]),
          ]),
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
                label(htmlFor: 'eduma-profile-name', [.text('Full Name')]),
                div(classes: 'eduma-modal__input-wrap', [
                  edumaIcon(EdumaIcons.user, size: 20),
                  input<String>(
                    id: 'eduma-profile-name',
                    classes: 'eduma-modal__input',
                    type: InputType.text,
                    value: _name,
                    disabled: _saving,
                    attributes: {'placeholder': 'Enter your name', 'autocomplete': 'name'},
                    onInput: (value) => setState(() {
                      _name = value;
                      _error = null;
                    }),
                  ),
                ]),
              ]),
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-profile-email', [.text('Email')]),
                div(classes: 'eduma-modal__input-wrap', [
                  edumaIcon(EdumaIcons.mail, size: 20),
                  input<String>(
                    id: 'eduma-profile-email',
                    classes: 'eduma-modal__input',
                    type: InputType.email,
                    value: component.email,
                    disabled: true,
                    attributes: {'readonly': ''},
                  ),
                ]),
              ]),
              if (_error case final msg?) p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(msg)]),
            ]),
            div(classes: 'eduma-modal__footer', [
              button(
                classes: 'eduma-modal__btn eduma-modal__btn--primary',
                type: ButtonType.submit,
                disabled: _saving || !canSave,
                [.text(_saving ? 'Saving…' : 'Save Changes')],
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
