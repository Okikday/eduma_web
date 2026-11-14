import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

import '../../logic/auth_actions.dart';
import '../../logic/sign_up_logic.dart';
import '../widgets/auth_frame.dart';

class SignInPage extends StatefulComponent {
  const SignInPage({super.key, this.email = ''});

  final String email;

  @override
  State<SignInPage> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  String _email = '';
  String _password = '';
  bool _passwordVisible = false;
  bool _termsAccepted = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = component.email;
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

  Future<void> _submit() async {
    final email = _email.trim();
    if (!SignUpLogic.validEmail(email)) {
      _showValidationError('Enter a valid email address.', 'auth-email');
      return;
    }
    if (_password.length < 8) {
      _showValidationError('Please enter a valid password.', 'auth-password');
      return;
    }
    if (!_termsAccepted) {
      _showValidationError(
        'Please read and agree to the Terms of Service to continue.',
        'auth-consent',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthActions.signIn(email: email, password: _password);
      if (mounted) web.window.location.assign('/main');
    } on AuthApiException catch (error) {
      if (error.isEmailNotVerified) {
        await AuthActions.acceptPendingSession(error);
        if (mounted) {
          web.window.location.assign(
            Uri(
              path: '/verify-email',
              queryParameters: {'email': email},
            ).toString(),
          );
        }
      } else if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeGoogleSignIn(String idToken) async {
    if (idToken.isEmpty || _loading) return;
    if (!_termsAccepted) {
      setState(
        () => _error = 'Please agree to the Terms of Service and acknowledge the Privacy Policy before continuing.',
      );
      return;
    }
    if (edumaGoogleWebClientId.isEmpty) {
      setState(
        () => _error = 'Google sign-in is not configured. Please sign in with your email instead.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthActions.googleSignIn(idToken);
      if (mounted) web.window.location.assign('/main');
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _googleButtonPressed() {
    setState(() {
      _error = !_termsAccepted
          ? 'Please agree to the Terms of Service and acknowledge the Privacy Policy before continuing.'
          : 'Google sign-in is not configured. Please sign in with your email instead.';
    });
  }

  @override
  Component build(BuildContext context) => authDesktopFrame(
    main_(
      classes: 'auth-page auth-page--sign-in',
      [
        input<String>(
          id: 'google-id-token',
          classes: 'auth-hidden-input',
          type: InputType.hidden,
          value: '',
          onInput: (token) => unawaited(_completeGoogleSignIn(token)),
          attributes: {'aria-hidden': 'true', 'tabindex': '-1'},
        ),
        div(classes: 'auth-header auth-header--sign-in', [
          h1(classes: 'auth-title', [
            .text('Welcome to Eduma'),
          ]),
          p(classes: 'auth-subtitle', [
            .text('Sign in, or create an account to get started'),
          ]),
        ]),
        form(
          classes: 'auth-form auth-form--sign-in',
          noValidate: true,
          events: {
            'submit': (event) {
              event.preventDefault();
              if (!_loading) unawaited(_submit());
            },
          },
          [
            if (_error case final message?) authError(message),
            authField(
              labelText: 'Email Address',
              name: 'email',
              value: _email,
              type: InputType.email,
              autocomplete: 'username',
              identifier: true,
              placeholder: 'Enter your email address',
              icon: 'mail',
              onInput: (value) => setState(() {
                _email = value;
                _error = null;
              }),
              suffix: _email.isEmpty
                  ? null
                  : button(
                      classes: 'auth-field-suffix',
                      type: ButtonType.button,
                      onClick: () => setState(() {
                        _email = '';
                        _error = null;
                      }),
                      attributes: {'aria-label': 'Clear email address'},
                      [authIcon('close', size: 18)],
                    ),
            ),
            authField(
              labelText: 'Password',
              name: 'password',
              value: _password,
              type: _passwordVisible ? InputType.text : InputType.password,
              autocomplete: 'current-password',
              placeholder: '••••••••',
              icon: 'lock',
              onInput: (value) => setState(() {
                _password = value;
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
            div(classes: 'auth-row--end', [
              Link(
                to: Uri(
                  path: '/forgot-password',
                  queryParameters: {
                    if (_email.trim().isNotEmpty) 'email': _email.trim(),
                  },
                ).toString(),
                child: span(classes: 'auth-link auth-link-button', [
                  .text('Forgot password?'),
                ]),
              ),
            ]),
            authConsent(
              value: _termsAccepted,
              disabled: _loading,
              onChanged: (value) => setState(() {
                _termsAccepted = value;
                _error = null;
              }),
            ),
            authSubmitButton(
              'Sign In',
              loading: _loading,
            ),
          ],
        ),
        div(classes: 'auth-social-section', [
          authDivider(),
          div(classes: 'auth-google-row', [
            authGoogleButton(
              termsAccepted: _termsAccepted,
              onUnavailable: _googleButtonPressed,
            ),
          ]),
        ]),
        div(classes: 'auth-sign-in-footer', [
          p(classes: 'auth-switch', [
            .text('New to Eduma? '),
            Link(
              to: '/sign-up',
              child: span(classes: 'auth-link', [
                .text('Create an account'),
              ]),
            ),
          ]),
        ]),
      ],
    ),
  );
}
