import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import 'eduma_icons.dart';
import 'eduma_link.dart';

/// Shared pill button styles matching `DesktopPillButton` in `../eduma`.
enum DesktopPillVariant { primary, tonal, outlined, glass, light }

/// Triggers browser back navigation when history exists, otherwise navigates
/// safely to [fallbackHref].
void navigateBackOrFallback(BuildContext context, {String fallbackHref = '/main'}) {
  final referrer = web.document.referrer;
  if (web.window.history.length > 1 && referrer.isNotEmpty) {
    try {
      final refUri = Uri.parse(referrer);
      if (refUri.host == web.window.location.host) {
        web.window.history.back();
        return;
      }
    } catch (_) {}
  }
  edumaNavigate(context, fallbackHref);
}

/// 50/50 desktop split layout (`>= 1024px`): sticky full-height hero on the
/// left with right-edge dissolve into `var(--eduma-bg)`, and scrollable
/// content pane (`min-width: 460px`) on the right.
Component desktopSplitScaffold({
  required Component hero,
  required Component body,
  String classes = '',
}) => main_(
  classes: classes.isEmpty ? 'eduma-split' : 'eduma-split $classes',
  [
    aside(classes: 'eduma-split__hero', [hero]),
    section(classes: 'eduma-split__body', [body]),
  ],
);

/// Full-height hero pane matching `DesktopHeroPane` in `../eduma`:
/// background artwork + top scrim (120px) + bottom scrim + 34% right-edge fade
/// + corner action slots (`top: 20px, left: 20px` & `top: 20px, right: 88px`)
/// + bottom-left content padded `(40px, 72px, 40px, 40px)`.
Component desktopHeroPane({
  required Component backdrop,
  Component? leading,
  Component? trailing,
  required List<Component> bottomContent,
  String classes = '',
}) => div(
  classes: classes.isEmpty ? 'eduma-hero-pane' : 'eduma-hero-pane $classes',
  [
    div(classes: 'eduma-hero-pane__backdrop', [backdrop]),
    span(classes: 'eduma-hero-pane__top-scrim', attributes: {'aria-hidden': 'true'}, []),
    span(classes: 'eduma-hero-pane__bottom-scrim', attributes: {'aria-hidden': 'true'}, []),
    span(classes: 'eduma-hero-pane__right-fade', attributes: {'aria-hidden': 'true'}, []),
    if (leading != null) div(classes: 'eduma-hero-pane__leading', [leading]),
    if (trailing != null) div(classes: 'eduma-hero-pane__trailing', [trailing]),
    div(classes: 'eduma-hero-pane__content', bottomContent),
  ],
);

/// 42x42 circular frosted-glass button used inside [desktopHeroPane].
Component desktopHeroButton({
  required Object icon,
  required String label,
  VoidCallback? onPressed,
  String? href,
  bool active = false,
  bool disabled = false,
  String classes = '',
}) {
  final cls = [
    'eduma-hero-btn',
    if (active) 'is-active',
    if (classes.isNotEmpty) classes,
  ].join(' ');
  final child = [edumaIcon(icon, size: 20)];
  if (href != null) {
    return edumaLink(
      to: href,
      classes: cls,
      attributes: {'aria-label': label, 'title': label},
      children: child,
    );
  }
  return button(
    classes: cls,
    type: ButtonType.button,
    disabled: disabled,
    attributes: {'aria-label': label, 'title': label},
    onClick: onPressed,
    child,
  );
}

/// 42x42 circular glass back button matching `DesktopHeroPane`'s default
/// leading button.
Component desktopHeroBackButton({
  String fallbackHref = '/main',
  VoidCallback? onPressed,
}) => Builder(
  builder: (context) => desktopHeroButton(
    icon: EdumaIcons.back,
    label: 'Go back',
    onPressed: onPressed ?? () => navigateBackOrFallback(context, fallbackHref: fallbackHref),
  ),
);

/// Pill button matching `DesktopPillButton` (`height: 42px`, `padding: 0 18px`,
/// `gap: 8px`, `14.5px w600`).
Component desktopPillButton({
  required Object icon,
  required String label,
  DesktopPillVariant variant = .primary,
  String? href,
  VoidCallback? onPressed,
  bool disabled = false,
  String classes = '',
}) {
  final cls = [
    'eduma-desktop-pill',
    'eduma-desktop-pill--${variant.name}',
    if (classes.isNotEmpty) classes,
  ].join(' ');
  final content = [
    edumaIcon(icon, size: 18),
    span([.text(label)]),
  ];
  if (href != null) {
    return edumaLink(to: href, classes: cls, children: content);
  }
  return button(
    classes: cls,
    type: ButtonType.button,
    disabled: disabled,
    onClick: onPressed,
    content,
  );
}

