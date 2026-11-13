import 'dart:async';

import 'package:hugeicons_pro/hugeicons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:iconsax_flutter/iconsax_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/logic/auth_actions.dart';
import '../../data/main_space.dart';
import '../../logic/main_actions.dart';

class MainHomePage extends StatefulComponent {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => MainHomePageState();
}

class MainHomePageState extends State<MainHomePage> {
  static const _searchDelay = Duration(milliseconds: 350);

  EdumaSession? _session;
  List<MainSpace> _spaces = const [];
  List<MainSpace> _pinnedSpaces = const [];
  List<MainSpace>? _searchResults;
  String _query = '';
  int _page = 1;
  int _searchGeneration = 0;
  Timer? _searchTimer;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadHome);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHome() async {
    _searchGeneration++;
    _searchTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _pageError = null;
      _searchResults = null;
      _query = '';
      _page = 1;
    });
    try {
      final session = await MainActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _session = null;
          _spaces = const [];
          _pinnedSpaces = const [];
          _hasMore = false;
        });
        return;
      }
      if (session.accessToken.isEmpty) {
        throw MainApiException(
          session.warning ?? 'Your session could not be restored. Please sign in again.',
        );
      }
      setState(() => _session = session);
      final result = await MainActions.loadHome(session);
      if (!mounted) return;
      setState(() {
        _spaces = result.spaces;
        _pinnedSpaces = result.pinnedSpaces;
        _hasMore = result.hasMore;
      });
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on MainApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String value) {
    _searchTimer?.cancel();
    _query = value;
    final generation = ++_searchGeneration;
    if (value.trim().isEmpty) {
      unawaited(_loadHome());
      return;
    }
    setState(() {
      _searchResults = const [];
      _pageError = null;
      _error = null;
      _loading = true;
    });
    _searchTimer = Timer(_searchDelay, () {
      unawaited(_search(generation, value.trim()));
    });
  }

  Future<void> _search(int generation, String query) async {
    try {
      final result = await MainActions.loadSpaces(page: 1, query: query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchResults = result.spaces;
        _page = 1;
        _hasMore = result.hasMore;
      });
    } on AuthApiException catch (error) {
      if (mounted && generation == _searchGeneration) {
        setState(() => _error = error.message);
      }
    } on MainApiException catch (error) {
      if (mounted && generation == _searchGeneration) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final generation = _searchGeneration;
    final nextPage = _page + 1;
    final query = _query.trim();
    setState(() {
      _loadingMore = true;
      _pageError = null;
    });
    try {
      final result = await MainActions.loadSpaces(
        page: nextPage,
        query: query,
      );
      if (!mounted || generation != _searchGeneration) return;
      final current = _searchResults ?? _spaces;
      final ids = current.map((space) => space.id).toSet();
      final combined = [
        ...current,
        for (final space in result.spaces)
          if (ids.add(space.id)) space,
      ];
      setState(() {
        if (query.isEmpty) {
          _spaces = combined;
        } else {
          _searchResults = combined;
        }
        _page = nextPage;
        _hasMore = result.hasMore;
      });
    } on AuthApiException catch (error) {
      if (mounted && generation == _searchGeneration) {
        setState(() => _pageError = error.message);
      }
    } on MainApiException catch (error) {
      if (mounted && generation == _searchGeneration) {
        setState(() => _pageError = error.message);
      }
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Component build(BuildContext context) {
    final session = _session;
    final now = DateTime.now();
    final firstName = session?.name.trim().split(' ').first ?? 'Friend';
    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };
    final items = _searchResults ?? _spaces;

    return main_(classes: 'main-home', [
      if (session != null) _desktopRail(session),
      div(classes: 'main-home__content', [
        if (session != null)
          header(classes: 'main-home__header', [
            a(
              href: _flutterPath('/profile'),
              classes: 'main-home__profile',
              attributes: {'aria-label': 'Open your Eduma profile'},
              [
                _avatar(session),
                div(classes: 'main-home__greeting', [
                  strong([.text('Hi, $firstName')]),
                  span([.text(session.role.toUpperCase())]),
                ]),
              ],
            ),
            div(classes: 'main-home__header-actions', [
              if (AuthActions.canOpenFlutterApp)
                a(
                  href: _flutterPath('/streak'),
                  classes: 'main-home__icon-link',
                  attributes: {'aria-label': 'Study streak'},
                  [_icon(.streak)],
                ),
              if (AuthActions.canOpenFlutterApp)
                a(
                  href: _flutterPath('/notifications'),
                  classes: 'main-home__icon-link',
                  attributes: {'aria-label': 'Notifications'},
                  [_icon(.notifications)],
                ),
              if (AuthActions.canOpenFlutterApp)
                a(
                  href: _flutterPath('/main'),
                  classes: 'main-home__workspace-link',
                  [_icon(.arrow), .text('Open full workspace')],
                ),
            ]),
          ]),
        if (_loading && session == null)
          _loadingPage()
        else if (_error != null && session == null)
          _sessionError(_error!)
        else if (session == null)
          _signInPrompt()
        else
          div(classes: 'main-home__body', [
            if (!AuthActions.canOpenFlutterApp)
              _notice(
                'Calendar, Library, and other unmigrated screens remain in the Flutter workspace. Configure EDUMA_FLUTTER_APP_URL to a separate path on this same origin to enable handoff.',
              ),
            if (session.user['isEmailVerified'] != true) _verifyEmailNotice(),
            _desktopTitle(greeting, firstName, now),
            if (_query.trim().isEmpty && _pinnedSpaces.isNotEmpty) _pinnedSection(_pinnedSpaces),
            _searchBox(),
            _spacesSection(items),
            if (_hasMore && items.isNotEmpty) _loadMoreButton(),
            if (_pageError case final message?) _notice(message, isError: true, retryPage: true),
          ]),
        if (session != null) _mobileNavigation(),
      ]),
    ]);
  }

  Component _desktopRail(EdumaSession session) => nav(
    classes: 'main-home__rail',
    attributes: {'aria-label': 'Main navigation'},
    [
      a(
        href: '/main',
        classes: 'main-home__rail-logo',
        attributes: {'aria-label': 'Eduma Home'},
        [img(src: 'assets/logo/logo.png', alt: '')],
      ),
      _navItem(.railHome, 'Home', '/main', active: true),
      _navItem(.railCalendar, 'Calendar', _flutterPath('/calendarTab')),
      _navItem(.railLibrary, 'Library', _flutterPath('/libraryTab')),
      div(classes: 'main-home__rail-spacer', []),
      _navItem(
        .notifications,
        'Notifications',
        _flutterPath('/notifications'),
      ),
      a(
        href: _flutterPath('/profile'),
        classes: 'main-home__rail-profile',
        attributes: {'aria-label': 'Open your Eduma profile'},
        [_avatar(session)],
      ),
    ],
  );

  Component _navItem(
    _MainHomeIcon icon,
    String label,
    String href, {
    bool active = false,
  }) => a(
    href: href,
    classes: active ? 'main-home__rail-item is-active' : 'main-home__rail-item',
    attributes: {'aria-label': label, if (active) 'aria-current': 'page'},
    [
      _icon(icon, active: active),
      span([.text(label)]),
    ],
  );

  Component _avatar(EdumaSession session) {
    final url = _safeImageUrl(session.user['avatarUrl']);
    if (url != null) {
      return img(
        src: url,
        alt: '',
        classes: 'main-home__avatar',
        attributes: {'aria-hidden': 'true'},
      );
    }
    final name = session.name.trim();
    final initials = name.isEmpty
        ? 'E'
        : name
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();
    return span(classes: 'main-home__avatar main-home__avatar--initials', [
      .text(initials),
    ]);
  }

  Component _desktopTitle(String greeting, String firstName, DateTime now) => div(classes: 'main-home__desktop-title', [
    div([
      h1([.text('$greeting, $firstName')]),
      p([.text(_dateLabel(now))]),
    ]),
    button(
      classes: 'main-home__refresh',
      type: ButtonType.button,
      disabled: _loading,
      onClick: () => unawaited(_loadHome()),
      [_icon(.refresh), .text(_loading ? 'Refreshing…' : 'Refresh')],
    ),
  ]);

  Component _verifyEmailNotice() => div(
    classes: 'main-home__notice main-home__notice--verify',
    attributes: {'role': 'status'},
    [
      div([
        strong([.text('Verify your email')]),
        p([.text('Confirm your email address to keep your Eduma account secure.')]),
      ]),
      a(href: '/verify-email', [.text('Verify now')]),
    ],
  );

  Component _searchBox() => div(classes: 'main-home__search', [
    _icon(.search),
    input<String>(
      type: InputType.search,
      value: _query,
      attributes: {
        'aria-label': 'Search spaces',
        'autocomplete': 'off',
        'enterkeyhint': 'search',
        'placeholder': 'Search spaces',
      },
      onInput: _onSearch,
    ),
    if (_query.isNotEmpty)
      button(
        classes: 'main-home__clear-search',
        type: ButtonType.button,
        attributes: {'aria-label': 'Clear search'},
        onClick: () => _onSearch(''),
        [_icon(.close)],
      ),
  ]);

  Component _pinnedSection(List<MainSpace> spaces) => section(
    classes: 'main-home__pinned',
    attributes: {'aria-labelledby': 'main-pinned-title'},
    [
      div(classes: 'main-home__section-heading', [
        h2(id: 'main-pinned-title', [.text('Pinned')]),
        a(
          href: _flutterPath('/pinnedSpacesSeeAll'),
          classes: 'main-home__see-all',
          [.text('See all')],
        ),
      ]),
      div(classes: 'main-home__pinned-list', [
        for (final space in spaces) _pinnedCard(space),
      ]),
    ],
  );

  Component _pinnedCard(MainSpace space) => a(
    href: _flutterPath('/spaceDetail', query: {'id': space.id}),
    classes: 'main-home__pinned-card',
    [
      if (space.coverUrl case final cover?)
        img(
          src: cover,
          alt: '',
          classes: 'main-home__pinned-cover',
          attributes: {'aria-hidden': 'true'},
        ),
      span(classes: 'main-home__space-avatar', [
        if (space.coverUrl case final cover?) img(src: cover, alt: '') else _icon(.people),
      ]),
      span(classes: 'main-home__pinned-copy', [
        strong([.text(space.title)]),
        if (space.description case final description?) span([.text(description)]),
        span([.text(_memberLabel(space.memberCount))]),
      ]),
      _icon(.arrow),
    ],
  );

  Component _spacesSection(List<MainSpace> spaces) {
    final title = _query.isEmpty ? 'Spaces' : 'Results';
    return section(
      classes: 'main-home__spaces',
      attributes: {'aria-labelledby': 'main-spaces-title'},
      [
        div(classes: 'main-home__section-heading', [
          h2(id: 'main-spaces-title', [.text(title)]),
          if (_query.isEmpty)
            a(
              href: _flutterPath('/recentSpacesSeeAll'),
              classes: 'main-home__see-all',
              [.text('See all')],
            ),
        ]),
        if (_loading && spaces.isEmpty)
          _spaceSkeletons()
        else if (_error != null && spaces.isEmpty)
          _emptyState(
            "Couldn't load your spaces",
            _error!,
            retry: true,
          )
        else if (spaces.isEmpty)
          _emptyState(
            _query.isEmpty ? 'No spaces yet' : 'No spaces found',
            _query.isEmpty ? 'Open the full workspace to create or join a space.' : 'Try a different search.',
          )
        else
          div(classes: 'main-home__space-list', [
            for (final space in spaces) _spaceCard(space),
          ]),
      ],
    );
  }

  Component _spaceCard(MainSpace space) => a(
    href: _flutterPath('/spaceDetail', query: {'id': space.id}),
    classes: 'main-home__space-card',
    [
      span(classes: 'main-home__space-avatar', [
        if (space.coverUrl case final cover?) img(src: cover, alt: '') else _icon(.people),
      ]),
      span(classes: 'main-home__space-copy', [
        strong([.text(space.title)]),
        if (space.description case final description?)
          span(classes: 'main-home__space-description', [.text(description)]),
        span(classes: 'main-home__space-meta', [
          .text(
            '${_memberLabel(space.memberCount)} · ${_activityLabel(space.lastActivity)}',
          ),
        ]),
      ]),
      _icon(.arrow),
    ],
  );

  Component _spaceSkeletons() => div(
    classes: 'main-home__space-list',
    attributes: {'aria-label': 'Loading spaces', 'aria-busy': 'true'},
    [
      for (var index = 0; index < 3; index++)
        div(classes: 'main-home__space-skeleton', [
          span(classes: 'main-home__skeleton-avatar', []),
          span(classes: 'main-home__skeleton-lines', [
            span([]),
            span([]),
            span([]),
          ]),
        ]),
    ],
  );

  Component _loadMoreButton() => div(classes: 'main-home__load-more', [
    button(
      classes: 'main-home__load-more-button',
      type: ButtonType.button,
      disabled: _loadingMore,
      onClick: () => unawaited(_loadMore()),
      [_icon(.refresh), .text(_loadingMore ? 'Loading…' : 'Load more spaces')],
    ),
  ]);

  Component _emptyState(String title, String message, {bool retry = false}) => div(classes: 'main-home__empty-state', [
    _icon(retry ? .warning : .people),
    strong([.text(title)]),
    p([.text(message)]),
    if (retry)
      button(
        classes: 'main-home__retry',
        type: ButtonType.button,
        onClick: () {
          if (_query.trim().isEmpty) {
            unawaited(_loadHome());
          } else {
            _onSearch(_query);
          }
        },
        [_icon(.refresh), .text('Try again')],
      ),
    if (_query.isEmpty && AuthActions.canOpenFlutterApp)
      a(
        href: _flutterPath('/main'),
        classes: 'main-home__workspace-link',
        [_icon(.arrow), .text('Open full workspace')],
      ),
  ]);

  Component _notice(
    String message, {
    bool isError = false,
    bool retryPage = false,
  }) => div(
    classes: isError ? 'main-home__notice main-home__notice--error' : 'main-home__notice',
    attributes: {'role': isError ? 'alert' : 'status'},
    [
      p([.text(message)]),
      if (retryPage)
        button(
          classes: 'main-home__retry',
          type: ButtonType.button,
          onClick: () => unawaited(_loadMore()),
          [.text('Retry')],
        ),
    ],
  );

  Component _loadingPage() => div(
    classes: 'main-home__session-state',
    attributes: {'role': 'status', 'aria-live': 'polite'},
    [
      span(classes: 'main-home__spinner', []),
      p([.text('Restoring your Eduma session…')]),
    ],
  );

  Component _sessionError(String message) => div(
    classes: 'main-home__session-state',
    attributes: {'role': 'alert'},
    [
      h1([.text('Your session needs attention')]),
      p([.text(message)]),
      a(classes: 'main-home__primary-link', href: '/sign-in', [
        .text('Sign in again'),
      ]),
    ],
  );

  Component _signInPrompt() => div(
    classes: 'main-home__session-state',
    [
      h1([.text('Sign in to Eduma')]),
      p([.text('Your spaces and learning dashboard appear here after sign-in.')]),
      a(classes: 'main-home__primary-link', href: '/sign-in', [
        .text('Sign in'),
      ]),
    ],
  );

  Component _mobileNavigation() => nav(
    classes: 'main-home__mobile-nav',
    attributes: {'aria-label': 'Main navigation'},
    [
      _mobileNavItem(.home, 'Home', '/main', active: true),
      _mobileNavItem(.calendar, 'Calendar', _flutterPath('/calendarTab')),
      _mobileNavItem(.book, 'Library', _flutterPath('/libraryTab')),
    ],
  );

  Component _mobileNavItem(
    _MainHomeIcon icon,
    String label,
    String href, {
    bool active = false,
  }) => a(
    href: href,
    classes: active ? 'main-home__mobile-nav-item is-active' : 'main-home__mobile-nav-item',
    attributes: {'aria-label': label, if (active) 'aria-current': 'page'},
    [
      _icon(icon, active: active),
      span([.text(label)]),
    ],
  );

  String _flutterPath(String path, {Map<String, String> query = const {}}) {
    if (!AuthActions.canOpenFlutterApp) return '/account';
    final route = Uri(path: path, queryParameters: query).toString();
    return Uri.parse(edumaFlutterAppUrl).replace(fragment: route).toString();
  }
}

