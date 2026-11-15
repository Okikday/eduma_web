import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../auth/data/auth_api.dart';
import 'main_home_helpers.dart';

/// Top-level tabs represented across desktop [MainNavRail] and mobile
/// [MainBottomNavBar].
enum MainNavTab { home, calendar, library, notifications, profile, none }

/// Desktop 84px navigation rail matching `MainNavRail` in `../eduma`:
/// 30x30 brand mark, 68x62 tab items with 52x30 active pill indicator,
/// bottom notification status button with unread badge, and 42px profile avatar.
Component mainHomeDesktopRail(
  EdumaSession session, {
  MainNavTab activeTab = .home,
  int unreadNotifications = 0,
}) => nav(
  classes: 'main-home__rail',
  attributes: {'aria-label': 'Main navigation'},
  [
    edumaLink(
      to: '/main',
      classes: 'main-home__rail-logo',
      attributes: {'aria-label': 'Eduma home'},
      children: [img(src: 'assets/logo/logo.png', alt: 'Eduma')],
    ),
    div(classes: 'main-home__rail-items', [
      _railItem(
        label: 'Home',
        to: '/main',
        icon: activeTab == .home
            ? EdumaIcons.navRailHomeActive
            : EdumaIcons.navRailHome,
        active: activeTab == .home,
      ),
      _railItem(
        label: 'Calendar',
        to: '/calendarTab',
        icon: activeTab == .calendar
            ? EdumaIcons.navRailCalendarActive
            : EdumaIcons.navRailCalendar,
        active: activeTab == .calendar,
      ),
      _railItem(
        label: 'Library',
        to: '/libraryTab',
        icon: activeTab == .library
            ? EdumaIcons.navRailLibraryActive
            : EdumaIcons.navRailLibrary,
        active: activeTab == .library,
      ),
    ]),
    span(classes: 'main-home__rail-spacer', []),
    div(classes: 'main-home__rail-footer', [
      edumaLink(
        to: '/notifications',
        classes: activeTab == .notifications
            ? 'main-home__rail-notif is-active'
            : 'main-home__rail-notif',
        attributes: {
          'aria-label': unreadNotifications > 0
              ? 'Notifications ($unreadNotifications unread)'
              : 'Notifications',
          'title': 'Notifications',
        },
        children: [
          edumaIcon(EdumaIcons.navRailNotifications, size: 22),
          if (unreadNotifications > 0)
            span(
              classes: 'eduma-nav-badge eduma-nav-badge--rail',
              attributes: {'aria-label': '$unreadNotifications unread'},
              [
                .text(unreadNotifications > 99 ? '99+' : '$unreadNotifications'),
              ],
            ),
        ],
      ),
      _profileAvatarLink(
        session,
        classes: activeTab == .profile
            ? 'main-home__rail-profile is-active'
            : 'main-home__rail-profile',
        sizePx: 42,
      ),
    ]),
  ],
);

Component _railItem({
  required String label,
  required String to,
  required Object icon,
  required bool active,
}) => edumaLink(
  to: to,
  classes: active ? 'main-home__rail-item is-active' : 'main-home__rail-item',
  attributes: active ? {'aria-current': 'page'} : const {},
  children: [
    span(classes: 'main-home__rail-pill', [edumaIcon(icon, size: 22)]),
    span(classes: 'main-home__rail-label', [.text(label)]),
  ],
);

