import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../logic/auth_actions.dart';

class AuthFrame extends StatelessComponent {
  const AuthFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.kicker = '',
  });

  final String title;
  final String subtitle;
  final Component child;
  final String kicker;

  @override
  Component build(BuildContext context) => main_(classes: 'auth-frame', [
    section(classes: 'auth-frame__content', [
      if (kicker.isNotEmpty) p(classes: 'auth-kicker', [.text(kicker)]),
      authHeader(title: title, subtitle: subtitle),
      child,
    ]),
  ]);
}

Component authDesktopFrame(Component child, {bool signUp = false}) => div(
  classes: signUp ? 'auth-desktop-frame auth-desktop-frame--signup' : 'auth-desktop-frame',
  [
    aside(
      classes: 'auth-brand-panel',
      attributes: {'aria-label': 'About Eduma'},
      [
        div(classes: 'auth-brand-art', attributes: {'aria-hidden': 'true'}, []),
        div(classes: 'auth-brand-content', [
          div(classes: 'auth-brand-logo', [
            img(src: 'assets/logo/logo.png', alt: ''),
            strong([.text('Eduma')]),
          ]),
          div(classes: 'auth-brand-message', [
            h2([.text('Learn, plan and'), br(), .text('study together.')]),
            p([
              .text('Your notebooks, study spaces and schedule in one calm place, on every device.'),
            ]),
            div(classes: 'auth-brand-features', [
              _authBrandFeature(
                'book',
                'Curated notebooks',
                'Modular lessons with progress that follows you.',
              ),
              _authBrandFeature(
                'people',
                'Interactive spaces',
                'Pages, files and events shared with your group.',
              ),
              _authBrandFeature(
                'calendar',
                'Smart scheduling',
                'Focus blocks and reminders synced to your calendar.',
              ),
            ]),
          ]),
        ]),
      ],
    ),
    div(classes: 'auth-desktop-form-pane', [child]),
  ],
);

Component _authBrandFeature(String icon, String title, String subtitle) => div(
  classes: 'auth-brand-feature',
  [
    span(classes: 'auth-brand-feature-icon', [authIcon(icon, size: 20)]),
    div([
      strong([.text(title)]),
      p([.text(subtitle)]),
    ]),
  ],
);

Component authHeader({required String title, required String subtitle}) => div(classes: 'auth-header', [
  h1(classes: 'auth-title', [.text(title)]),
  p(classes: 'auth-subtitle', [.text(subtitle)]),
]);

Component authRouteTopBar({
  required String label,
  required VoidCallback onBack,
}) => header(classes: 'auth-route-topbar', [
  button(
    classes: 'auth-topbar-button auth-topbar-button--route',
    type: ButtonType.button,
    onClick: onBack,
    attributes: {'aria-label': label},
    [authIcon('back')],
  ),
]);

Component authField({
  required String labelText,
  required String name,
  required String value,
  required ValueChanged<String> onInput,
  required InputType type,
  required String autocomplete,
  String? placeholder,
  String? icon,
  Component? suffix,
  bool requiredField = true,
  bool disabled = false,
  bool identifier = false,
  bool invalid = false,
  String? describedBy,
  String? enterKeyHint,
  String? fieldClass,
}) {
  final id = 'auth-$name';
  return div(
    classes: fieldClass == null ? 'auth-field' : 'auth-field $fieldClass',
    [
      label(attributes: {'for': id}, [.text(labelText)]),
      div(classes: 'auth-input-wrap', [
        if (icon != null) span(classes: 'auth-field-icon', [authIcon(icon)]),
        input<String>(
          id: id,
          classes: 'auth-field-input',
          type: type,
          name: name,
          value: value,
          disabled: disabled,
          onInput: onInput,
          attributes: {
            'autocomplete': autocomplete,
            if (requiredField) 'required': '',
            if (identifier) ...{
              'autocorrect': 'off',
              'autocapitalize': 'none',
              'spellcheck': 'false',
            },
            if (invalid) 'aria-invalid': 'true',
            if (describedBy != null) 'aria-describedby': describedBy,
            if (enterKeyHint != null) 'enterkeyhint': enterKeyHint,
            if (placeholder != null) 'placeholder': placeholder,
          },
        ),
        if (suffix != null) suffix,
      ]),
    ],
  );
}

