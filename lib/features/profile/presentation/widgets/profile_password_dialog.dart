import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/data/auth_api.dart';
import '../../../main/presentation/widgets/main_home_icons.dart';
import '../../../main/presentation/widgets/web_dialog_helper.dart';
import '../../logic/profile_actions.dart';

/// Native modal `<dialog>` for changing password using an emailed reset code.
class ProfilePasswordDialog extends StatefulComponent {
  const ProfilePasswordDialog({
    required this.open,
    required this.email,
    required this.onClose,
    required this.onChanged,
    super.key,
  });

  final bool open;
  final String email;
  final VoidCallback onClose;
  final ValueChanged<EdumaSession> onChanged;

  @override
  State<ProfilePasswordDialog> createState() => _ProfilePasswordDialogState();
}

class _ProfilePasswordDialogState extends State<ProfilePasswordDialog> {
  static const _dialogId = 'eduma-password-dialog';

  String _resetInput = '';
  String _password = '';
  String _confirm = '';
  bool _sendingCode = false;
  bool _codeSent = false;
  bool _saving = false;
  String? _statusMessage;
  String? _error;

  @override
  void initState() {
    super.initState();
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  @override
  void didUpdateComponent(covariant ProfilePasswordDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!oldComponent.open && component.open) {
      setState(() {
        _resetInput = '';
        _password = '';
        _confirm = '';
        _sendingCode = false;
        _codeSent = false;
        _saving = false;
        _statusMessage = null;
        _error = null;
      });
    }
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  void _dismiss() {
    if (_saving) return;
    WebDialogHelper.resetReturnValue(_dialogId);
    component.onClose();
  }

  Future<void> _sendCode() async {
    if (_sendingCode || component.email.trim().isEmpty) return;
    setState(() {
      _sendingCode = true;
      _error = null;
      _statusMessage = null;
    });
    try {
      await ProfileActions.sendPasswordResetCode(component.email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _statusMessage = 'Sent a reset code to ${component.email}.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not send reset code right now.');
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!ChangePasswordLogic.canSubmit(
      codeInput: _resetInput,
      password: _password,
      confirm: _confirm,
    )) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final newSession = await ProfileActions.resetPasswordAndSignIn(
        email: component.email,
        rawCodeOrLink: _resetInput,
        newPassword: _password,
      );
      if (!mounted) return;
      WebDialogHelper.resetReturnValue(_dialogId);
      component.onClose();
      component.onChanged(newSession);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not update your password. Check the code and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Component build(BuildContext context) {
    final problem = ChangePasswordLogic.passwordProblem(_password, _confirm);
    final canSubmit = ChangePasswordLogic.canSubmit(
      codeInput: _resetInput,
      password: _password,
      confirm: _confirm,
    );

    return dialog(
      id: _dialogId,
      classes: 'eduma-modal',
      attributes: {
        'closedby': 'any',
        'aria-labelledby': 'eduma-password-dialog-title',
      },
      events: {
        'close': (_) {
          if (component.open) _dismiss();
        },
      },
      [
        div(classes: 'eduma-modal__header', [
          div(classes: 'eduma-modal__title', [
            h2(id: 'eduma-password-dialog-title', [.text('Password & security')]),
            p([.text('Request a one-time code to ${component.email}, then set a new password.')]),
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
              div(classes: 'eduma-profile__code-row', [
                button(
                  classes: 'main-home__action-button',
                  type: ButtonType.button,
                  disabled: _sendingCode || _saving,
                  onClick: () => unawaited(_sendCode()),
                  [
                    mainHomeIcon(.email, size: 15),
                    .text(
                      _sendingCode
                          ? 'Sending…'
                          : _codeSent
                          ? 'Resend code'
                          : 'Email verification code',
                    ),
                  ],
                ),
              ]),
              if (_statusMessage case final status?)
                p(classes: 'eduma-profile__hint-ok', [.text(status)]),
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-pw-code', [.text('Reset code or link')]),
                input<String>(
                  id: 'eduma-pw-code',
                  classes: 'eduma-modal__input',
                  type: InputType.text,
                  value: _resetInput,
                  disabled: _saving,
                  attributes: {'placeholder': 'Paste reset code or link'},
                  onInput: (value) => setState(() {
                    _resetInput = value;
                    _error = null;
                  }),
                ),
              ]),
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-pw-new', [.text('New password')]),
                input<String>(
                  id: 'eduma-pw-new',
                  classes: 'eduma-modal__input',
                  type: InputType.password,
                  value: _password,
                  disabled: _saving,
                  attributes: {'placeholder': 'At least 8 characters'},
                  onInput: (value) => setState(() {
                    _password = value;
                    _error = null;
                  }),
                ),
              ]),
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-pw-confirm', [.text('Confirm new password')]),
                input<String>(
                  id: 'eduma-pw-confirm',
                  classes: 'eduma-modal__input',
                  type: InputType.password,
                  value: _confirm,
                  disabled: _saving,
                  attributes: {'placeholder': 'Repeat new password'},
                  onInput: (value) => setState(() {
                    _confirm = value;
                    _error = null;
                  }),
                ),
              ]),
              if (problem case final pMsg?)
                p(classes: 'eduma-modal__error', [.text(pMsg)]),
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
                disabled: _saving || !canSubmit,
                [.text(_saving ? 'Updating…' : 'Update password')],
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
