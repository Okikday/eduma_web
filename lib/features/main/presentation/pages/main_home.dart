import 'dart:async';

import 'package:hugeicons_pro/hugeicons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:iconsax_flutter/iconsax_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/logic/auth_actions.dart';
import '../../data/main_canvas.dart';
import '../../data/main_space.dart';
import '../../logic/main_actions.dart';
import '../../logic/main_space_query.dart';

class MainHomePage extends StatefulComponent {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => MainHomePageState();
}

class MainHomePageState extends State<MainHomePage> {
  static const _searchDelay = Duration(milliseconds: 350);
  static const _verificationResendCooldown = Duration(seconds: 60);

  EdumaSession? _session;
  List<MainSpace> _spaces = const [];
  List<MainSpace> _pinnedSpaces = const [];
  List<MainCanvas> _recentCanvases = const [];
  String? _recentCanvasesError;
  List<MainSpace>? _searchResults;
  MainSpaceFilter _filter = .all;
  MainSpaceSort _sort = .recent;
  String _query = '';
  int _page = 1;
  int _searchGeneration = 0;
  Timer? _searchTimer;
  bool _loading = true;
  bool _loadingMore = false;
  bool _searchFocused = false;
  bool _spaceGridView = false;
  bool _emailVerificationDismissed = false;
  bool _resendingVerification = false;
  DateTime? _resendAvailableAt;
  Timer? _resendCooldownTimer;
  String? _verificationMessage;
  bool _verificationMessageIsError = false;
  int _filterMenuKey = 0;
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
    _resendCooldownTimer?.cancel();
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
          _recentCanvases = const [];
          _recentCanvasesError = null;
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
        _recentCanvases = result.recentCanvases;
        _recentCanvasesError = result.recentCanvasesError;
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
      final result = await MainActions.loadSpaces(
        page: 1,
        query: query,
        currentUserId: _session?.userId ?? '',
      );
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
        currentUserId: _session?.userId ?? '',
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
    final items = MainSpaceQuery.apply(
      _searchResults ?? _spaces,
      filter: _filter,
      sort: _sort,
    );

