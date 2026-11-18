import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/data/auth_api.dart';
import '../../../../core/presentation/eduma_icons.dart';
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
    });
    try {
      await ProfileActions.sendPasswordResetCode(component.email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
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
        ...WebDialogHelper.openAttr(component.open),
        'closedby': 'any',
        'aria-labelledby': 'eduma-password-dialog-title',
      },
      events: {
        'close': (_) {
          if (component.open) _dismiss();
        },
      },
      [
        // Two steps like `ChangePasswordSheet` in ../eduma: an intro that
        // emails the code, then the code and the new password.
        if (!_codeSent) ...[
          div(classes: 'eduma-modal__header', [
            div(classes: 'eduma-modal__title', [
              h2(id: 'eduma-password-dialog-title', [.text('Change password')]),
              p([.text("We'll email you a code to confirm it's you.")]),
            ]),
          ]),
          div(classes: 'eduma-modal__body', [
            if (_error case final msg?) p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(msg)]),
            p(classes: 'eduma-modal__copy', [
              .text(
                component.email.trim().isEmpty
                    ? 'Your account has no email address.'
                    : 'The code goes to ${component.email}.',
              ),
            ]),
            p(classes: 'eduma-modal__copy', [
              .text(
                'Saving the new password signs you out on your other devices and the WhatsApp bot. '
                'This device stays signed in.',
              ),
            ]),
          ]),
          div(classes: 'eduma-modal__footer', [
            button(
              classes: 'eduma-modal__btn eduma-modal__btn--primary',
              type: ButtonType.button,
              disabled: _sendingCode || component.email.trim().isEmpty,
              onClick: () => unawaited(_sendCode()),
              [.text(_sendingCode ? 'Sending…' : 'Email me a code')],
            ),
          ]),
        ] else ...[
          div(classes: 'eduma-modal__header', [
            div(classes: 'eduma-modal__title', [
              h2(id: 'eduma-password-dialog-title', [.text('Enter the code')]),
              p([.text('We sent it to ${component.email}. Check spam too.')]),
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
                if (_error case final msg?)
                  p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(msg)]),
                _field(
                  id: 'eduma-pw-code',
                  title: 'Code',
                  hint: 'The code or link from the email',
                  icon: EdumaIcons.sms,
                  value: _resetInput,
                  type: InputType.text,
                  onInput: (value) => _resetInput = value,
                  autocomplete: 'one-time-code',
                ),
                _field(
                  id: 'eduma-pw-new',
                  title: 'New password',
                  hint: 'At least 8 characters',
                  icon: EdumaIcons.lock,
                  value: _password,
                  type: InputType.password,
                  onInput: (value) => _password = value,
                  autocomplete: 'new-password',
                ),
                _field(
                  id: 'eduma-pw-confirm',
                  title: 'Repeat new password',
                  hint: 'Type it again',
                  icon: EdumaIcons.lock,
                  value: _confirm,
                  type: InputType.password,
                  onInput: (value) => _confirm = value,
                  autocomplete: 'new-password',
                ),
                if (problem case final pMsg?) p(classes: 'eduma-modal__hint', [.text(pMsg)]),
              ]),
              div(classes: 'eduma-modal__footer', [
                button(
                  classes: 'eduma-modal__btn',
                  type: ButtonType.button,
                  disabled: _sendingCode || _saving,
                  onClick: () => unawaited(_sendCode()),
                  [.text(_sendingCode ? 'Sending…' : 'New code')],
                ),
                button(
                  classes: 'eduma-modal__btn eduma-modal__btn--primary',
                  type: ButtonType.submit,
                  disabled: _saving || !canSubmit,
                  [.text(_saving ? 'Saving…' : 'Change password')],
                ),
              ]),
            ],
          ),
        ],
      ],
    );
  }

  Component _field({
    required String id,
    required String title,
    required String hint,
    required Object icon,
    required String value,
    required InputType type,
    required void Function(String) onInput,
    required String autocomplete,
  }) => div(classes: 'eduma-modal__field', [
    label(htmlFor: id, [.text(title)]),
    div(classes: 'eduma-modal__input-wrap', [
      edumaIcon(icon, size: 20),
      input<String>(
        id: id,
        classes: 'eduma-modal__input',
        type: type,
        value: value,
        disabled: _saving,
        attributes: {'placeholder': hint, 'autocomplete': autocomplete},
        onInput: (next) => setState(() {
          onInput(next);
          _error = null;
        }),
      ),
    ]),
  ]);
}
