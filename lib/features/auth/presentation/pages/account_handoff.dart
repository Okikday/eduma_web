import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../logic/auth_actions.dart';
import '../widgets/auth_frame.dart';

class AccountHandoffPage extends StatefulComponent {
  const AccountHandoffPage({super.key});

  @override
  State<AccountHandoffPage> createState() => AccountHandoffPageState();
}

class AccountHandoffPageState extends State<AccountHandoffPage> {
  EdumaSession? _session;
  bool _loading = true;
  bool _signingOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_restore);
  }

  Future<void> _restore() async {
    try {
      final session = await AuthActions.restoreSession();
      if (mounted) setState(() => _session = session);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await AuthActions.signOut();
      if (mounted) setState(() => _session = null);
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _session = null;
          _error = error.message;
        });
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Component build(BuildContext context) => AuthFrame(
    kicker: 'EDUMA ACCOUNT',
    title: _loading
        ? 'Restoring your session'
        : _session == null
        ? 'Sign in to continue'
        : 'Welcome, ${_session!.name.split(' ').first}',
    subtitle: _loading
        ? 'Checking your secure Eduma session.'
        : _session == null
        ? 'Your Eduma session is not available in this browser.'
        : 'Your account is ready. Continue to your existing Eduma workspace.',
    child: _loading
        ? div(classes: 'auth-actions', [
            p(classes: 'auth-loading-copy', [
              .text('Your account data stays in your browser while we check the server.'),
            ]),
          ])
        : _session == null
        ? div(classes: 'auth-actions', [
            if (_error case final message?) authError(message),
            Link(
              to: '/sign-in',
              child: button(classes: 'auth-submit', [.text('Back to sign in')]),
            ),
          ])
        : div(classes: 'auth-actions', [
            if (_session!.warning case final warning?) authError(warning),
            div(classes: 'auth-account-card', [
              div(classes: 'auth-avatar', [
                .text(_session!.name.trim().isEmpty ? 'E' : _session!.name.trim()[0].toUpperCase()),
              ]),
              div([
                strong([.text(_session!.name)]),
                p([.text(_session!.email)]),
                span(classes: 'auth-role', [
                  .text(_session!.role.toUpperCase()),
                ]),
              ]),
            ]),
            if (_error case final message?) authError(message),
            if (AuthActions.canOpenFlutterApp)
              a(
                href: edumaFlutterAppUrl,
                classes: 'auth-submit auth-submit--link',
                [
                  .text('Continue to Eduma'),
                ],
              )
            else
              authError(
                'The Flutter workspace must be hosted at a separate path on this same origin so your session can be shared. Configure EDUMA_FLUTTER_APP_URL to that path, then rebuild.',
              ),
            button(
              classes: 'auth-text-button',
              type: ButtonType.button,
              disabled: _signingOut,
              onClick: () {
                if (!_signingOut) unawaited(_signOut());
              },
              [
                .text(_signingOut ? 'Signing out…' : 'Sign out'),
              ],
            ),
          ]),
  );
}
