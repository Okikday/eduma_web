import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/logic/auth_actions.dart';
import '../../../notifications/data/notifications_api.dart';
import '../../../streak/data/streak_api.dart';
import '../../data/main_api.dart';
import '../../data/main_canvas.dart';
import '../../data/main_space.dart';
import '../../data/main_space_mutations.dart';
import '../../logic/main_actions.dart';
import '../../logic/main_space_query.dart';
import '../../logic/space_invite_link.dart';
import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../widgets/calendar_agenda_panel.dart';
import '../widgets/main_home_create_space_dialog.dart';
import '../widgets/main_home_helpers.dart';
import '../widgets/main_home_highlights.dart';
import '../widgets/main_home_icons.dart';
import '../widgets/main_home_join_space_dialog.dart';
import '../widgets/main_home_navigation.dart';
import '../widgets/main_home_notices.dart';
import '../widgets/main_home_search_bar.dart';
import '../widgets/main_home_space_context_menu.dart';
import '../widgets/main_home_spaces_section.dart';

class MainHomePage extends StatefulComponent {
  const MainHomePage({this.initialJoinCode = '', super.key});

  final String initialJoinCode;

  @override
  State<MainHomePage> createState() => MainHomePageState();
}

class MainHomePageState extends State<MainHomePage> {
  static const _searchDelay = Duration(milliseconds: 350);
  static const _verificationResendCooldown = Duration(seconds: 60);

  EdumaSession? _session = MainActions.currentSession;
  List<MainSpace> _spaces = const [];
  List<MainSpace> _pinnedSpaces = const [];
  List<MainCanvas> _recentCanvases = const [];
  String? _recentCanvasesError;
  List<MainSpace>? _searchResults;
  String _query = '';
  MainSpaceFilter _filter = .all;
  MainSpaceSort _sort = .recent;
  int _page = 1;
  int _searchGeneration = 0;
  Timer? _searchTimer;
  bool _loading = true;
  bool _loadingMore = false;
  bool _searchFocused = false;
  bool _spaceGridView = false;
  bool _gridPrefTouched = false;
  bool _sortPrefTouched = false;
  bool _emailVerificationDismissed = false;
  bool _resendingVerification = false;
  DateTime? _resendAvailableAt;
  Timer? _resendCooldownTimer;
  String? _verificationMessage;
  bool _verificationMessageIsError = false;
  bool _hasMore = false;
  String? _error;
  String? _pageError;
  bool _createDialogOpen = false;
  bool _joinDialogOpen = false;
  bool _handledInitialJoin = false;
  String _joinCodeDraft = '';
  Set<String> _pinningIds = const {};
  MainSpace? _menuSpace;
  int? _streakDays;
  int _unreadNotifications = 0;
  String? _actionMessage;
  bool _actionMessageIsError = false;