/// Pinned translucent top bar matching `PureAppBar` (`56px`, `backdrop-filter:
/// blur(18px)`, `0.5px` bottom hairline, `40x40` frosted `AppBackButton`).
Component pureAppBar({
  required String title,
  String? subtitle,
  Component? leading,
  Component? trailing,
  String fallbackHref = '/main',
  VoidCallback? onBack,
}) => header(
  classes: 'eduma-pure-appbar',
  [
    div(classes: 'eduma-pure-appbar__inner', [
      leading ??
          Builder(
            builder: (context) => button(
              classes: 'eduma-app-back-btn',
              type: ButtonType.button,
              attributes: {'aria-label': 'Go back', 'title': 'Go back'},
              onClick: onBack ?? () => navigateBackOrFallback(context, fallbackHref: fallbackHref),
              [edumaIcon(EdumaIcons.back, size: 20)],
            ),
          ),
      div(classes: 'eduma-pure-appbar__titles', [
        h1(classes: 'eduma-pure-appbar__title', [.text(title)]),
        if (subtitle != null && subtitle.trim().isNotEmpty)
          p(classes: 'eduma-pure-appbar__subtitle', [.text(subtitle)]),
      ]),
      if (trailing != null)
        div(classes: 'eduma-pure-appbar__trailing', [trailing]),
    ]),
  ],
);

/// Root-pushed adaptive page layout matching `PureAppBar` + `ReadableWidth`
/// (`640px` or `880px`), intentionally free of `MainNavRail` / `MainBottomNavBar`.
Component adaptivePageScaffold({
  required String title,
  String? subtitle,
  Component? leading,
  Component? trailing,
  int maxWidth = 640,
  bool showEdges = true,
  required List<Component> body,
  List<Component> overlays = const [],
  Component? bottomFloatingBar,
  String classes = '',
  String fallbackHref = '/main',
  VoidCallback? onBack,
}) {
  final cls = [
    'eduma-adaptive-page',
    if (maxWidth >= 800) 'eduma-adaptive-page--wide',
    if (showEdges) 'has-edges',
    if (classes.isNotEmpty) classes,
  ].join(' ');
  return main_(
    classes: cls,
    [
      div(classes: 'eduma-adaptive-page__column', [
        pureAppBar(
          title: title,
          subtitle: subtitle,
          leading: leading,
          trailing: trailing,
          fallbackHref: fallbackHref,
          onBack: onBack,
        ),
        div(classes: 'eduma-adaptive-page__body', body),
        if (bottomFloatingBar != null) bottomFloatingBar,
      ]),
      ...overlays,
    ],
  );
}

/// Pinned desktop page header matching `DesktopPageHeader` /
/// `DesktopPinnedPageHeader` (`padding: 28px 32px 20px`, `29px w700` title).
Component desktopPinnedPageHeader({
  required String title,
  String? subtitle,
  Component? leading,
  List<Component> actions = const [],
  String classes = '',
}) => header(
  classes: classes.isEmpty ? 'eduma-desktop-header' : 'eduma-desktop-header $classes',
  [
    div(classes: 'eduma-desktop-header__lead', [
      if (leading != null)
        leading
      else ...[
        h1(classes: 'eduma-desktop-header__title', [.text(title)]),
        if (subtitle != null && subtitle.trim().isNotEmpty)
          p(classes: 'eduma-desktop-header__subtitle', [.text(subtitle)]),
      ],
    ]),
    if (actions.isNotEmpty) div(classes: 'eduma-desktop-header__actions', actions),
  ],
);

/// 56x56 circular quick-note action button (`EdumaIcons.quickNote`, `size: 25`)
/// pinned to the bottom-right corner of desktop Home & Library panes.
Component desktopQuickNoteFab({
  String tooltip = 'Quick note',
  VoidCallback? onPressed,
}) {
  if (onPressed == null) {
    return edumaLink(
      to: '/spacePageStatic',
      classes: 'eduma-quick-note-fab',
      attributes: {'aria-label': tooltip, 'title': tooltip},
      children: [edumaIcon(EdumaIcons.quickNote, size: 25)],
    );
  }
  return button(
    classes: 'eduma-quick-note-fab',
    type: ButtonType.button,
    attributes: {'aria-label': tooltip, 'title': tooltip},
    onClick: onPressed,
    [edumaIcon(EdumaIcons.quickNote, size: 25)],
  );
}
