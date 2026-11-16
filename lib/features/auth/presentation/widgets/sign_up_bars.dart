import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'auth_frame.dart';

/// Top navigation/progress bar for the 4-step sign-up flow.
Component signUpTopBar({
  required int step,
  required bool showSkip,
  required VoidCallback onSkip,
}) => header(classes: 'auth-signup-topbar', [
  Link(
    to: '/sign-in',
    child: span(
      classes: 'auth-topbar-button',
      attributes: {'aria-label': 'Close sign up'},
      [authIcon('close-plain', size: 18)],
    ),
  ),
  div(
    classes: 'auth-step-progress',
    attributes: {
      'role': 'progressbar',
      'aria-label': 'Sign-up progress',
      'aria-valuemin': '1',
      'aria-valuemax': '4',
      'aria-valuenow': '${step + 1}',
    },
    [
      for (var index = 0; index < 4; index++)
        span(
          classes: index <= step
              ? 'auth-step-progress__segment auth-step-progress__segment--filled'
              : 'auth-step-progress__segment',
          attributes: {'aria-hidden': 'true'},
          [],
        ),
    ],
  ),
  if (showSkip)
    button(
      classes: 'auth-skip',
      type: ButtonType.button,
      onClick: onSkip,
      [.text('Skip')],
    )
  else
    button(
      classes: 'auth-skip auth-skip--hidden',
      type: ButtonType.button,
      disabled: true,
      [.text('Skip')],
    ),
]);

/// Persistent bottom consent checkbox and primary/secondary actions for sign-up.
Component signUpBottomBar({
  required int step,
  required bool termsAccepted,
  required bool loading,
  bool canContinue = true,
  required ValueChanged<bool> onTermsChanged,
  required VoidCallback onBack,
  required VoidCallback onPrimary,
}) => footer(classes: 'auth-bottom-bar', [
  authConsent(
    value: termsAccepted,
    disabled: loading,
    onChanged: onTermsChanged,
  ),
  div(classes: 'auth-step-actions', [
    if (step > 0)
      button(
        classes: 'auth-secondary-button',
        type: ButtonType.button,
        disabled: loading,
        onClick: onBack,
        [.text('Back')],
      ),
    button(
      classes: 'auth-submit',
      type: ButtonType.button,
      disabled: loading || !canContinue,
      onClick: onPrimary,
      [
        .text(step == 3 ? 'Create account' : 'Continue'),
        if (loading)
          span(classes: 'auth-spinner', [])
        else if (step < 3)
          span(classes: 'auth-button-trailing', [authIcon('arrow', size: 18)]),
      ],
    ),
  ]),
]);
