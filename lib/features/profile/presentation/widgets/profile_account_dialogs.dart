import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/data/auth_api.dart';
import '../../../main/presentation/widgets/main_home_icons.dart';
import '../../../main/presentation/widgets/web_dialog_helper.dart';
import '../../logic/profile_actions.dart';

/// Modal `<dialog>` for editing academic / learner profile (`PATCH /users/me`).
class ProfileAboutYouDialog extends StatefulComponent {
  const ProfileAboutYouDialog({
    required this.open,
    required this.user,
    required this.onClose,
    required this.onSaved,
    super.key,
  });

  final bool open;
  final Map<String, dynamic> user;
  final VoidCallback onClose;
  final ValueChanged<Map<String, dynamic>> onSaved;

  @override
  State<ProfileAboutYouDialog> createState() => _ProfileAboutYouDialogState();
}

class _ProfileAboutYouDialogState extends State<ProfileAboutYouDialog> {
  static const _dialogId = 'eduma-about-you-dialog';

  String _level = '';
  String _field = '';
  String _school = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _syncFromUser();
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  @override
  void didUpdateComponent(covariant ProfileAboutYouDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!oldComponent.open && component.open) {
      setState(() {
        _syncFromUser();
        _saving = false;
        _error = null;
      });
    }
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  void _syncFromUser() {
    final user = component.user;
    _level = '${user['level'] ?? ''}'.trim();
    _field = '${user['fieldOfStudy'] ?? user['department'] ?? ''}'.trim();
    final inst = user['institution'];
    _school = inst is Map
        ? '${inst['name'] ?? inst['shortName'] ?? ''}'.trim()
        : '${inst ?? user['school'] ?? ''}'.trim();
  }

  void _dismiss() {
    if (_saving) return;
    WebDialogHelper.resetReturnValue(_dialogId);
    component.onClose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ProfileActions.updateLearnerProfile(
        level: _level,
        fieldOfStudy: _field,
        school: _school,
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
      setState(() => _error = 'Could not update your academic details.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Component build(BuildContext context) => dialog(
    id: _dialogId,
    classes: 'eduma-modal',
    attributes: {
      'closedby': 'any',
      'aria-labelledby': 'eduma-about-you-title',
    },
    events: {
      'close': (_) {
        if (component.open) _dismiss();
      },
    },
    [
      div(classes: 'eduma-modal__header', [
        div(classes: 'eduma-modal__title', [
          h2(id: 'eduma-about-you-title', [.text('About you')]),
          p([.text('Personalize recommendations with your school, level, and field of study.')]),
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
              label(htmlFor: 'eduma-about-school', [.text('School or institution')]),
              input<String>(
                id: 'eduma-about-school',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _school,
                disabled: _saving,
                attributes: {'placeholder': 'e.g. University of Lagos', 'maxlength': '120'},
                onInput: (value) => setState(() => _school = value),
              ),
            ]),
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'eduma-about-field', [.text('Field of study')]),
              input<String>(
                id: 'eduma-about-field',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _field,
                disabled: _saving,
                attributes: {'placeholder': 'e.g. Computer Science', 'maxlength': '120'},
                onInput: (value) => setState(() => _field = value),
              ),
            ]),
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'eduma-about-level', [.text('Level')]),
              input<String>(
                id: 'eduma-about-level',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _level,
                disabled: _saving,
                attributes: {'placeholder': 'e.g. 200', 'maxlength': '40'},
                onInput: (value) => setState(() => _level = value),
              ),
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
              disabled: _saving,
              [.text(_saving ? 'Saving…' : 'Save details')],
            ),
          ]),
        ],
      ),
    ],
  );
}

/// Destructive confirmation `<dialog>` for `DELETE /users/me`.
class ProfileDeleteAccountDialog extends StatefulComponent {
  const ProfileDeleteAccountDialog({
    required this.open,
    required this.onClose,
    required this.onDeleted,
    super.key,
  });

  final bool open;
  final VoidCallback onClose;
  final VoidCallback onDeleted;

  @override
  State<ProfileDeleteAccountDialog> createState() => _ProfileDeleteAccountDialogState();
}

class _ProfileDeleteAccountDialogState extends State<ProfileDeleteAccountDialog> {
  static const _dialogId = 'eduma-delete-account-dialog';

  String _confirmText = '';
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  @override
  void didUpdateComponent(covariant ProfileDeleteAccountDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!oldComponent.open && component.open) {
      setState(() {
        _confirmText = '';
        _deleting = false;
        _error = null;
      });
    }
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  void _dismiss() {
    if (_deleting) return;
    WebDialogHelper.resetReturnValue(_dialogId);
    component.onClose();
  }

  Future<void> _submit() async {
    if (_deleting || _confirmText.trim().toUpperCase() != 'DELETE') return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ProfileActions.deleteAccount();
      if (!mounted) return;
      WebDialogHelper.resetReturnValue(_dialogId);
      component.onClose();
      component.onDeleted();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not delete your account right now.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Component build(BuildContext context) {
    final ready = _confirmText.trim().toUpperCase() == 'DELETE';
    return dialog(
      id: _dialogId,
      classes: 'eduma-modal',
      attributes: {
        'closedby': 'any',
        'aria-labelledby': 'eduma-delete-account-title',
      },
      events: {
        'close': (_) {
          if (component.open) _dismiss();
        },
      },
      [
        div(classes: 'eduma-modal__header', [
          div(classes: 'eduma-modal__title', [
            h2(id: 'eduma-delete-account-title', [.text('Delete account')]),
            p([.text('This permanently deletes your profile, spaces, and study history.')]),
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
                label(htmlFor: 'eduma-delete-confirm', [.text('Type DELETE to confirm')]),
                input<String>(
                  id: 'eduma-delete-confirm',
                  classes: 'eduma-modal__input',
                  type: InputType.text,
                  value: _confirmText,
                  disabled: _deleting,
                  attributes: {'placeholder': 'DELETE', 'autocomplete': 'off'},
                  onInput: (value) => setState(() {
                    _confirmText = value;
                    _error = null;
                  }),
                ),
              ]),
              if (_error case final msg?)
                p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(msg)]),
            ]),
            div(classes: 'eduma-modal__footer', [
              button(
                classes: 'eduma-modal__btn',
                type: ButtonType.button,
                disabled: _deleting,
                onClick: _dismiss,
                [.text('Cancel')],
              ),
              button(
                classes: 'eduma-modal__btn eduma-modal__btn--danger',
                type: ButtonType.submit,
                disabled: !ready || _deleting,
                [.text(_deleting ? 'Deleting…' : 'Delete account')],
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
