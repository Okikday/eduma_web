import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../logic/sign_up_logic.dart';
import 'auth_frame.dart';

/// Step 1 of sign-up: full name, auto-suggested/validated username, and Google SSO.
Component signUpNameStep({
  required String name,
  required String username,
  required UsernameCheck usernameCheck,
  required String usernameMessage,
  required String usernameMessageClass,
  required bool termsAccepted,
  required String? error,
  required ValueChanged<String> onNameChanged,
  required ValueChanged<String> onUsernameChanged,
  required VoidCallback onSubmit,
  required VoidCallback onGoogleUnavailable,
}) => form(
  classes: 'auth-step-form',
  noValidate: true,
  events: {
    'submit': (event) {
      event.preventDefault();
      onSubmit();
    },
  },
  [
    if (error != null) div(classes: 'auth-step-error', [authError(error)]),
    div(classes: 'auth-step-content auth-name-step', [
      div(classes: 'auth-field-stack', [
        authField(
          labelText: 'Full name',
          name: 'name',
          value: name,
          type: InputType.text,
          autocomplete: 'name',
          placeholder: 'Your first and last name',
          icon: 'user',
          enterKeyHint: 'next',
          onInput: onNameChanged,
        ),
        authField(
          labelText: 'Username',
          name: 'username',
          value: username,
          type: InputType.text,
          autocomplete: 'username',
          identifier: true,
          placeholder: 'yourname',
          icon: 'username',
          invalid: usernameCheck == UsernameCheck.taken || usernameCheck == UsernameCheck.invalid,
          describedBy: 'auth-username-help',
          enterKeyHint: 'next',
          fieldClass: usernameCheck == UsernameCheck.taken || usernameCheck == UsernameCheck.invalid
              ? 'auth-field--error'
              : null,
          onInput: onUsernameChanged,
          suffix: _usernameSuffix(usernameCheck),
        ),
      ]),
      p(
        classes: usernameMessageClass.isEmpty ? 'auth-username-help' : 'auth-username-help $usernameMessageClass',
        attributes: {
          'id': 'auth-username-help',
          'role': 'status',
          'aria-live': 'polite',
        },
        [.text(usernameMessage)],
      ),
      authDivider(text: 'Or'),
      div(classes: 'auth-google-row', [
        authGoogleButton(
          termsAccepted: termsAccepted,
          onUnavailable: onGoogleUnavailable,
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
);

/// Step 2 of sign-up: email, password with toggle, and strength meter.
Component signUpCredentialsStep({
  required String email,
  required String password,
  required bool passwordVisible,
  required String? error,
  required ValueChanged<String> onEmailChanged,
  required ValueChanged<String> onPasswordChanged,
  required VoidCallback onTogglePassword,
  required VoidCallback onSubmit,
}) => form(
  classes: 'auth-step-form',
  noValidate: true,
  events: {
    'submit': (event) {
      event.preventDefault();
      onSubmit();
    },
  },
  [
    if (error != null) div(classes: 'auth-step-error', [authError(error)]),
    div(classes: 'auth-step-content', [
      div(classes: 'auth-field-stack', [
        authField(
          labelText: 'Email',
          name: 'email',
          value: email,
          type: InputType.email,
          autocomplete: 'email',
          identifier: true,
          placeholder: 'you@example.com',
          icon: 'mail',
          enterKeyHint: 'next',
          onInput: onEmailChanged,
        ),
        authField(
          labelText: 'Password',
          name: 'password',
          value: password,
          type: passwordVisible ? InputType.text : InputType.password,
          autocomplete: 'new-password',
          placeholder: 'At least 8 characters',
          icon: 'lock',
          enterKeyHint: 'done',
          onInput: onPasswordChanged,
          suffix: button(
            classes: 'auth-field-suffix',
            type: ButtonType.button,
            onClick: onTogglePassword,
            attributes: {
              'aria-label': passwordVisible ? 'Hide password' : 'Show password',
            },
            [authIcon(passwordVisible ? 'eye' : 'eye-off')],
          ),
        ),
        signUpPasswordStrength(password),
      ]),
    ]),
  ],
);

/// Step 3 of sign-up: optional invite/referral code and lookup feedback.
Component signUpReferralStep({
  required String referralCode,
  required ReferralCheck referralCheck,
  required String? referralMessage,
  required String? error,
  required ValueChanged<String> onReferralChanged,
  required VoidCallback onSubmit,
}) => form(
  classes: 'auth-step-form',
  noValidate: true,
  events: {
    'submit': (event) {
      event.preventDefault();
      onSubmit();
    },
  },
  [
    if (error != null) div(classes: 'auth-step-error', [authError(error)]),
    div(classes: 'auth-step-content', [
      authField(
        labelText: 'Invite code',
        name: 'referralCode',
        value: referralCode,
        type: InputType.text,
        autocomplete: 'off',
        identifier: true,
        requiredField: false,
        placeholder: 'Paste a code or invite link',
        icon: 'ticket',
        onInput: onReferralChanged,
      ),
      if (referralMessage != null)
        p(
          classes: switch (referralCheck) {
            ReferralCheck.invalid => 'auth-referral-status auth-referral-status--invalid',
            ReferralCheck.valid => 'auth-referral-status auth-referral-status--valid',
            _ => 'auth-referral-status',
          },
          attributes: {'role': 'status', 'aria-live': 'polite'},
          [.text(referralMessage)],
        ),
      if (referralCheck == ReferralCheck.checking)
        p(
          classes: 'auth-referral-status',
          attributes: {'role': 'status', 'aria-live': 'polite'},
          [.text('Checking the code…')],
        ),
    ]),
  ],
);

/// Visual 4-segment password strength indicator.
Component signUpPasswordStrength(String password) {
  final strength = SignUpLogic.strengthOf(password);
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

Component? _usernameSuffix(UsernameCheck check) => switch (check) {
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