    return main_(
      classes: 'main-home',
      [
        if (session != null) _desktopRail(session),
        div(classes: 'main-home__content', [
          if (session != null)
            header(classes: 'main-home__header', [
              if (AuthActions.canOpenFlutterApp)
                a(
                  href: _flutterPath('/profile')!,
                  classes: 'main-home__profile',
                  attributes: {'aria-label': 'Open Profile & settings'},
                  [
                    _avatar(session),
                    _greetingIdentity(session, firstName),
                  ],
                )
              else
                div(classes: 'main-home__profile', [
                  _avatar(session),
                  _greetingIdentity(session, firstName),
                ]),
              _desktopTitle(
                greeting,
                session.name.trim().isEmpty ? '' : firstName,
                now,
              ),
              div(classes: 'main-home__header-actions', [
                if (AuthActions.canOpenFlutterApp) ...[
                  a(
                    href: _flutterPath('/streak')!,
                    classes: 'main-home__icon-link',
                    attributes: {'aria-label': 'Study streak'},
                    [_icon(.streak)],
                  ),
                ],
                if (AuthActions.canOpenFlutterApp && _recentCanvases.isNotEmpty)
                  a(
                    href: _flutterPath('/recentCanvasesSeeAll')!,
                    classes: 'main-home__icon-link main-home__desktop-action',
                    attributes: {'aria-label': 'Recent pages'},
                    [_icon(.canvas)],
                  ),
                if (AuthActions.canOpenFlutterApp)
                  a(
                    href: _flutterPath('/assistantHistory')!,
                    classes: 'main-home__icon-link main-home__desktop-action',
                    attributes: {'aria-label': 'AI chats'},
                    [_icon(.ai)],
                  ),
                if (AuthActions.canOpenFlutterApp) ...[
                  a(
                    href: _flutterPath('/notifications')!,
                    classes: 'main-home__icon-link main-home__mobile-action',
                    attributes: {'aria-label': 'Notifications'},
                    [_icon(.notifications)],
                  ),
                  button(
                    classes: 'main-home__icon-link main-home__refresh main-home__desktop-action',
                    type: ButtonType.button,
                    disabled: _loading,
                    attributes: {'aria-label': 'Refresh'},
                    onClick: () => unawaited(_loadHome()),
                    [_icon(.refresh)],
                  ),
                ],
                if (AuthActions.canOpenFlutterApp) ...[
                  _handoffLink(
                    '/main',
                    'main-home__action-button main-home__desktop-action',
                    [.text('Join space')],
                  ),
                  _handoffLink(
                    '/main',
                    'main-home__action-button main-home__action-button--primary main-home__desktop-action',
                    [_icon(.add), .text('Create space')],
                  ),
                ],
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
              if (_query.trim().isEmpty && session.user['isEmailVerified'] != true && !_emailVerificationDismissed)
                _verifyEmailNotice(session),
              if (_query.trim().isEmpty && _recentCanvasesError != null) _notice(_recentCanvasesError!, isError: true),
              if (_query.trim().isEmpty && !_searchFocused)
                div(classes: 'main-home__highlights', [
                  if (_recentCanvases.isNotEmpty) _recentCanvasSection(_recentCanvases),
                  if (_pinnedSpaces.isNotEmpty) _pinnedSection(_pinnedSpaces),
                ]),
              div(
                classes: 'main-home__search-region',
                attributes: {'role': 'search', 'aria-label': 'Search spaces'},
                [_searchBox()],
              ),
              _spacesSection(items),
              if (_hasMore) _loadMoreButton(),
              if (_pageError case final message?) _notice(message, isError: true, retryPage: true),
            ]),
          if (session != null) _mobileNavigation(),
        ]),
      ],
    );
  }

  Component _desktopRail(EdumaSession session) => nav(
    classes: 'main-home__rail',
    attributes: {'aria-label': 'Main navigation'},
    [
      a(
        href: '/home',
        classes: 'main-home__rail-logo',
        attributes: {'aria-label': 'Eduma Home'},
        [img(src: 'assets/logo/logo.png', alt: '')],
      ),
      _navItem(.railHome, 'Home', '/home', active: true),
      _navItem(.railCalendar, 'Calendar', _flutterPath('/calendar')),
      _navItem(.railLibrary, 'Library', _flutterPath('/library')),
      div(classes: 'main-home__rail-spacer', []),
      _navItem(
        .notifications,
        'Notifications',
        _flutterPath('/notifications'),
      ),
      div(classes: 'main-home__rail-bottom-gap', []),
      if (AuthActions.canOpenFlutterApp)
        a(
          href: _flutterPath('/profile')!,
          classes: 'main-home__rail-profile',
          attributes: {'aria-label': 'Open your Eduma profile'},
          [_avatar(session)],
        )
      else
        div(classes: 'main-home__rail-profile', [_avatar(session)]),
    ],
  );

  Component _navItem(
    _MainHomeIcon icon,
    String label,
    String? href, {
    bool active = false,
  }) {
    final classes = [
      'main-home__rail-item',
      if (active) 'is-active',
      if (href == null) 'is-disabled',
    ].join(' ');
    final content = [
      _icon(icon, active: active),
      span(classes: 'main-home__rail-label', [.text(label)]),
    ];
    if (href == null) {
      return span(
        classes: classes,
        content,
      );
    }
    return a(
      href: href,
      classes: classes,
      attributes: {'aria-label': label, if (active) 'aria-current': 'page'},
      content,
    );
  }

  Component _greetingIdentity(EdumaSession session, String firstName) => div(classes: 'main-home__greeting', [
    strong([.text('Hi, $firstName')]),
    span([.text(session.role.toUpperCase())]),
  ]);

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
      h1([.text(firstName.isEmpty ? greeting : '$greeting, $firstName')]),
      p([.text(_dateLabel(now))]),
    ]),
  ]);

  int get _resendSecondsRemaining {
    final availableAt = _resendAvailableAt;
    if (availableAt == null) return 0;
    final milliseconds = availableAt.difference(DateTime.now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  Component _verifyEmailNotice(EdumaSession session) {
    final email = '${session.user['email'] ?? ''}'.trim();
    final secondsRemaining = _resendSecondsRemaining;
    return div(
      classes: 'main-home__notice main-home__notice--verify',
      [
        _icon(.email),
        div(classes: 'main-home__verification-copy', [
          strong([.text('Verify your email')]),
          p([
            .text(
              email.isEmpty
                  ? 'Enter the 6-digit code we emailed you to confirm your email address.'
                  : 'We sent a 6-digit code to $email. Enter it to confirm your email address.',
            ),
          ]),
          if (_verificationMessage case final message?)
            p(
              [.text(message)],
              attributes: {'role': _verificationMessageIsError ? 'alert' : 'status'},
            ),
          div(classes: 'main-home__verification-actions', [
            a(
              href: '/verify-email',
              classes: 'main-home__verification-primary',
              [_icon(.key), .text('Enter code')],
            ),
            button(
              classes: 'main-home__verification-resend',
              type: ButtonType.button,
              disabled: _resendingVerification || secondsRemaining > 0,
              onClick: () => unawaited(_resendVerification()),
              [
                _icon(.refresh, size: 15),
                .text(
                  _resendingVerification
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
          onClick: () => setState(() => _emailVerificationDismissed = true),
          [_icon(.close)],
        ),
      ],
    );
  }

  void _startResendCooldown(int seconds) {
    _resendCooldownTimer?.cancel();
    _resendAvailableAt = DateTime.now().add(Duration(seconds: seconds));
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining == 0) {
        timer.cancel();
        _resendCooldownTimer = null;
      }
      setState(() {});
    });
    setState(() {});
  }

  Future<void> _resendVerification() async {
    setState(() {
      _resendingVerification = true;
      _verificationMessage = null;
      _verificationMessageIsError = false;
    });
    try {
      await AuthActions.resendVerification();
      if (!mounted) return;
      setState(() {
        _verificationMessage = 'We sent a new verification code.';
      });
      _startResendCooldown(_verificationResendCooldown.inSeconds);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _verificationMessage = error.message;
        _verificationMessageIsError = true;
      });
      final retryAfter = int.tryParse('${error.details['retryAfter'] ?? ''}');
      if (error.statusCode == 429 && retryAfter != null && retryAfter > 0) {
        _startResendCooldown(retryAfter);
      }
    } finally {
      if (mounted) setState(() => _resendingVerification = false);
    }
  }

  Component _searchBox() => div(classes: 'main-home__search-row', [
    div(classes: 'main-home__search', [
      _icon(.search),
      input<String>(
        type: InputType.search,
        value: _query,
        attributes: {
          'aria-label': 'Search spaces',
          'autocomplete': 'off',
          'autocorrect': 'off',
          'autocapitalize': 'none',
          'enterkeyhint': 'search',
          'placeholder': 'Search spaces...',
          'spellcheck': 'false',
        },
        events: {
          'focus': (_) => setState(() => _searchFocused = true),
          'blur': (_) => setState(() => _searchFocused = false),
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
    ]),
    details(
      [
        summary(
          [_icon(.filter)],
          classes: 'main-home__filter-trigger',
          attributes: {'aria-label': 'Filter & sort'},
        ),
        div(classes: 'main-home__filter-menu', [
          _filterMenuSection(
            'SHOW',
            [
              for (final filter in MainSpaceFilter.values)
                _filterMenuItem(
                  _filterIconFor(filter),
                  filter.label,
                  _filter == filter,
                  () => setState(() {
                    _filter = filter;
                    _filterMenuKey++;
                  }),
                ),
            ],
          ),
          _filterMenuSection(
            'SORT BY',
            [
              for (final sort in MainSpaceSort.values)
                _filterMenuItem(
                  _sortIconFor(sort),
                  sort.label,
                  _sort == sort,
                  () => setState(() {
                    _sort = sort;
                    _filterMenuKey++;
                  }),
                ),
            ],
          ),
          _filterMenuSection(
            'VIEW',
            [
              _filterMenuItem(
                .list,
                'List',
                !_spaceGridView,
                () => setState(() {
                  _spaceGridView = false;
                  _filterMenuKey++;
                }),
              ),
              _filterMenuItem(
                .grid,
                'Grid',
                _spaceGridView,
                () => setState(() {
                  _spaceGridView = true;
                  _filterMenuKey++;
                }),
              ),
            ],
          ),
          if (_filter != .all || _sort != .recent)
            button(
              classes: 'main-home__reset-filters',
              type: ButtonType.button,
              onClick: () => setState(() {
                _filter = .all;
                _sort = .recent;
                _filterMenuKey++;
              }),
              [_icon(.refresh, size: 15), .text('Reset filters')],
            ),
        ]),
      ],
      key: ValueKey(_filterMenuKey),
      classes: 'main-home__filter-disclosure',
    ),
  ]);

  Component _filterMenuSection(String title, List<Component> options) => div(
    classes: 'main-home__filter-group',
    [
      strong([.text(title)]),
      ...options,
    ],
  );

  Component _filterMenuItem(
    _MainHomeIcon icon,
    String title,
    bool selected,
    VoidCallback onClick,
  ) => button(
    classes: 'main-home__filter-option',
    type: ButtonType.button,
    attributes: {'aria-pressed': '$selected'},
    onClick: onClick,
    [
      _icon(icon, size: 17),
      span([.text(title)]),
      if (selected) _icon(.check, size: 16),
    ],
  );

  _MainHomeIcon _filterIconFor(MainSpaceFilter filter) => switch (filter) {
    .all => .layer,
    .owned => .owner,
    .joined => .people,
    .pinned => .pin,
  };

  _MainHomeIcon _sortIconFor(MainSpaceSort sort) => switch (sort) {
    .recent => .clock,
    .name => .sort,
    .date => .calendar,
    .accessed => .eye,
  };

  Component _recentCanvasSection(List<MainCanvas> canvases) => section(
    classes: 'main-home__recent',
    attributes: {'aria-labelledby': 'main-recent-title'},
    [
      div(classes: 'main-home__section-heading', [
        h2(id: 'main-recent-title', [.text('Recent Canvas')]),
        if (canvases.length > 1)
          _handoffLink(
            '/recentCanvasesSeeAll',
            'main-home__see-all',
            [.text('See all')],
          ),
      ]),
      div(classes: 'main-home__recent-list', [
        for (final canvas in canvases) _recentCanvasCard(canvas),
      ]),
    ],
  );

  Component _recentCanvasCard(MainCanvas canvas) {
    final path = canvas.type == .dynamicCanvas ? '/spacePageCanvas' : '/spacePageStatic';
    final title = canvas.title.isEmpty
        ? canvas.type == .dynamicCanvas
              ? 'Untitled canvas'
              : 'Untitled note'
        : canvas.title;
    return _handoffLink(
      path,
      'main-home__recent-card',
      [
        span(
          classes: 'main-home__recent-cover',
          [
            if (canvas.previewUrl case final cover?)
              img(src: cover, alt: '')
            else
              _icon(
                canvas.type == .dynamicCanvas ? .canvas : .note,
                size: 27,
              ),
          ],
        ),
        span(classes: 'main-home__recent-copy', [
          span(classes: 'main-home__recent-space', [
            .text(canvas.spaceTitle ?? 'Space'),
          ]),
          strong([.text(title)]),
          span(classes: 'main-home__recent-footer', [
            span(classes: 'main-home__recent-meta', [
              .text(_canvasActivityLabel(canvas)),
            ]),
            span(classes: 'main-home__resume', [.text('Resume')]),
          ]),
        ]),
        span(classes: 'main-home__canvas-type', [
          _icon(
            canvas.type == .dynamicCanvas ? .canvas : .note,
            size: 12,
          ),
          .text(canvas.type == .dynamicCanvas ? 'Canvas' : 'Notes'),
        ]),
      ],
      query: {'id': canvas.id, 'spaceId': canvas.spaceId},
    );
  }

  Component _pinnedSection(List<MainSpace> spaces) => section(
    classes: 'main-home__pinned',
    attributes: {'aria-labelledby': 'main-pinned-title'},
    [
      div(classes: 'main-home__section-heading', [
        h2(id: 'main-pinned-title', [.text('Pinned')]),
        _handoffLink(
          '/pinnedSpacesSeeAll',
          'main-home__see-all',
          [.text('See all')],
        ),
      ]),
      div(classes: 'main-home__pinned-list', [
        for (final space in spaces) _pinnedCard(space),
      ]),
    ],
  );

  Component _pinnedCard(MainSpace space) => _handoffLink(
    '/spaceDetail',
    'main-home__pinned-card',
    [
      if (space.coverUrl case final cover?)
        img(
          src: cover,
          alt: '',
          classes: 'main-home__pinned-cover',
          attributes: {'aria-hidden': 'true'},
        ),
      _spaceAvatar(space, pinned: true),
      span(classes: 'main-home__pinned-copy', [
        span(classes: 'main-home__space-name', [
          strong([.text(space.title)]),
          if (space.isVerified) _icon(.verified, size: 14),
        ]),
        if (space.description case final description?) span([.text(description)]),
        _memberRow(space, onGradient: true),
      ]),
      if (AuthActions.canOpenFlutterApp) _icon(.arrow),
    ],
    query: {'id': space.id},
  );

  Component _spacesSection(List<MainSpace> spaces) {
    final searching = _query.trim().isNotEmpty;
    return section(
      classes: 'main-home__spaces',
      attributes: {'aria-label': searching ? 'Search results' : 'All spaces'},
      [
        div(classes: 'main-home__section-heading', [
          h2([.text(searching ? 'Results' : 'All spaces')]),
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
          _spacesEmptyState(searching)
        else
          div(
            classes: [
              'main-home__space-list',
              if (_spaceGridView) 'main-home__space-list--grid',
            ].join(' '),
            [
              for (final space in spaces) _spaceCard(space),
            ],
          ),
      ],
    );
  }

  Component _spacesEmptyState(bool searching) {
    if (searching) {
      return _emptyState(
        'No spaces match “${_query.trim()}”',
        'Check the spelling or try a different word.',
        actions: [
          button(
            classes: 'main-home__empty-action',
            type: ButtonType.button,
            onClick: () => _onSearch(''),
            [.text('Clear')],
          ),
        ],
      );
    }
    if (_filter != .all) {
      return _emptyState(
        'No spaces match these filters',
        'Try another type or show all your spaces.',
        actions: [
          button(
            classes: 'main-home__empty-action',
            type: ButtonType.button,
            onClick: () => setState(() {
              _filter = .all;
              _sort = .recent;
            }),
            [.text('Clear')],
          ),
        ],
      );
    }
    return _emptyState(
      'No spaces yet',
      'Create a collaborative space for your courses, study groups, and notes, or enter an invite code to join an existing space.',
      actions: [
        _handoffLink(
          '/main',
          'main-home__empty-action main-home__empty-action--primary',
          [_icon(.add), .text('Create Space')],
        ),
        _handoffLink(
          '/main',
          'main-home__empty-action',
          [_icon(.login), .text('Join Space')],
        ),
      ],
    );
  }

  Component _spaceCard(MainSpace space) {
    if (_spaceGridView) {
      return _spaceGridCard(space);
    }
    return _handoffLink(
      '/spaceDetail',
      'main-home__space-card',
      [
        _spaceAvatar(space),
        span(classes: 'main-home__space-copy', [
          span(classes: 'main-home__space-name', [
            strong([.text(space.title)]),
            if (space.isVerified) _icon(.verified, size: 14),
          ]),
          if (space.description case final description?)
            span(classes: 'main-home__space-description', [
              .text(description),
            ]),
          _memberRow(space),
        ]),
        if (AuthActions.canOpenFlutterApp) _icon(.arrow),
      ],
      query: {'id': space.id},
    );
  }

  Component _spaceGridCard(MainSpace space) {
    final activity = _activityLabel(space.lastActivity, space.activityType);
    final members = space.isPersonal ? 'Only you' : _memberLabel(space.memberCount);
    final meta = activity.isEmpty ? members : '$members · $activity';
    return _handoffLink(
      '/spaceDetail',
      'main-home__space-grid-card',
      [
        span(classes: 'main-home__space-grid-art', [
          if (space.coverUrl case final cover?)
            img(src: cover, alt: '')
          else
            _icon(space.isPersonal ? .home : .people, size: 48),
          if (space.role case MainSpaceRole.owner || MainSpaceRole.admin)
            span(
              classes: 'main-home__role-badge',
              attributes: {
                'aria-label': space.role == .owner ? 'Space owner' : 'Space administrator',
              },
              [_icon(space.role == .owner ? .owner : .admin, size: 10)],
            ),
        ]),
        span(classes: 'main-home__space-grid-copy', [
          span(classes: 'main-home__space-name', [
            strong([.text(space.title)]),
            if (space.isVerified) _icon(.verified, size: 14),
          ]),
          span(classes: 'main-home__space-grid-meta', [.text(meta)]),
        ]),
      ],
      query: {'id': space.id},
    );
  }

  Component _spaceAvatar(MainSpace space, {bool pinned = false}) => span(
    classes: [
      'main-home__space-avatar',
      if (pinned) 'main-home__space-avatar--pinned',
    ].join(' '),
    [
      if (space.coverUrl case final cover?) img(src: cover, alt: '') else _icon(space.isPersonal ? .home : .people),
      if (space.role case MainSpaceRole.owner || MainSpaceRole.admin)
        span(
          classes: 'main-home__role-badge',
          attributes: {
            'aria-label': space.role == .owner ? 'Space owner' : 'Space administrator',
          },
          [_icon(space.role == .owner ? .owner : .admin, size: 10)],
        ),
    ],
  );

  Component _memberRow(MainSpace space, {bool onGradient = false}) {
    final members = space.memberPreview.take(3).toList();
    final activity = _activityLabel(space.lastActivity, space.activityType);
    if (space.isPersonal) {
      return span(classes: 'main-home__member-row', [
        span(classes: 'main-home__personal-label', [
          .text('Personal'),
        ]),
      ]);
    }
    return span(
      classes: [
        'main-home__member-row',
        if (onGradient) 'main-home__member-row--inverse',
      ].join(' '),
      [
        if (members.isNotEmpty)
          span(classes: 'main-home__member-stack', [
            for (final member in members)
              span(classes: 'main-home__member-avatar', [
                if (member.avatarUrl case final url?) img(src: url, alt: '') else .text(_initials(member.name)),
              ]),
          ]),
        span(classes: 'main-home__member-meta', [
          .text(_memberLabel(space.memberCount)),
          if (activity.isNotEmpty) .text(' · $activity'),
        ]),
      ],
    );
  }

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

  Component _emptyState(
    String title,
    String message, {
    bool retry = false,
    List<Component> actions = const [],
  }) => div(
    classes: 'main-home__empty-state',
    [
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
      if (actions.isNotEmpty) div(classes: 'main-home__empty-actions', actions),
    ],
  );

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
      div(classes: 'main-home__mobile-tab-bar', [
        _mobileNavItem(.home, 'Home', '/home', active: true),
        _mobileNavItem(.calendar, 'Calendar', _flutterPath('/calendar')),
        _mobileNavItem(.book, 'Library', _flutterPath('/library')),
      ]),
      _mobileActionsMenu(),
    ],
  );

  Component _mobileNavItem(
    _MainHomeIcon icon,
    String label,
    String? href, {
    bool active = false,
  }) {
    final classes = [
      'main-home__mobile-nav-item',
      if (active) 'is-active',
      if (href == null) 'is-disabled',
    ].join(' ');
    final content = [
      span(classes: 'main-home__mobile-nav-icon', [
        _icon(icon, active: active),
      ]),
      span([.text(label)]),
    ];
    if (href == null) {
      return span(
        classes: classes,
        content,
      );
    }
    return a(
      href: href,
      classes: classes,
      attributes: {'aria-label': label, if (active) 'aria-current': 'page'},
      content,
    );
  }

  Component _mobileActionsMenu() => details(
    [
      summary(
        [_icon(.addAction)],
        classes: 'main-home__mobile-action-trigger',
        attributes: {'aria-label': 'Create or open a Home action'},
      ),
      div(classes: 'main-home__mobile-action-menu', [
        _mobileActionLink(
          '/main',
          'Create',
          'Create a space',
          .add,
        ),
        _mobileActionLink(
          '/main',
          'Join',
          'Join a space with an invite link or code',
          .login,
        ),
        if (_spaces.isNotEmpty)
          _mobileActionLink(
            '/recentSpacesSeeAll',
            'All spaces',
            'See all your spaces',
            .expand,
          ),
        _mobileActionLink(
          '/assistantHistory',
          'Recent AI chats',
          'Pick up a study chat',
          .ai,
        ),
        if (_recentCanvases.isNotEmpty)
          _mobileActionLink(
            '/recentCanvasesSeeAll',
            'Recent pages',
            'Pages you opened lately',
            .canvas,
          ),
      ]),
    ],
    classes: 'main-home__mobile-actions',
  );

  Component _mobileActionLink(
    String path,
    String title,
    String subtitle,
    _MainHomeIcon icon,
  ) => _handoffLink(
    path,
    'main-home__mobile-action-item',
    [
      _icon(icon, size: 20),
      span(classes: 'main-home__mobile-action-copy', [
        strong([.text(title)]),
        span([.text(subtitle)]),
      ]),
    ],
  );

  Component _handoffLink(
    String path,
    String classes,
    List<Component> children, {
    Map<String, String> query = const {},
  }) {
    final href = _flutterPath(path, query: query);
    if (href == null) {
      return div(
        classes: '$classes is-disabled',
        children,
      );
    }
    return a(href: href, classes: classes, children);
  }

  String? _flutterPath(String path, {Map<String, String> query = const {}}) {
    if (!AuthActions.canOpenFlutterApp) return null;
    final base = Uri.parse(edumaFlutterAppUrl);
    final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
    final appBase = base.replace(path: basePath, query: '', fragment: '');
    final routePath = path.startsWith('/') ? path.substring(1) : path;
    return appBase
        .resolve(
          Uri(
            path: routePath,
            queryParameters: query.isEmpty ? null : query,
          ).toString(),
        )
        .toString();
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
  email,
  key,
  refresh,
  arrow,
  warning,
  add,
  addAction,
  ai,
  check,
  canvas,
  clock,
  expand,
  eye,
  filter,
  grid,
  layer,
  list,
  login,
  note,
  pin,
  sort,
  verified,
  owner,
  admin,
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
    .email => IconsaxIcon(icon: Iconsax.sms_tracking_copy, size: size),
    .key => IconsaxIcon(icon: Iconsax.key_copy, size: size),
    .refresh => IconsaxIcon(icon: Iconsax.refresh_copy, size: size),
    .arrow => IconsaxIcon(icon: Iconsax.arrow_right_3, size: size),
    .warning => IconsaxIcon(icon: Iconsax.danger, size: size),
    .add => IconsaxIcon(icon: Iconsax.add_copy, size: size),
    .addAction => HugeIcon(icon: HugeIconsStroke.addCircleHalfDot, size: size),
    .ai => HugeIcon(icon: HugeIconsStroke.aiMagic, size: size),
    .check => IconsaxIcon(icon: Iconsax.tick_circle_copy, size: size),
    .canvas => HugeIcon(icon: HugeIconsStroke.canvas, size: size),
    .clock => IconsaxIcon(icon: Iconsax.clock_copy, size: size),
    .expand => HugeIcon(icon: HugeIconsStroke.expand, size: size),
    .eye => IconsaxIcon(icon: Iconsax.eye_copy, size: size),
    .filter => IconsaxIcon(icon: Iconsax.filter_copy, size: size),
    .grid => IconsaxIcon(icon: Iconsax.element_3_copy, size: size),
    .layer => HugeIcon(icon: HugeIconsStroke.layer, size: size),
    .list => IconsaxIcon(icon: Iconsax.row_vertical_copy, size: size),
    .login => IconsaxIcon(icon: Iconsax.login_copy, size: size),
    .note => HugeIcon(icon: HugeIconsStroke.note, size: size),
    .pin => IconsaxIcon(icon: Iconsax.bookmark_copy, size: size),
    .sort => IconsaxIcon(icon: Iconsax.sort_copy, size: size),
    .verified => IconsaxIcon(icon: Iconsax.verify, size: size),
    .owner => HugeIcon(icon: HugeIconsSolid.crown, size: size),
    .admin => HugeIcon(icon: HugeIconsSolid.shieldUser, size: size),
  };
}

String _memberLabel(int count) => '$count ${count == 1 ? 'member' : 'members'}';

String _activityLabel(
  DateTime? date,
  MainSpaceActivityType? activityType,
) {
  if (date == null || activityType == null) return '';
  final elapsed = DateTime.now().difference(date);
  final prefix = activityType == .edited ? 'Edited' : 'Opened';
  if (elapsed.isNegative || elapsed.inMinutes < 1) return '$prefix just now';
  if (elapsed.inHours < 1) return '$prefix ${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return '$prefix ${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return '$prefix ${elapsed.inDays}d ago';
  return '$prefix ${date.month}/${date.day}/${date.year}';
}

String _canvasActivityLabel(MainCanvas canvas) {
  final openedAt = canvas.openedAt;
  if (openedAt == null) {
    return 'Resume ${canvas.type == .dynamicCanvas ? 'canvas' : 'note'}';
  }
  final elapsed = DateTime.now().difference(openedAt);
  if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Opened just now';
  if (elapsed.inHours < 1) return 'Opened ${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return 'Opened ${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return 'Opened ${elapsed.inDays}d ago';
  return 'Opened ${openedAt.month}/${openedAt.day}/${openedAt.year}';
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

String _initials(String? name) {
  final parts = name?.trim().split(RegExp(r'\s+')) ?? const [];
  return parts.where((part) => part.isNotEmpty).take(2).map((part) => part[0].toUpperCase()).join();
}

String? _safeImageUrl(Object? value) {
  final uri = Uri.tryParse(value?.toString() ?? '');
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri.toString();
}