  int get _resendSecondsRemaining {
    final availableAt = _resendAvailableAt;
    if (availableAt == null) return 0;
    final milliseconds = availableAt.difference(DateTime.now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    final session = AuthActions.currentSession;
    var hasCached = false;
    if (session != null) {
      EdumaMemoryCache.instance.ensureUser(session.userId);
      final cached = EdumaMemoryCache.instance.home;
      if (cached != null) {
        hasCached = true;
        _session = session;
        _spaces = cached.spaces;
        _pinnedSpaces = cached.pinnedSpaces;
        _recentCanvases = cached.recentCanvases;
        _hasMore = cached.hasMore;
        _streakDays = cached.streakCount > 0 ? cached.streakCount : null;
        _unreadNotifications = EdumaMemoryCache.instance.unreadNotifications ?? 0;
        _loading = false;
      }
    }
    Future<void>.microtask(_restorePreferences);
    Future<void>.microtask(() => _loadHome(background: hasCached));
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _restorePreferences() async {
    final prefs = await MainActions.loadPreferences();
    if (!mounted) return;
    if (!_gridPrefTouched && prefs.spaceGridView != _spaceGridView) {
      setState(() => _spaceGridView = prefs.spaceGridView);
    }
    if (!_sortPrefTouched && prefs.spaceSort != _sort) {
      setState(() => _sort = prefs.spaceSort);
    }
  }

  Future<void> _loadHome({bool background = false}) async {
    _searchGeneration++;
    _searchTimer?.cancel();
    setState(() {
      if (!background) _loading = true;
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
        edumaNavigate(context, '/sign-in', replace: true);
        return;
      }
      if (session.accessToken.isEmpty) {
        throw MainApiException(
          session.warning ?? 'Your session could not be restored. Please sign in again.',
        );
      }
      setState(() => _session = session);
      unawaited(_loadStreak());
      unawaited(_loadUnreadNotifications());
      if (!_handledInitialJoin && component.initialJoinCode.trim().isNotEmpty) {
        _handledInitialJoin = true;
        _joinCodeDraft = component.initialJoinCode.trim();
        _joinDialogOpen = true;
      }
      final result = await MainActions.loadHome(session);
      if (!mounted) return;
      EdumaMemoryCache.instance.ensureUser(session.userId);
      EdumaMemoryCache.instance.home =
          (EdumaMemoryCache.instance.home ??
                  HomeCacheData(
                    spaces: result.spaces,
                    pinnedSpaces: result.pinnedSpaces,
                    recentCanvases: result.recentCanvases,
                    hasMore: result.hasMore,
                  ))
              .copyWith(
                spaces: result.spaces,
                pinnedSpaces: result.pinnedSpaces,
                recentCanvases: result.recentCanvases,
                hasMore: result.hasMore,
              );
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
      setState(() {
        _searchResults = null;
        _pageError = null;
        _error = null;
      });
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

  void _setGridView(bool grid) {
    _gridPrefTouched = true;
    setState(() => _spaceGridView = grid);
    unawaited(MainActions.saveSpaceGridView(grid));
  }

  void _setSort(MainSpaceSort sort) {
    _sortPrefTouched = true;
    setState(() => _sort = sort);
    unawaited(MainActions.saveSpaceSort(sort));
  }

  void _resetFilters() {
    _sortPrefTouched = true;
    setState(() {
      _filter = .all;
      _sort = .recent;
    });
    unawaited(MainActions.saveSpaceSort(.recent));
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
      setState(() => _verificationMessage = 'We sent a new verification code.');
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

  void _openCreateDialog() => setState(() {
    _actionMessage = null;
    _createDialogOpen = true;
  });

  void _openJoinDialog([String code = '']) => setState(() {
    _actionMessage = null;
    _joinCodeDraft = code;
    _joinDialogOpen = true;
  });

  void _onSpaceCreated(MainSpace? created) {
    if (created != null) {
      setState(() {
        _spaces = [created, ..._spaces.where((item) => item.id != created.id)];
        _actionMessage = '“${created.title}” is ready.';
        _actionMessageIsError = false;
      });
    } else {
      setState(() {
        _actionMessage = 'Space created.';
        _actionMessageIsError = false;
      });
    }
    unawaited(_loadHome());
  }

  void _onSpaceJoined(MainSpaceJoinResult result) {
    final joinedSpace = result.space;
    if (joinedSpace != null) {
      setState(() {
        _spaces = [
          joinedSpace,
          ..._spaces.where((item) => item.id != joinedSpace.id),
        ];
        _actionMessage = 'Joined “${joinedSpace.title}”.';
        _actionMessageIsError = false;
      });
    } else {
      setState(() {
        _actionMessage = 'Joined space successfully.';
        _actionMessageIsError = false;
      });
    }
    unawaited(_loadHome());
  }

  void _onSpaceRemoved(MainSpace space) {
    setState(() {
      _spaces = _spaces.where((item) => item.id != space.id).toList();
      _pinnedSpaces = _pinnedSpaces.where((item) => item.id != space.id).toList();
      if (_searchResults != null) {
        _searchResults = _searchResults!.where((item) => item.id != space.id).toList();
      }
      _actionMessage = space.role == MainSpaceRole.owner ? 'Deleted “${space.title}”.' : 'Left “${space.title}”.';
      _actionMessageIsError = false;
    });
    final cached = EdumaMemoryCache.instance.home;
    if (cached != null) {
      EdumaMemoryCache.instance.home = cached.copyWith(
        spaces: cached.spaces.where((item) => item.id != space.id).toList(),
        pinnedSpaces: cached.pinnedSpaces.where((item) => item.id != space.id).toList(),
      );
    }
  }

  Future<void> _togglePin(MainSpace space) async {
    if (_pinningIds.contains(space.id)) return;
    final nextPinned = !space.isPinned;
    if (nextPinned && _pinnedSpaces.length >= SpaceInviteLink.maxPinnedSpaces) {
      setState(() {
        _actionMessage = 'You can pin up to ${SpaceInviteLink.maxPinnedSpaces} spaces.';
        _actionMessageIsError = true;
      });
      return;
    }

    setState(() {
      _actionMessage = null;
      _pinningIds = {..._pinningIds, space.id};
      _spaces = mainHomeReplacePin(_spaces, space.id, nextPinned);
      if (_searchResults != null) {
        _searchResults = mainHomeReplacePin(_searchResults!, space.id, nextPinned);
      }
      _pinnedSpaces = mainHomeSyncPinnedList(_pinnedSpaces, space, nextPinned);
    });

    try {
      await MainActions.setSpacePinned(space.id, pinned: nextPinned);
      if (!mounted) return;
      setState(() {
        _actionMessage = nextPinned ? 'Pinned “${space.title}”' : 'Unpinned “${space.title}”';
        _actionMessageIsError = false;
      });
    } on MainPinLimitException catch (error) {
      _rollbackPin(space, !nextPinned, error.message);
    } on AuthApiException catch (error) {
      _rollbackPin(space, !nextPinned, error.message);
    } on MainApiException catch (error) {
      _rollbackPin(space, !nextPinned, error.message);
    } finally {
      if (mounted) {
        setState(() {
          _pinningIds = {..._pinningIds}..remove(space.id);
        });
      }
    }
  }

  void _rollbackPin(MainSpace space, bool previousPinned, String message) {
    if (!mounted) return;
    setState(() {
      _spaces = mainHomeReplacePin(_spaces, space.id, previousPinned);
      if (_searchResults != null) {
        _searchResults = mainHomeReplacePin(_searchResults!, space.id, previousPinned);
      }
      _pinnedSpaces = mainHomeSyncPinnedList(_pinnedSpaces, space, previousPinned);
      _actionMessage = message;
      _actionMessageIsError = true;
    });
  }

  Future<void> _loadStreak() async {
    try {
      final summary = await StreakApi.instance.loadMyStreak();
      EdumaMemoryCache.instance.home = EdumaMemoryCache.instance.home?.copyWith(
        streakCount: summary.current,
        streakTodayMinutes: summary.todayMinutes,
        streakGoalMinutes: summary.goalMinutes,
      );
      if (mounted) setState(() => _streakDays = summary.current);
    } catch (_) {
      // Streak chip stays compact without a count if streak endpoint is unavailable.
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await NotificationsApi.instance.loadUnreadCount();
      EdumaMemoryCache.instance.unreadNotifications = count;
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {
      // Unread count defaults to 0 when notifications are unavailable.
    }
  }

  @override
  Component build(BuildContext context) {
    final session = _session;
    final now = DateTime.now();
    final trimmedName = session?.name.trim() ?? '';
    final firstName = mainHomeFirstName(trimmedName);
    final items = MainSpaceQuery.apply(
      _searchResults ?? _spaces,
      filter: _filter,
      sort: _sort,
    );

    return main_(
      classes: session != null ? 'main-home main-home--has-agenda' : 'main-home',
      [
        if (session != null)
          mainHomeDesktopRail(
            session,
            unreadNotifications: _unreadNotifications,
          ),
        div(classes: 'main-home__center-wrap', [
          div(classes: 'main-home__content', [
            if (session != null)
              mainHomeHeader(
                session: session,
                firstName: firstName,
                greeting: mainHomeGreetingWord(now),
                desktopFirstName: trimmedName.isEmpty ? '' : firstName,
                now: now,
                loading: _loading,
                hasRecentCanvases: _recentCanvases.isNotEmpty,
                onRefresh: () => unawaited(_loadHome()),
                onOpenJoinSpace: () => _openJoinDialog(),
                onOpenCreateSpace: _openCreateDialog,
                unreadNotifications: _unreadNotifications,
                streakDays: _streakDays,
              ),
            if (_loading && session == null)
              mainHomeLoadingSessionState()
            else if (_error != null && session == null)
              mainHomeSessionErrorState(_error!, onRetry: () => unawaited(_loadHome()))
            else if (session == null)
              mainHomeSignInPromptState()
            else
              div(classes: 'main-home__body', [
                if (_actionMessage case final message?) mainHomeNotice(message, isError: _actionMessageIsError),
                if (_query.trim().isEmpty && session.user['isEmailVerified'] != true && !_emailVerificationDismissed)
                  mainHomeVerifyEmailBanner(
                    session: session,
                    resending: _resendingVerification,
                    secondsRemaining: _resendSecondsRemaining,
                    feedbackMessage: _verificationMessage,
                    feedbackIsError: _verificationMessageIsError,
                    onResend: () => unawaited(_resendVerification()),
                    onDismiss: () => setState(() => _emailVerificationDismissed = true),
                  ),
                if (_query.trim().isEmpty && _recentCanvasesError != null)
                  mainHomeNotice(_recentCanvasesError!, isError: true),
                if (_query.trim().isEmpty && _filter == .all && !_searchFocused)
                  div(key: const ValueKey('main-home-highlights'), classes: 'main-home__highlights', [
                    if (_recentCanvases.isNotEmpty) mainHomeRecentCanvasSection(_recentCanvases),
                    if (_pinnedSpaces.isNotEmpty)
                      mainHomePinnedSection(
                        _pinnedSpaces,
                        onOpenMenu: (space) => setState(() => _menuSpace = space),
                      ),
                  ]),
                div(
                  key: const ValueKey('main-home-search-region'),
                  classes: 'main-home__search-region',
                  attributes: {'role': 'search', 'aria-label': 'Search spaces'},
                  [
                    mainHomeSearchBar(
                      query: _query,
                      filter: _filter,
                      sort: _sort,
                      gridView: _spaceGridView,
                      onSearch: _onSearch,
                      onFocusChanged: (focused) => setState(() => _searchFocused = focused),
                      onSelectFilter: (filter) => setState(() => _filter = filter),
                      onSelectSort: _setSort,
                      onSelectGridView: _setGridView,
                      onResetFilters: _resetFilters,
                    ),
                  ],
                ),
                mainHomeSpacesSection(
                  spaces: items,
                  query: _query,
                  filter: _filter,
                  loading: _loading,
                  error: _error,
                  gridView: _spaceGridView,
                  onRetry: () {
                    if (_query.trim().isEmpty) {
                      unawaited(_loadHome());
                    } else {
                      _onSearch(_query);
                    }
                  },
                  onClearSearch: () => _onSearch(''),
                  onClearFilters: _resetFilters,
                  onOpenCreateSpace: _openCreateDialog,
                  onOpenJoinSpace: () => _openJoinDialog(),
                  onOpenMenu: (space) => setState(() => _menuSpace = space),
                ),
                if (_hasMore)
                  div(classes: 'main-home__load-more', [
                    button(
                      classes: 'main-home__load-more-button',
                      type: ButtonType.button,
                      disabled: _loadingMore,
                      onClick: () => unawaited(_loadMore()),
                      [
                        mainHomeIcon(.refresh),
                        .text(_loadingMore ? 'Loading…' : 'Load more spaces'),
                      ],
                    ),
                  ]),
                if (_pageError case final message?)
                  mainHomeNotice(message, isError: true, onRetry: () => unawaited(_loadMore())),
              ]),
            if (session != null) ...[
              mainHomeMobileNavigation(
                hasSpaces: _spaces.isNotEmpty,
                hasRecentCanvases: _recentCanvases.isNotEmpty,
                onOpenCreateSpace: _openCreateDialog,
                onOpenJoinSpace: () => _openJoinDialog(),
              ),
              MainHomeCreateSpaceDialog(
                open: _createDialogOpen,
                currentUserId: session.userId,
                onClose: () => setState(() => _createDialogOpen = false),
                onCreated: _onSpaceCreated,
              ),
              MainHomeJoinSpaceDialog(
                open: _joinDialogOpen,
                initialCode: _joinCodeDraft,
                currentUserId: session.userId,
                onClose: () => setState(() => _joinDialogOpen = false),
                onJoined: _onSpaceJoined,
              ),
              MainHomeSpaceContextMenuDialog(
                space: _menuSpace,
                pinning: _menuSpace != null && _pinningIds.contains(_menuSpace!.id),
                onClose: () => setState(() => _menuSpace = null),
                onTogglePin: (space) => unawaited(_togglePin(space)),
                onSpaceRemoved: _onSpaceRemoved,
              ),
            ],
          ]),
          if (session != null) desktopQuickNoteFab(),
        ]),
        if (session != null) const CalendarAgendaPanel(),
      ],
    );
  }
}
