import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

import '../../logic/auth_actions.dart';
import '../../logic/sign_up_logic.dart';
import '../widgets/auth_frame.dart';

enum _ReferralCheck { idle, checking, valid, invalid, unknown }

class SignUpPage extends StatefulComponent {
  const SignUpPage({super.key, this.referralCode = ''});

  final String referralCode;

  @override
  State<SignUpPage> createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  String _name = '';
  String _username = '';
  String _email = '';
  String _password = '';
  String _referralCode = '';
  bool _usernameEdited = false;
  bool _referralFromLink = false;
  bool _passwordVisible = false;
  bool _termsAccepted = false;
  bool _loading = false;
  int _step = 0;
  UsernameCheck _usernameCheck = UsernameCheck.idle;
  _ReferralCheck _referralCheck = _ReferralCheck.idle;
  String? _usernameCheckMessage;
  String? _referralMessage;
  String? _error;
  Timer? _usernameTimer;
  Timer? _referralTimer;
  int _referralRevision = 0;

  bool get _canContinue => switch (_step) {
    0 =>
      _name.trim().length >= 2 &&
          SignUpLogic.validUsername(_username) &&
          _usernameCheck != UsernameCheck.taken &&
          _usernameCheck != UsernameCheck.invalid,
    1 => SignUpLogic.validEmail(_email) && SignUpLogic.strengthOf(_password).acceptable,
    _ => _termsAccepted,
  };

  @override
  void initState() {
    super.initState();
    final code = SignUpLogic.referralCodeFrom(component.referralCode);
    _referralCode = code ?? component.referralCode;
    _referralFromLink = _referralCode.isNotEmpty;
  }

  @override
  void dispose() {
    _usernameTimer?.cancel();
    _referralTimer?.cancel();
    super.dispose();
  }

  void _focusElement(String id) {
    unawaited(
      Future<void>.delayed(Duration.zero, () {
        if (!mounted) return;
        (web.document.getElementById(id) as web.HTMLElement?)?.focus();
      }),
    );
  }

  void _showValidationError(String message, String targetId) {
    setState(() => _error = message);
    _focusElement(targetId);
  }

  void _onNameChanged(String value) {
    setState(() {
      _name = value;
      _error = null;
      if (!_usernameEdited) {
        final suggestions = SignUpLogic.usernameCandidates(value);
        _username = suggestions.isEmpty ? '' : suggestions.first;
      }
    });
    _scheduleUsernameCheck();
  }

  void _onUsernameChanged(String value) {
    final filtered = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    setState(() {
      _username = filtered.length > 30 ? filtered.substring(0, 30) : filtered;
      _usernameEdited = true;
      _error = null;
    });
    _scheduleUsernameCheck();
  }