/// Top bar shared by desktop (`HomeDesktopView1`: greeting + `EEEE, d MMMM` +
/// ordered actions) and mobile (`HomeTabHeader`: avatar + `Hi, $firstName` +
/// `ROLE` + streak chip + notification pill).
Component mainHomeHeader({
  required EdumaSession session,
  required String firstName,
  required String greeting,
  required String desktopFirstName,
  required DateTime now,
  required bool loading,
  required bool hasRecentCanvases,
  required VoidCallback onRefresh,
  required VoidCallback onOpenJoinSpace,
  required VoidCallback onOpenCreateSpace,
  int unreadNotifications = 0,
  int? streakDays,
}) {
  final greetingTitle = desktopFirstName.isEmpty
      ? greeting
      : '$greeting, $desktopFirstName';
  final mobileName = firstName.isEmpty ? 'Friend' : firstName;
  final rawRole = '${session.user['role'] ?? 'student'}'.trim();
  final roleLabel = (rawRole.isEmpty ? 'STUDENT' : rawRole).toUpperCase();
  final badgeText = unreadNotifications > 99 ? '99+' : '$unreadNotifications';

  return header(classes: 'main-home__header', [
    // Mobile HomeTabHeader: 44px avatar + "Hi, Name" / ROLE | StreakChip + notif pill
    div(classes: 'main-home__mobile-topbar', [
      div(classes: 'main-home__mobile-brand', [
        _profileAvatarLink(
          session,
          classes: 'main-home__mobile-avatar',
          sizePx: 44,
        ),
        div(classes: 'main-home__mobile-greeting', [
          span(classes: 'main-home__mobile-hello', [.text('Hi, $mobileName')]),
          span(classes: 'main-home__mobile-role', [.text(roleLabel)]),
        ]),
      ]),
      div(classes: 'main-home__mobile-topbar-actions', [
        _streakChip(streakDays),
        div(classes: 'main-home__mobile-notif-pill', [
          _topCircleRouteLink(
            to: '/notifications',
            icon: unreadNotifications > 0
                ? EdumaIcons.notificationsSolid
                : EdumaIcons.notificationsSquare,
            label: unreadNotifications > 0
                ? 'Notifications ($unreadNotifications unread)'
                : 'Notifications',
            badge: unreadNotifications > 0 ? badgeText : null,
          ),
        ]),
      ]),
    ]),
    // Desktop HomeDesktopView1 header: greeting + date left, ordered actions right
    div(classes: 'main-home__desktop-head', [
      div(classes: 'main-home__desktop-title-col', [
        h1(classes: 'main-home__desktop-title', [.text(greetingTitle)]),
        p(classes: 'main-home__desktop-subtitle', [
          .text(_formatWeekdayDayMonth(now)),
        ]),
      ]),
      div(classes: 'main-home__header-actions', [
        _streakChip(streakDays),
        edumaLink(
          to: '/assistantHistory',
          classes: 'main-home__icon-link main-home__header-circle',
          attributes: {'aria-label': 'AI chats', 'title': 'AI chats'},
          children: [edumaIcon(EdumaIcons.sparkles, size: 19)],
        ),
        if (hasRecentCanvases)
          edumaLink(
            to: '/recentCanvasesSeeAll',
            classes: 'main-home__icon-link main-home__header-circle',
            attributes: {'aria-label': 'Recent pages', 'title': 'Recent pages'},
            children: [edumaIcon(EdumaIcons.canvas, size: 19)],
          ),
        button(
          classes: 'main-home__icon-link main-home__header-circle main-home__refresh',
          type: ButtonType.button,
          disabled: loading,
          attributes: {'aria-label': 'Refresh', 'title': 'Refresh'},
          onClick: onRefresh,
          [edumaIcon(EdumaIcons.refresh, size: 19)],
        ),
        button(
          classes: 'eduma-desktop-pill eduma-desktop-pill--tonal main-home__header-pill',
          type: ButtonType.button,
          onClick: onOpenJoinSpace,
          [edumaIcon(EdumaIcons.login, size: 18), span([.text('Join space')])],
        ),
        button(
          classes: 'eduma-desktop-pill eduma-desktop-pill--primary main-home__header-pill',
          type: ButtonType.button,
          onClick: onOpenCreateSpace,
          [edumaIcon(EdumaIcons.add, size: 18), span([.text('Create space')])],
        ),
      ]),
    ]),
  ]);
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatWeekdayDayMonth(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

Component _streakChip(int? streakDays) {
  final count = streakDays ?? 0;
  final lit = count > 0;
  return edumaLink(
    to: '/streak',
    classes: lit
        ? 'main-home__streak-chip is-lit is-active'
        : 'main-home__streak-chip',
    attributes: {'aria-label': 'Study streak'},
    children: [
      edumaIcon(lit ? EdumaIcons.streakSolid : EdumaIcons.streak, size: 19),
      if (lit) span([.text('$count')]),
    ],
  );
}

Component _topCircleRouteLink({
  required String to,
  required Object icon,
  required String label,
  String? badge,
}) => edumaLink(
  to: to,
  classes: 'main-home__mobile-notif-btn eduma-nav-badge-anchor',
  attributes: {'aria-label': label, 'title': label},
  children: [
    edumaIcon(icon, size: 22),
    if (badge != null) span(classes: 'eduma-nav-badge', [.text(badge)]),
  ],
);

/// Mobile bottom floating pill (`216x68` with `HugeIconsSolid`/`HugeIconsStroke`)
/// + `20px` gap + contextual gradient mini FAB (`44x44`), matching
/// `MainBottomNavBar` in `../eduma`.
Component mainHomeMobileNavigation({
  MainNavTab activeTab = .home,
  bool hasSpaces = false,
  bool hasRecentCanvases = false,
  bool showActionsMenu = true,
  VoidCallback? onOpenCreateSpace,
  VoidCallback? onOpenJoinSpace,
  VoidCallback? onPrimaryAction,
}) => nav(
  classes: 'main-home__mobile-nav',
  attributes: {'aria-label': 'Mobile navigation'},
  [
    div(classes: 'main-home__mobile-tab-bar', [
      _mobileTabLink(
        label: 'Home',
        to: '/main',
        icon: activeTab == .home
            ? EdumaIcons.navBarHomeActive
            : EdumaIcons.navBarHome,
        active: activeTab == .home,
      ),
      _mobileTabLink(
        label: 'Calendar',
        to: '/calendarTab',
        icon: activeTab == .calendar
            ? EdumaIcons.navBarCalendarActive
            : EdumaIcons.navBarCalendar,
        active: activeTab == .calendar,
      ),
      _mobileTabLink(
        label: 'Library',
        to: '/libraryTab',
        icon: activeTab == .library
            ? EdumaIcons.navBarLibraryActive
            : EdumaIcons.navBarLibrary,
        active: activeTab == .library,
      ),
    ]),
    _contextualMobileFab(
      activeTab: activeTab,
      showActionsMenu: showActionsMenu,
      onOpenCreateSpace: onOpenCreateSpace,
      onOpenJoinSpace: onOpenJoinSpace,
      onPrimaryAction: onPrimaryAction,
    ),
  ],
);

Component _mobileTabLink({
  required String label,
  required String to,
  required Object icon,
  required bool active,
}) => edumaLink(
  to: to,
  classes: active
      ? 'main-home__mobile-nav-item is-active'
      : 'main-home__mobile-nav-item',
  attributes: {
    'aria-label': label,
    if (active) 'aria-current': 'page',
  },
  children: [
    span(classes: 'main-home__mobile-nav-icon', [edumaIcon(icon, size: 20)]),
    span(classes: 'main-home__mobile-nav-text', [.text(label)]),
  ],
);

Component _contextualMobileFab({
  required MainNavTab activeTab,
  required bool showActionsMenu,
  VoidCallback? onOpenCreateSpace,
  VoidCallback? onOpenJoinSpace,
  VoidCallback? onPrimaryAction,
}) {
  if (activeTab == .calendar) {
    return button(
      classes: 'main-home__mobile-fab',
      type: ButtonType.button,
      attributes: {'aria-label': 'New event', 'title': 'New event'},
      onClick: onPrimaryAction ?? () {},
      [edumaIcon(EdumaIcons.fabNewEvent, size: 20)],
    );
  }
  if (activeTab == .library) {
    return button(
      classes: 'main-home__mobile-fab',
      type: ButtonType.button,
      attributes: {'aria-label': 'Add to library', 'title': 'Add to library'},
      onClick: onPrimaryAction ?? () {},
      [edumaIcon(EdumaIcons.fabAddLibrary, size: 20)],
    );
  }
  if (showActionsMenu) {
    return details(classes: 'main-home__mobile-action-menu', [
      summary(
        classes: 'main-home__mobile-fab main-home__mobile-action-trigger',
        attributes: {'aria-label': 'Space actions'},
        [edumaIcon(EdumaIcons.fabCreateSpace, size: 20)],
      ),
      div(classes: 'main-home__mobile-actions', [
        if (onOpenCreateSpace != null)
          button(
            classes: 'main-home__mobile-action-item',
            type: ButtonType.button,
            onClick: onOpenCreateSpace,
            [
              edumaIcon(EdumaIcons.add, size: 18),
              span(classes: 'main-home__mobile-action-copy', [.text('Create Space')]),
            ],
          ),
        if (onOpenJoinSpace != null)
          button(
            classes: 'main-home__mobile-action-item',
            type: ButtonType.button,
            onClick: onOpenJoinSpace,
            [
              edumaIcon(EdumaIcons.login, size: 18),
              span(classes: 'main-home__mobile-action-copy', [.text('Join Space')]),
            ],
          ),
        edumaLink(
          to: '/assistantHistory',
          classes: 'main-home__mobile-action-item',
          children: [
            edumaIcon(EdumaIcons.sparkles, size: 18),
            span(classes: 'main-home__mobile-action-copy', [.text('AI chats')]),
          ],
        ),
        edumaLink(
          to: '/recentCanvasesSeeAll',
          classes: 'main-home__mobile-action-item',
          children: [
            edumaIcon(EdumaIcons.canvas, size: 18),
            span(classes: 'main-home__mobile-action-copy', [.text('Recent pages')]),
          ],
        ),
      ]),
    ]);
  }
  return button(
    classes: 'main-home__mobile-fab',
    type: ButtonType.button,
    attributes: {'aria-label': 'Create Space'},
    onClick: onOpenCreateSpace ?? onPrimaryAction ?? () {},
    [edumaIcon(EdumaIcons.fabCreateSpace, size: 20)],
  );
}

Component mainHomeAvatar(
  EdumaSession session, {
  int sizePx = 44,
}) {
  final avatarUrl = mainHomeSafeImageUrl(
    session.user['profilePic'] ?? session.user['avatarUrl'],
  );
  if (avatarUrl != null) {
    return img(
      classes: 'main-home__avatar',
      src: avatarUrl,
      alt: session.name,
      width: sizePx,
      height: sizePx,
    );
  }
  return span(
    classes: 'main-home__avatar main-home__avatar--icon',
    attributes: {'style': 'width: ${sizePx}px; height: ${sizePx}px;'},
    [edumaIcon(EdumaIcons.user, size: (sizePx * 0.5).round())],
  );
}

Component _profileAvatarLink(
  EdumaSession session, {
  required String classes,
  required int sizePx,
}) => edumaLink(
  to: '/profile',
  classes: classes,
  attributes: {
    'aria-label': 'Open profile (${session.name})',
    'title': session.name,
  },
  children: [mainHomeAvatar(session, sizePx: sizePx)],
);
