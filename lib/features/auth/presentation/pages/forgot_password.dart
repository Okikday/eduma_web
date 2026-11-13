import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

import '../../logic/auth_actions.dart';
import '../../logic/sign_up_logic.dart';
import '../widgets/auth_frame.dart';

class ForgotPasswordPage extends StatefulComponent {
  const ForgotPasswordPage({super.key, this.email = '', this.token = ''});

  final String email;
  final String token;

  @override
  State<ForgotPasswordPage> createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  String _email = '';
  String _token = '';
  String _newPassword = '';
  bool _resetStep = false;
  bool _passwordVisible = false;
  bool _loading = false;
  bool _requestSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = component.email;
    _token = component.token;
    _resetStep = _token.isNotEmpty;
    if (_resetStep) AuthActions.scrubTokenFromAddressBar();
  }

  void _showValidationError(String message, String targetId) {
    setState(() => _error = message);
    unawaited(
      Future<void>.delayed(Duration.zero, () {
        if (!mounted) return;
        (web.document.getElementById(targetId) as web.HTMLElement?)?.focus();
      }),
    );
  }

  Future<void> _requestCode() async {
    final email = _email.trim();
    if (!SignUpLogic.validEmail(email)) {
      _showValidationError('Enter a valid email address.', 'auth-email');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthActions.requestPasswordReset(email);
      if (mounted) {
        setState(() {
          _requestSent = true;
          _resetStep = true;
        });
      }
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_token.trim().isEmpty) {
      _showValidationError('Enter the code or link from your email.', 'auth-resetToken');
      return;
    }
    if (_newPassword.length < 8) {
      _showValidationError(
        'Your new password must be at least 8 characters.',
        'auth-newPassword',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthActions.resetPassword(
        token: _token,
        newPassword: _newPassword,
      );
      if (mounted) web.window.location.assign('/sign-in');
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.statusCode == 401 || error.statusCode == 404 || error.statusCode == 410
              ? 'That link or code is invalid or has expired. Request a new one.'
              : error.message,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_resetStep) {
      setState(() {
        _resetStep = false;
        _requestSent = false;
        _error = null;
      });
    } else {
      web.window.location.assign('/sign-in');
    }
  }

  @override
  Component build(BuildContext context) {
    final title = _resetStep ? 'Set New Password' : 'Reset Password';
    final subtitle = _resetStep
        ? 'Enter the 6-digit code from the email we sent you (or paste its link), then choose a new password'
        : 'Enter your email address and we will send you a 6-digit code (and a link)';

    return authDesktopFrame(
      main_(classes: 'auth-page auth-page--route', [
        authRouteTopBar(
          label: _resetStep ? 'Back to email' : 'Back',
          onBack: _back,
        ),
        section(classes: 'auth-route-content', [
          authHeader(title: title, subtitle: subtitle),
          form(
            classes: 'auth-route-form',
            noValidate: true,
            events: {
              'submit': (event) {
                event.preventDefault();
                if (_loading) return;
                unawaited(_resetStep ? _resetPassword() : _requestCode());
              },
            },
            [
              if (_error case final message?) authError(message),
              if (!_resetStep) ...[
                authField(
                  labelText: 'Email Address',
                  name: 'email',
                  value: _email,
                  type: InputType.email,
                  autocomplete: 'email',
                  identifier: true,
                  placeholder: 'alex@eduma.com.ng',
                  icon: 'mail',
                  enterKeyHint: 'done',
                  onInput: (value) => setState(() {
                    _email = value;
                    _error = null;
                  }),
                ),
                authSubmitButton('Send Code', loading: _loading),
              ] else ...[
                if (_requestSent)
                  authSuccess(
                    'If an account exists for this address, a reset code and link are on their way.',
                  ),
                authField(
                  labelText: 'Code from the email',
                  name: 'resetToken',
                  value: _token,
                  type: InputType.text,
                  autocomplete: 'one-time-code',
                  identifier: true,
                  placeholder: '6-digit code, or paste the link',
                  icon: 'ticket',
                  enterKeyHint: 'next',
                  onInput: (value) => setState(() {
                    _token = value;
                    _error = null;
                  }),
                ),
                authField(
                  labelText: 'New Password (min. 8 characters)',
                  name: 'newPassword',
                  value: _newPassword,
                  type: _passwordVisible ? InputType.text : InputType.password,
                  autocomplete: 'new-password',
                  placeholder: '••••••••',
                  icon: 'lock',
                  enterKeyHint: 'done',
                  onInput: (value) => setState(() {
                    _newPassword = value;
                    _error = null;
                  }),
                  suffix: button(
                    classes: 'auth-field-suffix',
                    type: ButtonType.button,
                    onClick: () => setState(() => _passwordVisible = !_passwordVisible),
                    attributes: {
                      'aria-label': _passwordVisible ? 'Hide password' : 'Show password',
                    },
                    [authIcon(_passwordVisible ? 'eye' : 'eye-off')],
                  ),
                ),
                authSubmitButton('Update Password', loading: _loading),
              ],
            ],
          ),
          div(classes: 'auth-back-to-sign-in', [
            Link(
              to: '/sign-in',
              child: span([.text('Back to Sign In')]),
            ),
          ]),
        ]),
      ]),
    );
  }
}