Component authError(String message) => div(
  classes: 'auth-notice auth-notice--error',
  attributes: {'role': 'alert'},
  [
    span(classes: 'auth-notice__icon', [authIcon('info')]),
    p([.text(message)]),
  ],
);

Component authSuccess(String message) => div(
  classes: 'auth-notice auth-notice--success',
  attributes: {'role': 'status'},
  [
    span(classes: 'auth-notice__icon', [authIcon('check')]),
    p([.text(message)]),
  ],
);

Component authSubmitButton(
  String label, {
  required bool loading,
  bool enabled = true,
  String? buttonClass,
}) => button(
  classes: buttonClass == null ? 'auth-submit' : 'auth-submit $buttonClass',
  type: ButtonType.submit,
  disabled: loading || !enabled,
  [
    .text(label),
    if (loading) span(classes: 'auth-spinner', []),
  ],
);

Component authConsent({
  required bool value,
  required ValueChanged<bool> onChanged,
  required bool disabled,
}) => div(classes: 'auth-consent', [
  input<bool>(
    id: 'auth-consent',
    type: InputType.checkbox,
    checked: value,
    disabled: disabled,
    onChange: onChanged,
    attributes: {
      'name': 'acceptedTerms',
      'required': '',
      'aria-labelledby': 'auth-consent-copy',
    },
  ),
  p(
    attributes: {'id': 'auth-consent-copy'},
    [
      .text('I have read and agree to the '),
      a(href: _legalDocumentUrl('terms'), [
        .text('Terms of Service'),
      ]),
      .text(' and acknowledge the '),
      a(href: _legalDocumentUrl('privacy'), [
        .text('Privacy Policy'),
      ]),
      .text('.'),
    ],
  ),
]);

Component authDivider({String text = 'Or continue with'}) => div(
  classes: 'auth-divider',
  [
    span(classes: 'auth-divider__line', []),
    span(classes: 'auth-divider__text', [.text(text)]),
    span(classes: 'auth-divider__line', []),
  ],
);

Component authGoogleButton({
  required bool termsAccepted,
  required VoidCallback onUnavailable,
}) {
  if (termsAccepted && edumaGoogleWebClientId.isNotEmpty) {
    return div(
      id: 'google-sign-in-button',
      classes: 'auth-google-rendered',
      attributes: {'data-google-client-id': edumaGoogleWebClientId},
      [],
    );
  }
  return button(
    classes: 'auth-google-icon-button',
    type: ButtonType.button,
    onClick: onUnavailable,
    attributes: {'aria-label': 'Continue with Google'},
    [
      span(classes: 'auth-google-mark', [.text('G')]),
    ],
  );
}

Component authIcon(String name, {int size = 20}) {
  final icon = switch (name) {
    'mail' => EdumaIcons.sms,
    'mail01' => EdumaIcons.mail,
    'lock' => EdumaIcons.lock,
    'user' => EdumaIcons.user,
    'username' => EdumaIcons.userTag,
    'ticket' => EdumaIcons.ticket,
    'key' => EdumaIcons.key,
    'sms-tracking' => EdumaIcons.smsTracking,
    'eye' => EdumaIcons.eye,
    'eye-off' => EdumaIcons.eyeSlash,
    'back' => EdumaIcons.back,
    'close' => EdumaIcons.closeCircle,
    'close-plain' => EdumaIcons.closePlain,
    'cancel-circle' => EdumaIcons.cancelCircle,
    'arrow' => EdumaIcons.chevronRight,
    'info' => EdumaIcons.infoCircle,
    'check' => EdumaIcons.tickCircle,
    'book' => EdumaIcons.book1,
    'people' => EdumaIcons.people,
    'calendar' => EdumaIcons.calendar,
    'camera' => EdumaIcons.camera,
    'gallery-add' => EdumaIcons.galleryAdd,
    _ => EdumaIcons.infoCircle,
  };
  return edumaIcon(icon, size: size);
}

String _legalDocumentUrl(String document) {
  if (AuthActions.canOpenFlutterApp) {
    final workspace = Uri.parse(edumaFlutterAppUrl);
    final base = workspace.path.endsWith('/') ? workspace : workspace.replace(path: '${workspace.path}/');
    return base.resolve('legalDocument?id=$document').toString();
  }
  return Uri.https(
    'app.eduma.com.ng',
    '/legalDocument',
    {'id': document},
  ).toString();
}
