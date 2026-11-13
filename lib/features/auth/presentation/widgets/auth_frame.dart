import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
  final paths = switch (name) {
    'mail' => ['M3 5h18v14H3z', 'm3 6 9 7 9-7'],
    'lock' => ['M5 10h14v11H5z', 'M8 10V7a4 4 0 0 1 8 0v3', 'M12 14v3'],
    'user' => [
      'M20 21a8 8 0 0 0-16 0',
      'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8',
    ],
    'username' => [
      'M4 20a8 8 0 0 1 13.7-5.7',
      'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8',
      'M16 19h6',
      'M19 16v6',
    ],
    'ticket' => [
      'M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v3a2 2 0 0 0 0 4v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-3a2 2 0 0 0 0-4V7z',
      'M13 5v2',
      'M13 11v2',
      'M13 17v2',
    ],
    'eye' => [
      'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z',
      'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6',
    ],
    'eye-off' => [
      'm3 3 18 18',
      'M10.6 10.6a2 2 0 0 0 2.8 2.8',
      'M9.9 5.2A10.8 10.8 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4.1',
      'M6.2 6.2C3.5 8 2 12 2 12s3.6 7 10 7a10.7 10.7 0 0 0 4-.8',
    ],
    'back' => ['m15 18-6-6 6-6', 'M9 12h12'],
    'close' => ['m6 6 12 12', 'M18 6 6 18'],
    'arrow' => ['M5 12h14', 'm12 5 7 7-7 7'],
    'info' => ['M12 11v5', 'M12 8h.01', 'M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0z'],
    'check' => ['m5 12 4 4L19 6'],
    'book' => [
      'M4 5.5A2.5 2.5 0 0 1 6.5 3H20v17H6.5A2.5 2.5 0 0 0 4 22z',
      'M4 5.5v14A2.5 2.5 0 0 1 6.5 17H20',
      'M8 7h8',
      'M8 10h8',
    ],
    'people' => [
      'M16 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2',
      'M10 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8',
      'M20 21v-2a4 4 0 0 0-3-3.87',
      'M16 3.13a4 4 0 0 1 0 7.75',
    ],
    'calendar' => [
      'M8 2v4',
      'M16 2v4',
      'M3 10h18',
      'M5 4h14a2 2 0 0 1 2 2v14H3V6a2 2 0 0 1 2-2z',
      'M8 14h.01',
      'M12 14h.01',
      'M16 14h.01',
      'M8 18h.01',
      'M12 18h.01',
    ],
    _ => const <String>[],
  };

  return svg(
    [
      for (final d in paths) path([], attributes: {'d': d}),
    ],
    viewBox: '0 0 24 24',
    attributes: {
      'width': '$size',
      'height': '$size',
      'fill': 'none',
      'stroke': 'currentColor',
      'stroke-width': '1.8',
      'stroke-linecap': 'round',
      'stroke-linejoin': 'round',
      'aria-hidden': 'true',
    },
  );
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
