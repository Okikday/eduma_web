import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'features/auth/presentation/pages/account_handoff.dart';
import 'features/auth/presentation/pages/forgot_password.dart';
import 'features/auth/presentation/pages/sign_in.dart';
import 'features/auth/presentation/pages/sign_up.dart';
import 'features/auth/presentation/pages/verify_email.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) => Router(
    routes: [
      Route(
        path: '/',
        title: 'Sign in to Eduma',
        builder: (context, state) => SignInPage(email: state.queryParams['email'] ?? ''),
      ),
      Route(
        path: '/sign-in',
        title: 'Sign in to Eduma',
        builder: (context, state) => SignInPage(email: state.queryParams['email'] ?? ''),
      ),
      Route(
        path: '/sign-up',
        title: 'Create an Eduma account',
        builder: (context, state) => SignUpPage(
          referralCode: state.queryParams['ref'] ?? state.queryParams['referral'] ?? '',
        ),
      ),
      Route(
        path: '/forgot-password',
        title: 'Reset your Eduma password',
        builder: (context, state) => ForgotPasswordPage(
          email: state.queryParams['email'] ?? '',
          token: state.queryParams['token'] ?? '',
        ),
      ),
      Route(
        path: '/reset-password',
        title: 'Reset your Eduma password',
        builder: (context, state) => ForgotPasswordPage(
          email: state.queryParams['email'] ?? '',
          token: state.queryParams['token'] ?? '',
        ),
      ),
      Route(
        path: '/verify-email',
        title: 'Verify your Eduma email',
        builder: (context, state) => VerifyEmailPage(
          email: state.queryParams['email'] ?? '',
          token: state.queryParams['token'] ?? '',
          codeJustSent: state.queryParams['sent'] == 'true',
        ),
      ),
      Route(
        path: '/account',
        title: 'Continue to Eduma',
        builder: (context, state) => const AccountHandoffPage(),
      ),
    ],
  );
}