  void _scheduleUsernameCheck() {
    _usernameTimer?.cancel();
    final username = _username;
    if (username.isEmpty) {
      setState(() {
        _usernameCheck = UsernameCheck.idle;
        _usernameCheckMessage = null;
      });
      return;
    }
    if (!SignUpLogic.validUsername(username)) {
      setState(() {
        _usernameCheck = UsernameCheck.invalid;
        _usernameCheckMessage = 'Use 3–30 lowercase letters, numbers, dots, or underscores.';
      });
      return;
    }

    setState(() {
      _usernameCheck = UsernameCheck.checking;
      _usernameCheckMessage = null;
    });
    _usernameTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final available = await AuthActions.checkUsername(username);
        if (!mounted || username != _username) return;
        setState(() {
          _usernameCheck = switch (available) {
            true => UsernameCheck.available,
            false => UsernameCheck.taken,
            null => UsernameCheck.unknown,
          };
          _usernameCheckMessage = available == null
              ? "We couldn't check this username. We'll verify it when you create your account."
              : null;
        });
      } on AuthApiException {
        if (!mounted || username != _username) return;
        setState(() {
          _usernameCheck = UsernameCheck.unknown;
          _usernameCheckMessage = "We couldn't check this username. We'll verify it when you create your account.";
        });
      }
    });
  }

  void _onReferralChanged(String value) {
    final parsed = SignUpLogic.referralCodeFrom(value);
    setState(() {
      _referralCode = parsed ?? value;
      _referralFromLink = false;
      _referralCheck = _ReferralCheck.idle;
      _referralMessage = null;
      _error = null;
    });
    _scheduleReferralCheck();
  }

  void _scheduleReferralCheck() {
    _referralTimer?.cancel();
    final code = SignUpLogic.cleanReferralCode(_referralCode);
    final revision = ++_referralRevision;
    if (code == null) {
      setState(() {
        _referralCheck = _ReferralCheck.idle;
        _referralMessage = null;
      });
      return;
    }

    setState(() {
      _referralCheck = _ReferralCheck.checking;
      _referralMessage = null;
    });
    _referralTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final response = await AuthActions.lookupReferral(code);
        if (!mounted || revision != _referralRevision) return;
        final referral = _asMap(response['referral']) ?? response;
        final inviter = _asMap(
          referral['inviter'] ?? referral['referrer'] ?? referral['user'],
        );
        final valid = referral['valid'] != false && referral['isValid'] != false && referral['exists'] != false;
        final label = _inviterLabel(inviter);
        setState(() {
          _referralCheck = valid ? _ReferralCheck.valid : _ReferralCheck.invalid;
          _referralMessage = valid
              ? label == null
                    ? 'Invite code found$_referralLinkSuffix'
                    : 'Invited by $label$_referralLinkSuffix'
              : "We couldn't find that code, so it won't be used. Check it for typos.";
        });
      } on AuthApiException catch (error) {
        if (!mounted || revision != _referralRevision) return;
        final routeMissing =
            error.statusCode == 405 ||
            error.statusCode == 501 ||
            (error.statusCode == 404 && error.message.toLowerCase().contains('route'));
        final invalid =
            !routeMissing && (error.statusCode == 404 || error.statusCode == 410 || error.statusCode == 422);
        setState(() {
          _referralCheck = invalid ? _ReferralCheck.invalid : _ReferralCheck.unknown;
          _referralMessage = invalid
              ? "We couldn't find that code, so it won't be used. Check it for typos."
              : "We couldn't check this code right now. We'll include it with your account.";
        });
      }
    });
  }

  String get _referralLinkSuffix => _referralFromLink ? ' · from your invite link' : '';

  Map<String, dynamic>? _asMap(Object? value) => value is Map ? Map<String, dynamic>.from(value) : null;

  String? _inviterLabel(Map<String, dynamic>? inviter) {
    if (inviter == null) return null;
    for (final key in const ['name', 'fullName', 'username']) {
      final value = inviter[key];
      if (value is String && value.trim().isNotEmpty) {
        return key == 'username' ? '@${value.trim()}' : value.trim();
      }
    }
    return null;
  }

  void _primary() {
    if (_loading) return;
    if (!_canContinue) {
      final message = switch (_step) {
        0 => 'Add your name and choose an available username to continue.',
        1 => 'Add a valid email and a password of at least 8 characters.',
        _ => 'Please read and agree to the Terms of Service to create your account.',
      };
      final targetId = switch (_step) {
        0 => _name.trim().length < 2 ? 'auth-name' : 'auth-username',
        1 => SignUpLogic.validEmail(_email) ? 'auth-password' : 'auth-email',
        _ => 'auth-consent',
      };
      _showValidationError(message, targetId);
      return;
    }
    if (_step == 2) {
      unawaited(_createAccount());
      return;
    }

    setState(() {
      _step++;
      _error = null;
    });
    _focusElement('auth-step-heading');
    if (_step == 2) _scheduleReferralCheck();
  }

  void _back() {
    if (_loading) return;
    if (_step == 0) {
      web.window.location.assign('/sign-in');
      return;
    }
    setState(() {
      _step--;
      _error = null;
    });
    _focusElement('auth-step-heading');
  }

  Future<void> _createAccount() async {
    final name = _name.trim();
    final username = _username.trim().toLowerCase();
    final email = _email.trim();
    final code = _referralCheck == _ReferralCheck.invalid ? null : SignUpLogic.cleanReferralCode(_referralCode);
    if (!_termsAccepted) {
      _showValidationError(
        'Please read and agree to the Terms of Service to create your account.',
        'auth-consent',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      try {
        await AuthActions.register(
          name: name,
          username: username,
          email: email,
          password: _password,
          referralCode: code ?? '',
        );
      } on AuthApiException catch (error) {
        if (code == null || !_referralWasRefused(error)) rethrow;
        await AuthActions.register(
          name: name,
          username: username,
          email: email,
          password: _password,
          referralCode: '',
        );
      }
      if (mounted) _goToVerification(email);
    } on AuthApiException catch (error) {
      if (error.isEmailNotVerified) {
        try {
          await AuthActions.acceptPendingSession(error);
          if (mounted) _goToVerification(email);
        } on AuthApiException catch (sessionError) {
          if (mounted) setState(() => _error = sessionError.message);
        }
      } else if (mounted) {
        final text = '${error.message} ${error.details}'.toLowerCase();
        setState(() {
          if (text.contains('username') || text.contains('handle')) {
            _step = 0;
            _usernameCheck = UsernameCheck.taken;
            _usernameCheckMessage = error.message;
          } else if (text.contains('email') || text.contains('password')) {
            _step = 1;
          }
          _error = error.message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _referralWasRefused(AuthApiException error) {
    if (error.statusCode != 400 && error.statusCode != 422) return false;
    final text = '${error.message} ${error.code ?? ''} ${error.details}'.toLowerCase();
    return text.contains('referral') || text.contains('invite');
  }

  void _goToVerification(String email) {
    web.window.location.assign(
      Uri(
        path: '/verify-email',
        queryParameters: {'email': email, 'sent': 'true'},
      ).toString(),
    );
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

    final code = _referralCheck == _ReferralCheck.invalid ? null : SignUpLogic.cleanReferralCode(_referralCode);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthActions.googleSignIn(idToken, referralCode: code);
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

  Component? _usernameSuffix() {
    return switch (_usernameCheck) {
      UsernameCheck.checking => span(classes: 'auth-mini-spinner', []),
      UsernameCheck.available => span(
        classes: 'auth-field-status auth-field-status--available',
        [authIcon('check', size: 18)],
      ),
      UsernameCheck.taken || UsernameCheck.invalid => span(
        classes: 'auth-field-status auth-field-status--error',
        [authIcon('close', size: 18)],
      ),
      UsernameCheck.idle || UsernameCheck.unknown => null,
    };
  }

  String get _usernameMessage =>
      _usernameCheckMessage ??
      switch (_usernameCheck) {
        UsernameCheck.available => '@$_username is available',
        UsernameCheck.taken => 'That username is already taken. Try another.',
        UsernameCheck.invalid => 'Use 3–30 lowercase letters, numbers, dots, or underscores.',
        _ => 'Classmates can find and mention you by it.',
      };

  String get _usernameMessageClass => switch (_usernameCheck) {
    UsernameCheck.available => 'auth-username-help--available',
    UsernameCheck.taken || UsernameCheck.invalid => 'auth-username-help--error',
    _ => '',
  };

  String get _stepTitle => switch (_step) {
    0 => "What's your name?",
    1 =>
      SignUpLogic.firstName(_name).isEmpty
          ? 'Your email and password'
          : 'Nice to meet you, ${SignUpLogic.firstName(_name)}',
    _ => _referralCode.isNotEmpty ? "You're invited" : 'Were you invited?',
  };

  String get _stepHelper => switch (_step) {
    0 => 'This is how friends and study groups will see you.',
    1 => "Add the email and password you'll sign in with. We'll send a code to confirm the email.",
    _ =>
      _referralCode.isNotEmpty
          ? "Your invite code is filled in from the link. Create your account when you're ready."
          : 'If a friend shared an invite code, add it here. You can skip this.',
  };

  Component _passwordStrength() {
    final strength = SignUpLogic.strengthOf(_password);
    final tone = switch (strength) {
      PasswordStrength.empty => '',
      PasswordStrength.tooShort || PasswordStrength.weak => 'auth-password-strength--weak',
      PasswordStrength.fair => 'auth-password-strength--fair',
      PasswordStrength.good || PasswordStrength.strong => 'auth-password-strength--good',
    };
    final label = strength == PasswordStrength.empty
        ? 'Mix letters, numbers and symbols for a stronger password.'
        : strength.label;
    return div(
      classes: tone.isEmpty ? 'auth-password-strength' : 'auth-password-strength $tone',
      [
        div(classes: 'auth-strength-bars', [
          for (var index = 0; index < 4; index++)
            span(
              classes: index < strength.segments ? 'auth-strength-bar auth-strength-bar--filled' : 'auth-strength-bar',
              [],
            ),
        ]),
        p([.text(label)]),
      ],
    );
  }

  Component _stepFields() => switch (_step) {
    0 => form(
      classes: 'auth-step-form',
      noValidate: true,
      events: {
        'submit': (event) {
          event.preventDefault();
          _primary();
        },
      },
      [
        if (_error case final message?) div(classes: 'auth-step-error', [authError(message)]),
        div(classes: 'auth-step-content auth-name-step', [
          div(classes: 'auth-field-stack', [
            authField(
              labelText: 'Full name',
              name: 'name',
              value: _name,
              type: InputType.text,
              autocomplete: 'name',
              placeholder: 'Your first and last name',
              icon: 'user',
              enterKeyHint: 'next',
              onInput: _onNameChanged,
            ),
            authField(
              labelText: 'Username',
              name: 'username',
              value: _username,
              type: InputType.text,
              autocomplete: 'username',
              identifier: true,
              placeholder: 'yourname',
              icon: 'username',
              invalid: _usernameCheck == UsernameCheck.taken || _usernameCheck == UsernameCheck.invalid,
              describedBy: 'auth-username-help',
              enterKeyHint: 'next',
              fieldClass: _usernameCheck == UsernameCheck.taken || _usernameCheck == UsernameCheck.invalid
                  ? 'auth-field--error'
                  : null,
              onInput: _onUsernameChanged,
              suffix: _usernameSuffix(),
            ),
          ]),
          p(
            classes: _usernameMessageClass.isEmpty ? 'auth-username-help' : 'auth-username-help $_usernameMessageClass',
            attributes: {
              'id': 'auth-username-help',
              'role': 'status',
              'aria-live': 'polite',
            },
            [
              .text(_usernameMessage),
            ],
          ),
          authDivider(text: 'Or'),
          div(classes: 'auth-google-row', [
            authGoogleButton(
              termsAccepted: _termsAccepted,
              onUnavailable: _googleButtonPressed,
            ),
          ]),
          p(classes: 'auth-switch', [
            .text('Already have an account? '),
            Link(
              to: '/sign-in',
              child: span(classes: 'auth-link', [.text('Sign in')]),
            ),
          ]),
        ]),
      ],
    ),
    1 => form(
      classes: 'auth-step-form',
      noValidate: true,
      events: {
        'submit': (event) {
          event.preventDefault();
          _primary();
        },
      },
      [
        if (_error case final message?) div(classes: 'auth-step-error', [authError(message)]),
        div(classes: 'auth-step-content', [
          div(classes: 'auth-field-stack', [
            authField(
              labelText: 'Email',
              name: 'email',
              value: _email,
              type: InputType.email,
              autocomplete: 'email',
              identifier: true,
              placeholder: 'you@example.com',
              icon: 'mail',
              enterKeyHint: 'next',
              onInput: (value) => setState(() {
                _email = value;
                _error = null;
              }),
            ),
            authField(
              labelText: 'Password',
              name: 'password',
              value: _password,
              type: _passwordVisible ? InputType.text : InputType.password,
              autocomplete: 'new-password',
              placeholder: 'At least 8 characters',
              icon: 'lock',
              enterKeyHint: 'done',
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
            _passwordStrength(),
          ]),
        ]),
      ],
    ),
    _ => form(
      classes: 'auth-step-form',
      noValidate: true,
      events: {
        'submit': (event) {
          event.preventDefault();
          _primary();
        },
      },
      [
        if (_error case final message?) div(classes: 'auth-step-error', [authError(message)]),
        div(classes: 'auth-step-content', [
          authField(
            labelText: 'Invite code',
            name: 'referralCode',
            value: _referralCode,
            type: InputType.text,
            autocomplete: 'off',
            identifier: true,
            requiredField: false,
            placeholder: 'Paste a code or invite link',
            icon: 'ticket',
            onInput: _onReferralChanged,
          ),
          if (_referralMessage case final message?)
            p(
              classes: switch (_referralCheck) {
                _ReferralCheck.invalid => 'auth-referral-status auth-referral-status--invalid',
                _ReferralCheck.valid => 'auth-referral-status auth-referral-status--valid',
                _ => 'auth-referral-status',
              },
              attributes: {'role': 'status', 'aria-live': 'polite'},
              [.text(message)],
            ),
          if (_referralCheck == _ReferralCheck.checking)
            p(
              classes: 'auth-referral-status',
              attributes: {'role': 'status', 'aria-live': 'polite'},
              [.text('Checking the code…')],
            ),
        ]),
      ],
    ),
  };

  @override
  Component build(BuildContext context) => authDesktopFrame(
    main_(
      classes: 'auth-signup-page',
      [
        input<String>(
          id: 'google-id-token',
          classes: 'auth-hidden-input',
          type: InputType.hidden,
          value: '',
          onInput: (token) => unawaited(_completeGoogleSignIn(token)),
          attributes: {'aria-hidden': 'true', 'tabindex': '-1'},
        ),
        header(classes: 'auth-signup-topbar', [
          Link(
            to: '/sign-in',
            child: span(
              classes: 'auth-topbar-button',
              attributes: {'aria-label': 'Close sign up'},
              [authIcon('close', size: 18)],
            ),
          ),
          div(
            classes: 'auth-step-progress',
            attributes: {
              'role': 'progressbar',
              'aria-label': 'Sign-up progress',
              'aria-valuemin': '1',
              'aria-valuemax': '3',
              'aria-valuenow': '${_step + 1}',
            },
            [
              for (var index = 0; index < 3; index++)
                span(
                  classes: index <= _step
                      ? 'auth-step-progress__segment auth-step-progress__segment--filled'
                      : 'auth-step-progress__segment',
                  attributes: {'aria-hidden': 'true'},
                  [],
                ),
            ],
          ),
          if (_step == 2 && _referralCode.isEmpty && !_loading)
            button(
              classes: 'auth-skip',
              type: ButtonType.button,
              onClick: _primary,
              [.text('Skip')],
            )
          else
            button(
              classes: 'auth-skip auth-skip--hidden',
              type: ButtonType.button,
              disabled: true,
              [.text('Skip')],
            ),
        ]),
        section(classes: 'auth-step-body', [
          div(classes: 'auth-step-header', [
            h1(
              id: 'auth-step-heading',
              classes: 'auth-title',
              attributes: {'tabindex': '-1'},
              [.text(_stepTitle)],
            ),
            p(classes: 'auth-subtitle', [.text(_stepHelper)]),
          ]),
          _stepFields(),
        ]),
        footer(classes: 'auth-bottom-bar', [
          authConsent(
            value: _termsAccepted,
            disabled: _loading,
            onChanged: (value) => setState(() {
              _termsAccepted = value;
              _error = null;
            }),
          ),
          div(classes: 'auth-step-actions', [
            if (_step > 0)
              button(
                classes: 'auth-secondary-button',
                type: ButtonType.button,
                disabled: _loading,
                onClick: _back,
                [.text('Back')],
              ),
            button(
              classes: 'auth-submit',
              type: ButtonType.button,
              disabled: _loading,
              onClick: _primary,
              [
                .text(_step == 2 ? 'Create account' : 'Continue'),
                if (_loading)
                  span(classes: 'auth-spinner', [])
                else if (_step < 2)
                  span(classes: 'auth-button-trailing', [authIcon('arrow', size: 18)]),
              ],
            ),
          ]),
        ]),
      ],
    ),
    signUp: true,
  );
}
