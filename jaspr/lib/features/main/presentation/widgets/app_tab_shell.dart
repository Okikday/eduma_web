import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../auth/data/auth_api.dart';
import 'calendar_agenda_panel.dart';
import 'main_home_icons.dart';
import 'main_home_navigation.dart';

/// Shared shell for signed-in main tabs (`Calendar`, `Library`) and legacy
/// transitional subpages before Steps 3–8 migrate them to `desktopSplitScaffold`
/// / `adaptivePageScaffold`.
Component appTabShell({
  required EdumaSession? session,
  required bool loadingSession,
  String? sessionError,
  required VoidCallback onRetrySession,
  MainNavTab activeTab = .none,
  required String title,
  String? subtitle,
  String? backHref,
  String backLabel = 'Back',
  int unreadNotifications = 0,
  List<Component> headerActions = const [],
  required List<Component> body,
  List<Component> overlays = const [],
  VoidCallback? onMobilePrimaryAction,
  bool showAgendaPanel = false,
  bool showQuickNoteFab = false,
}) {
  final effectiveAgenda = showAgendaPanel || activeTab == .library;
  final effectiveQuickNote = showQuickNoteFab || activeTab == .library;

  return main_(
    classes: [
      'main-home',
      'eduma-app-shell',
      if (effectiveAgenda) 'main-home--has-agenda',
      if (activeTab == .library) 'eduma-app-shell--library',
    ].join(' '),
    [
      if (session != null)
        mainHomeDesktopRail(
          session,
          activeTab: activeTab,
          unreadNotifications: unreadNotifications,
        ),
      div(classes: 'main-home__center-wrap', [
        div(classes: 'main-home__content', [
          if (session != null)
            desktopPinnedPageHeader(
              title: title,
              subtitle: subtitle,
              leading: backHref == null
                  ? null
                  : div(classes: 'eduma-subpage-header__lead', [
                      edumaLink(
                        to: backHref,
                        classes: 'eduma-subpage-back',
                        attributes: {'aria-label': backLabel},
                        children: [mainHomeIcon(.back, size: 18)],
                      ),
                      div([
                        h1(classes: 'eduma-desktop-header__title', [.text(title)]),
                        if (subtitle != null && subtitle.trim().isNotEmpty)
                          p(classes: 'eduma-desktop-header__subtitle', [
                            .text(subtitle),
                          ]),
                      ]),
                    ]),
              actions: [
                ...headerActions,
                edumaLink(
                  to: '/notifications',
                  classes: 'main-home__icon-link eduma-nav-badge-anchor',
                  attributes: {'aria-label': 'Notifications'},
                  children: [
                    mainHomeIcon(.notifications),
                    if (unreadNotifications > 0)
                      span(
                        classes: 'eduma-nav-badge',
                        [
                          .text(unreadNotifications > 99 ? '99+' : '$unreadNotifications'),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          if (loadingSession && session == null)
            _stateCard(
              title: 'Loading session…',
              message: 'Checking your Eduma account and workspace preferences.',
            )
          else if (sessionError != null && session == null)
            _stateCard(
              title: 'Unable to reach Eduma',
              message: sessionError,
              actionLabel: 'Retry',
              onAction: onRetrySession,
            )
          else if (session == null)
            _signInPrompt()
          else
            div(classes: 'main-home__body eduma-app-body', body),
          if (session != null) ...[
            mainHomeMobileNavigation(
              activeTab: activeTab == .calendar || activeTab == .library
                  ? activeTab
                  : .home,
              showActionsMenu: false,
              onPrimaryAction: onMobilePrimaryAction,
            ),
            ...overlays,
          ],
        ]),
        if (session != null && effectiveQuickNote) desktopQuickNoteFab(),
      ]),
      if (session != null && effectiveAgenda) const CalendarAgendaPanel(),
    ],
  );
}

Component appSessionGateBody({
  required EdumaSession? session,
  required bool loadingSession,
  String? sessionError,
  required VoidCallback onRetrySession,
  required List<Component> Function(EdumaSession session) builder,
}) {
  if (loadingSession && session == null) {
    return _stateCard(
      title: 'Loading session…',
      message: 'Checking your Eduma account and workspace preferences.',
    );
  }
  if (sessionError != null && session == null) {
    return _stateCard(
      title: 'Unable to reach Eduma',
      message: sessionError,
      actionLabel: 'Retry',
      onAction: onRetrySession,
    );
  }
  if (session == null) return _signInPrompt();
  return .fragment(builder(session));
}

Component appFeatureStateCard({
  required MainHomeIcon icon,
  required String title,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) => div(classes: 'eduma-feature-empty', [
  span(classes: 'eduma-feature-empty__icon', [mainHomeIcon(icon, size: 28)]),
  h2([.text(title)]),
  p([.text(message)]),
  if (actionLabel != null && onAction != null)
    button(
      classes: 'eduma-desktop-pill eduma-desktop-pill--primary',
      type: ButtonType.button,
      onClick: onAction,
      [.text(actionLabel)],
    ),
]);

Component _stateCard({
  required String title,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) => div(classes: 'main-home__session-state', [
  h2([.text(title)]),
  p([.text(message)]),
  if (actionLabel != null && onAction != null)
    button(
      classes: 'main-home__retry',
      type: ButtonType.button,
      onClick: onAction,
      [.text(actionLabel)],
    ),
]);

Component _signInPrompt() => div(classes: 'main-home__session-state', [
  h2([.text('Sign in to continue')]),
  p([.text('Your Eduma session expired or has not started yet.')]),
  edumaLink(
    to: '/sign-in',
    classes: 'main-home__primary-link',
    children: [mainHomeIcon(.login), .text('Sign in')],
  ),
]);
