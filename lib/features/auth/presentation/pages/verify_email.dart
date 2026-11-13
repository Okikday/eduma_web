import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../logic/auth_actions.dart';
import '../widgets/auth_frame.dart';

class VerifyEmailPage extends StatefulComponent {
  const VerifyEmailPage({
    super.key,
    this.email = '',
    this.token = '',
    this.codeJustSent = false,
  });

  final String email;
  final String token;
  final bool codeJustSent;

  @override
  State<VerifyEmailPage> createState() => VerifyEmailPageState();
}

class VerifyEmailPageState extends State<VerifyEmailPage> {
  static const _codeLength = 6;

  String _email = '';
  String _code = '';
  bool _loading = false;
  bool _resending = false;
  bool _verified = false;
  bool _codeFocused = false;
  DateTime? _resendAvailableAt;
  DateTime? _lockedUntil;
  Timer? _countdownTimer;
  String? _error;

  int get _resendSecondsRemaining {
    final until = _resendAvailableAt;
    if (until == null) return 0;
    final seconds = until.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  int get _lockSecondsRemaining {
    final until = _lockedUntil;
    if (until == null) return 0;
    final seconds = until.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  @override
  void initState() {
    super.initState();
    _email = component.email;
    if (component.token.isNotEmpty) {
      AuthActions.scrubTokenFromAddressBar();
      Future<void>.microtask(_verify);
    } else if (component.codeJustSent) {
      _startResendCooldown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendAvailableAt = DateTime.now().add(Duration(seconds: seconds));
    _startCountdown();
  }

  void _startLock([int seconds = 0]) {
    if (seconds > 0) _lockedUntil = DateTime.now().add(Duration(seconds: seconds));
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining == 0 && _lockSecondsRemaining == 0) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  Future<void> _verify() async {
    final token = component.token;
    final code = token.isNotEmpty ? '' : _code.replaceAll(RegExp(r'\D'), '');
    if (token.isEmpty && code.length != _codeLength) {
      setState(() => _error = 'Enter the six-digit code from your email.');
      return;
    }
    if (token.isEmpty && _email.trim().isEmpty) {
      setState(() => _error = 'Sign in to enter your code.');
      return;
    }
    if (_lockSecondsRemaining > 0) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await AuthActions.verifyEmail(
        code: code,
        email: _email,
        token: token,
      );
      if (!mounted) return;
      if (session != null) {
        web.window.location.assign('/account');
      } else {
        setState(() => _verified = true);
      }
    } on AuthApiException catch (error) {
      if (!mounted) return;
      final retryAfter = int.tryParse('${error.details['retryAfter'] ?? ''}');
      if (error.statusCode == 429 && retryAfter != null && retryAfter > 0) {
        _startLock(retryAfter);
      }
      final codeName = (error.code ?? '').toUpperCase();
      final message = switch (codeName) {
        'INVALID_CODE' => "That code isn't right. Check the email and try again.",
        'EXPIRED' || 'CODE_EXPIRED' => 'That code has expired. Send yourself a new one.',
        _ when error.statusCode == 401 && _email.isEmpty => 'Sign in to enter your code.',
        _ => error.message,
      };
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendSecondsRemaining > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await AuthActions.resendVerification(email: _email);
      if (mounted) _startResendCooldown();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
      final retryAfter = int.tryParse('${error.details['retryAfter'] ?? ''}');
      if (error.statusCode == 429 && retryAfter != null && retryAfter > 0) {
        _startResendCooldown(retryAfter);
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _onCodeChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final code = digits.length <= _codeLength ? digits : digits.substring(0, _codeLength);
    setState(() {
      _code = code;
      _error = null;
    });
    if (code.length == _codeLength && !_loading) unawaited(_verify());
  }

  String get _subtitle => _email.isEmpty
      ? 'Enter the 6-digit code from the email we sent you.'
      : 'Enter the 6-digit code we sent to ${_email.trim()}.';

  String get _resendLabel => _resending
      ? 'Sending…'
      : _resendSecondsRemaining > 0
      ? 'Resend code in ${_resendSecondsRemaining}s'
      : 'Resend code';

  @override
  Component build(BuildContext context) => main_(
    classes: 'auth-page auth-page--route',
    [
      authRouteTopBar(
        label: 'Back to sign in',
        onBack: () => web.window.location.assign('/sign-in'),
      ),
      div(classes: 'auth-verify-scroll', [
        section(
          classes: _verified ? 'auth-verify-content auth-empty-state' : 'auth-verify-content',
          [
            div(classes: 'auth-icon-tile', [
              authIcon(_verified ? 'check' : 'mail', size: 22),
            ]),
            h1(classes: 'auth-verify-title', [
              .text(_verified ? 'Email verified' : 'Verify your email'),
            ]),
            p(classes: 'auth-verify-copy', [
              .text(
                _verified ? 'Thanks for confirming your email address. Sign in to continue.' : _subtitle,
              ),
            ]),
            if (_verified) ...[
              a(href: '/sign-in', classes: 'auth-submit', [
                .text('Sign in'),
              ]),
            ] else ...[
              if (component.token.isNotEmpty && _loading)
                p(classes: 'auth-verify-status', [
                  .text('Confirming your email…'),
                ])
              else ...[
                div(
                  classes: _codeFocused ? 'auth-otp auth-otp--focused' : 'auth-otp',
                  [
                    for (var index = 0; index < _codeLength; index++)
                      span(
                        classes: [
                          'auth-otp-digit',
                          if (_codeFocused && index == _code.length.clamp(0, _codeLength - 1)) 'auth-otp-digit--active',
                          if (_error != null) 'auth-otp-digit--error',
                          if (_loading || _lockSecondsRemaining > 0) 'auth-otp-digit--disabled',
                        ].join(' '),
                        [
                          .text(index < _code.length ? _code[index] : ''),
                        ],
                      ),
                    input<String>(
                      id: 'verify-code',
                      classes: 'auth-otp-input',
                      type: InputType.text,
                      value: _code,
                      disabled: _loading || _lockSecondsRemaining > 0,
                      onInput: _onCodeChanged,
                      events: {
                        'focus': (_) => setState(() => _codeFocused = true),
                        'blur': (_) => setState(() => _codeFocused = false),
                      },
                      attributes: {
                        'aria-label': 'Six-digit verification code',
                        'autocomplete': 'one-time-code',
                        'autofocus': '',
                        'inputmode': 'numeric',
                        'maxlength': '6',
                        'pattern': '[0-9]*',
                      },
                    ),
                  ],
                ),
                div(
                  classes: 'auth-verify-status',
                  attributes: {'role': 'status', if (_error != null) 'aria-live': 'polite'},
                  [
                    if (_lockSecondsRemaining > 0)
                      .text(
                        'Too many attempts. Try again in ${_lockSecondsRemaining}s.',
                      )
                    else if (_error case final message?)
                      .text(message),
                  ],
                ),
                form(
                  noValidate: true,
                  events: {
                    'submit': (event) {
                      event.preventDefault();
                      if (!_loading) unawaited(_verify());
                    },
                  },
                  [
                    button(
                      classes: 'auth-submit auth-verify-button',
                      type: ButtonType.submit,
                      disabled: _loading || _lockSecondsRemaining > 0 || _code.length != _codeLength,
                      [
                        .text('Verify'),
                        if (_loading) span(classes: 'auth-spinner', []),
                      ],
                    ),
                  ],
                ),
                div(classes: 'auth-resend-row', [
                  span([.text("Didn't get it? Check spam, or")]),
                  button(
                    classes: 'auth-text-button',
                    type: ButtonType.button,
                    disabled: _resending || _resendSecondsRemaining > 0,
                    onClick: _resend,
                    [.text(_resendLabel)],
                  ),
                ]),
              ],
            ],
          ],
        ),
      ]),
    ],
  );
}
