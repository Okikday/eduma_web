import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../../../core/presentation/eduma_link.dart';
import '../../data/auth_api.dart' show edumaGoogleSignInConfigured;
import '../../logic/auth_actions.dart';
import '../../logic/sign_up_logic.dart';
import '../widgets/auth_frame.dart';
import '../widgets/sign_up_bars.dart';
import '../widgets/sign_up_photo_step.dart';
import '../widgets/sign_up_steps.dart';

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
  String? _photoDataUrl;
  String _referralCode = '';
  bool _usernameEdited = false;
  bool _referralFromLink = false;
  bool _passwordVisible = false;
  bool _termsAccepted = false;
  bool _loading = false;
  int _step = 0;
  UsernameCheck _usernameCheck = UsernameCheck.idle;
  ReferralCheck _referralCheck = ReferralCheck.idle;
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
    2 => true,
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
      _referralCheck = ReferralCheck.idle;
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
        _referralCheck = ReferralCheck.idle;
        _referralMessage = null;
      });
      return;
    }

    setState(() {
      _referralCheck = ReferralCheck.checking;
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
          _referralCheck = valid ? ReferralCheck.valid : ReferralCheck.invalid;
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
          _referralCheck = invalid ? ReferralCheck.invalid : ReferralCheck.unknown;
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
    if (_step == 3) {
      unawaited(_createAccount());
      return;
    }

    setState(() {
      _step++;
      _error = null;
    });
    _focusElement('auth-step-heading');
    if (_step == 3) _scheduleReferralCheck();
  }

  void _back() {
    if (_loading) return;
    if (_step == 0) {
      edumaNavigate(context, '/sign-in');
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
    final code = _referralCheck == ReferralCheck.invalid ? null : SignUpLogic.cleanReferralCode(_referralCode);
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
    edumaNavigate(
      context,
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
    if (!edumaGoogleSignInConfigured) {
      setState(
        () => _error = 'Google sign-in needs a web client ID. Use email sign-in for now.',
      );
      return;
    }

    final code = _referralCheck == ReferralCheck.invalid ? null : SignUpLogic.cleanReferralCode(_referralCode);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthActions.googleSignIn(idToken, referralCode: code);
      if (mounted) edumaNavigate(context, '/main', replace: true);
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
          : 'Google sign-in needs a web client ID. Use email sign-in for now.';
    });
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
    2 => 'Add a profile photo',
    _ => _referralCode.isNotEmpty ? "You're invited" : 'Were you invited?',
  };

  String get _stepHelper => switch (_step) {
    0 => 'This is how friends and study groups will see you.',
    1 => "Add the email and password you'll sign in with. We'll send a code to confirm the email.",
    2 => 'It helps friends recognise you. You can change it any time.',
    _ =>
      _referralCode.isNotEmpty
          ? "Your invite code is filled in from the link. Create your account when you're ready."
          : 'If a friend shared an invite code, add it here. You can skip this.',
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
        signUpTopBar(
          step: _step,
          showSkip:
              !_loading &&
              ((_step == 2 && (_photoDataUrl == null || _photoDataUrl!.isEmpty)) ||
                  (_step == 3 && _referralCode.isEmpty)),
          onSkip: _primary,
        ),
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
          switch (_step) {
            0 => signUpNameStep(
              name: _name,
              username: _username,
              usernameCheck: _usernameCheck,
              usernameMessage: _usernameMessage,
              usernameMessageClass: _usernameMessageClass,
              termsAccepted: _termsAccepted,
              error: _error,
              onNameChanged: _onNameChanged,
              onUsernameChanged: _onUsernameChanged,
              onSubmit: _primary,
              onGoogleUnavailable: _googleButtonPressed,
            ),
            1 => signUpCredentialsStep(
              email: _email,
              password: _password,
              passwordVisible: _passwordVisible,
              error: _error,
              onEmailChanged: (value) => setState(() {
                _email = value;
                _error = null;
              }),
              onPasswordChanged: (value) => setState(() {
                _password = value;
                _error = null;
              }),
              onTogglePassword: () => setState(() => _passwordVisible = !_passwordVisible),
              onSubmit: _primary,
            ),
            2 => signUpPhotoStep(
              name: _name,
              photoDataUrl: _photoDataUrl,
              busy: false,
              error: _error,
              onPhotoSelected: (dataUrl) => setState(() {
                _photoDataUrl = dataUrl;
                _error = null;
              }),
              onRemovePhoto: () => setState(() => _photoDataUrl = null),
            ),
            _ => signUpReferralStep(
              referralCode: _referralCode,
              referralCheck: _referralCheck,
              referralMessage: _referralMessage,
              error: _error,
              onReferralChanged: _onReferralChanged,
              onSubmit: _primary,
            ),
          },
        ]),
        signUpBottomBar(
          step: _step,
          termsAccepted: _termsAccepted,
          loading: _loading,
          canContinue: _canContinue,
          onTermsChanged: (value) => setState(() {
            _termsAccepted = value;
            _error = null;
          }),
          onBack: _back,
          onPrimary: _primary,
        ),
      ],
    ),
    signUp: true,
  );
}