enum _MainHomeIcon {
  home,
  calendar,
  book,
  railHome,
  railCalendar,
  railLibrary,
  people,
  notifications,
  streak,
  search,
  close,
  refresh,
  arrow,
  warning,
}

Component _icon(_MainHomeIcon name, {int size = 20, bool active = false}) {
  return switch (name) {
    .home => HugeIcon(
      icon: active ? HugeIconsSolid.home07 : HugeIconsStroke.home07,
      size: size,
    ),
    .calendar => HugeIcon(
      icon: active ? HugeIconsSolid.calendar03 : HugeIconsStroke.calendar03,
      size: size,
    ),
    .book => HugeIcon(
      icon: active ? HugeIconsSolid.bookOpen02 : HugeIconsStroke.libraries,
      size: size,
    ),
    .railHome => IconsaxIcon(
      icon: active ? Iconsax.home_1 : Iconsax.home_copy,
      size: size,
    ),
    .railCalendar => IconsaxIcon(
      icon: active ? Iconsax.calendar : Iconsax.calendar_1_copy,
      size: size,
    ),
    .railLibrary => IconsaxIcon(
      icon: active ? Iconsax.book : Iconsax.book_copy,
      size: size,
    ),
    .people => IconsaxIcon(icon: Iconsax.people, size: size),
    .notifications => HugeIcon(
      icon: HugeIconsStroke.notificationSquare,
      size: size,
    ),
    .streak => HugeIcon(icon: HugeIconsStroke.fire, size: size),
    .search => IconsaxIcon(icon: Iconsax.search_status_copy, size: size),
    .close => IconsaxIcon(icon: Iconsax.close_circle, size: size),
    .refresh => IconsaxIcon(icon: Iconsax.refresh_copy, size: size),
    .arrow => IconsaxIcon(icon: Iconsax.arrow_right_3, size: size),
    .warning => IconsaxIcon(icon: Iconsax.danger, size: size),
  };
}

String _memberLabel(int count) => '$count ${count == 1 ? 'member' : 'members'}';

String _activityLabel(DateTime? date) {
  if (date == null) return 'Recently active';
  final elapsed = DateTime.now().difference(date);
  if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Updated just now';
  if (elapsed.inHours < 1) return 'Updated ${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return 'Updated ${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return 'Updated ${elapsed.inDays}d ago';
  return 'Updated ${date.month}/${date.day}/${date.year}';
}

String _dateLabel(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
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
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String? _safeImageUrl(Object? value) {
  final uri = Uri.tryParse(value?.toString() ?? '');
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri.toString();
}
