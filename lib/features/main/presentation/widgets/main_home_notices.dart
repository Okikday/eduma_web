import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_link.dart';
import '../../../auth/data/auth_api.dart';
import 'main_home_icons.dart';

/// Email verification prompt shown at top of Home when `isEmailVerified != true`.
Component mainHomeVerifyEmailBanner({
  required EdumaSession session,
  required bool resending,
  required int secondsRemaining,
  required String? feedbackMessage,
  required bool feedbackIsError,
  required VoidCallback onResend,
  required VoidCallback onDismiss,
}) {
  final email = '${session.user['email'] ?? ''}'.trim();
  return div(
    classes: 'main-home__notice main-home__notice--verify',
    [
      mainHomeIcon(.email),
      div(classes: 'main-home__verification-copy', [
        strong([.text('Verify your email')]),
        p([
          .text(
            email.isEmpty
                ? 'Enter the 6-digit code we emailed you to confirm your email address.'
                : 'We sent a 6-digit code to $email. Enter it to confirm your email address.',
          ),
        ]),
        if (feedbackMessage != null)
          p(
            attributes: {'role': feedbackIsError ? 'alert' : 'status'},
            [.text(feedbackMessage)],
          ),
        div(classes: 'main-home__verification-actions', [
          edumaLink(
            to: '/verify-email',
            classes: 'main-home__verification-primary',
            children: [mainHomeIcon(.key), .text('Enter code')],
          ),
          button(
            classes: 'main-home__verification-resend',
            type: ButtonType.button,
            disabled: resending || secondsRemaining > 0,
            onClick: onResend,
            [
              mainHomeIcon(.refresh, size: 15),
              .text(
                resending
                    ? 'Sending…'
                    : secondsRemaining > 0
                    ? 'Resend code in ${secondsRemaining}s'
                    : 'Resend code',
              ),
            ],
          ),
        ]),
      ]),
      button(
        classes: 'main-home__verification-dismiss',
        type: ButtonType.button,
        attributes: {'aria-label': 'Not now'},
        onClick: onDismiss,
        [mainHomeIcon(.close)],
      ),
    ],
  );
}

Component mainHomeNotice(
  String message, {
  bool isError = false,
  VoidCallback? onRetry,
}) => div(
  classes: isError ? 'main-home__notice main-home__notice--error' : 'main-home__notice',
  attributes: {'role': isError ? 'alert' : 'status'},
  [
    p([.text(message)]),
    if (onRetry != null)
      button(
        classes: 'main-home__retry',
        type: ButtonType.button,
        onClick: onRetry,
        [.text('Retry')],
      ),
  ],
);

Component mainHomeEmptyState(
  String title,
  String message, {
  VoidCallback? onRetry,
  List<Component> actions = const [],
}) => div(
  classes: 'main-home__empty-state',
  [
    mainHomeIcon(onRetry != null ? .warning : .people),
    strong([.text(title)]),
    p([.text(message)]),
    if (onRetry != null)
      button(
        classes: 'main-home__retry',
        type: ButtonType.button,
        onClick: onRetry,
        [mainHomeIcon(.refresh), .text('Try again')],
      ),
    if (actions.isNotEmpty) div(classes: 'main-home__empty-actions', actions),
  ],
);

Component mainHomeLoadingSessionState() => div(
  classes: 'main-home__session-state',
  attributes: {'role': 'status', 'aria-live': 'polite', 'aria-label': 'Loading Eduma'},
  [
    span(classes: 'main-home__spinner', []),
  ],
);

Component mainHomeSessionErrorState(
  String message, {
  required VoidCallback onRetry,
}) => div(
  classes: 'main-home__session-state',
  attributes: {'role': 'alert'},
  [
    h1([.text("Couldn't open Home")]),
    p([.text(message)]),
    button(
      classes: 'main-home__retry',
      type: ButtonType.button,
      onClick: onRetry,
      [mainHomeIcon(.refresh), .text('Try again')],
    ),
    edumaLink(
      classes: 'main-home__secondary-link',
      to: '/sign-in',
      children: [
        .text('Sign in again'),
      ],
    ),
  ],
);

Component mainHomeSignInPromptState() => div(
  classes: 'main-home__session-state',
  [
    h1([.text('Sign in to Eduma')]),
    p([.text('Your spaces and learning dashboard appear here after sign-in.')]),
    edumaLink(
      classes: 'main-home__primary-link',
      to: '/sign-in',
      children: [
        .text('Sign in'),
      ],
    ),
  ],
);
