import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../auth/data/auth_api.dart';
import '../../data/streak_api.dart';
import '../../data/streak_models.dart';
import '../widgets/streak_sections.dart';

/// Study streak overview and weekly leaderboard (`/streak`), matching `StreakDesktopView` & `StreakView`.
class StreakPage extends StatefulComponent {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  final _streakApi = StreakApi.instance;

  bool _loading = true;
  bool _refreshing = false;
  bool _authenticated = false;
  bool _leaderboardVisible = true;
  bool _savingVisibility = false;
  String? _error;
  String _currentUserId = '';
  String _currentUserName = '';
  StreakSummaryData _summary = const StreakSummaryData();

  LeaderboardScope _scope = LeaderboardScope.spaces;
  final Map<LeaderboardScope, LeaderboardResponseData> _boards = {};
  StreakLeaderboardStatus _boardStatus = StreakLeaderboardStatus.loading;
  bool _boardRefreshing = false;
  String? _boardError;
  bool _boardUnavailable = false;

  @override
  void initState() {
    super.initState();
    final session = EdumaAuthApi.instance.currentSession;
    var hasCached = false;
    if (session != null) {
      EdumaMemoryCache.instance.ensureUser(session.userId);
      final cachedSummary = EdumaMemoryCache.instance.streakSummary;
      if (cachedSummary != null) {
        _authenticated = true;
        _loading = false;
        _currentUserId = session.userId;
        _currentUserName = session.name.trim();
        _summary = cachedSummary;
        _boards.addAll(EdumaMemoryCache.instance.streakBoards);
        _boardStatus = _boards[_scope] != null
            ? StreakLeaderboardStatus.ready
            : StreakLeaderboardStatus.loading;
        hasCached = true;
      }
    }
    unawaited(_load(background: hasCached));
  }

  Future<void> _load({bool background = false}) async {
    final session = EdumaAuthApi.instance.currentSession ?? await EdumaAuthApi.instance.restoreSession();
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _authenticated = false;
        _loading = false;
        _refreshing = false;
      });
      return;
    }

    _currentUserId = session.userId;
    _currentUserName = session.name.trim();
    EdumaMemoryCache.instance.ensureUser(session.userId);
    if (!background) {
      setState(() {
        _authenticated = true;
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    _boardUnavailable = false;
    await Future.wait([
      _loadOverview(),
      _loadBoard(_scope),
    ]);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _loadOverview() async {
    try {
      final overview = await _streakApi.loadStreakOverview();
      if (!mounted) return;
      EdumaMemoryCache.instance.streakSummary = overview.summary;
      setState(() {
        _summary = overview.summary;
        _leaderboardVisible = overview.leaderboardVisible;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    }
  }

  Future<void> _loadBoard(LeaderboardScope scope) async {
    if (_boardUnavailable) return;
    if (mounted && _scope == scope) {
      setState(() {
        _boardRefreshing = true;
        _boardError = null;
      });
    }
    try {
      final board = await _streakApi.loadLeaderboard(scope);
      if (!mounted) return;
      if (board != null) {
        _boards[scope] = board;
        EdumaMemoryCache.instance.streakBoards[scope] = board;
      }
      if (_scope != scope) return;
      final shown = _boards[scope];
      setState(() {
        _boardRefreshing = false;
        _boardStatus = shown != null ? StreakLeaderboardStatus.ready : StreakLeaderboardStatus.failed;
      });
    } on StreakLeaderboardUnavailableException {
      if (!mounted) return;
      _boardUnavailable = true;
      if (_scope != scope) return;
      setState(() {
        _boardRefreshing = false;
        _boardStatus = _boards[scope] != null
            ? StreakLeaderboardStatus.ready
            : StreakLeaderboardStatus.unavailable;
      });
    } catch (error) {
      if (!mounted) return;
      if (_scope != scope) return;
      final shown = _boards[scope];
      setState(() {
        _boardRefreshing = false;
        _boardStatus = shown != null ? StreakLeaderboardStatus.ready : StreakLeaderboardStatus.failed;
        _boardError = shown == null ? _friendlyError(error) : null;
      });
    }
  }

  void _selectScope(LeaderboardScope nextScope) {
    if (nextScope == _scope) return;
    final cached = _boards[nextScope];
    setState(() {
      _scope = nextScope;
      _boardError = null;
      _boardStatus = _boardUnavailable
          ? StreakLeaderboardStatus.unavailable
          : (cached != null ? StreakLeaderboardStatus.ready : StreakLeaderboardStatus.loading);
    });
    if (!_boardUnavailable) unawaited(_loadBoard(nextScope));
  }

  Future<void> _toggleVisibility(bool nextVisible) async {
    if (_savingVisibility) return;
    final prev = _leaderboardVisible;
    setState(() {
      _leaderboardVisible = nextVisible;
      _savingVisibility = true;
    });
    try {
      final confirmed = await _streakApi.updateLeaderboardVisibility(nextVisible);
      if (!mounted) return;
      setState(() {
        _leaderboardVisible = confirmed;
        _savingVisibility = false;
      });
      unawaited(_loadBoard(_scope));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _leaderboardVisible = prev;
        _savingVisibility = false;
        _error = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) =>
      error is AuthApiException ? error.message : 'Something went wrong. Try again.';

  @override
  Component build(BuildContext context) {
    if (_loading) {
      return div(classes: 'eduma-page-loading', [
        span(classes: 'main-home__spinner', []),
      ]);
    }

    final trailing = _authenticated
        ? button(
            classes: _refreshing ? 'eduma-streak__refresh-btn is-spinning' : 'eduma-streak__refresh-btn',
            type: ButtonType.button,
            attributes: {'aria-label': 'Refresh streak'},
            onClick: () => unawaited(_load(background: true)),
            [edumaIcon(EdumaIcons.refresh, size: 18)],
          )
        : null;

    return adaptivePageScaffold(
      title: 'Streak',
      maxWidth: 1120,
      fallbackHref: '/home',
      trailing: trailing,
      body: [div(classes: 'eduma-streak', [_buildContent()])],
    );
  }

  Component _buildContent() {
    if (!_authenticated && !_loading) {
      return div(classes: 'eduma-streak__guest', [
        span(classes: 'eduma-streak__guest-icon', [edumaIcon(EdumaIcons.streakSolid, size: 28)]),
        h2([.text('Sign in to track your study streak')]),
        p([.text('Your daily study minutes, weekly rest days, and progress stay synced across all devices.')]),
        a(href: '/sign-in?next=/streak', classes: 'eduma-streak__cta', [.text('Sign in')]),
      ]);
    }

    if (_loading) {
      return div(classes: 'eduma-streak__layout', [
        div(classes: 'eduma-streak__overview', [
          div(classes: 'eduma-streak__skel-card', []),
          div(classes: 'eduma-streak__skel-card is-tall', []),
          div(classes: 'eduma-streak__skel-card is-compact', []),
        ]),
        div(classes: 'eduma-streak__leaderboard', [
          div(classes: 'eduma-streak__skel-card is-board', []),
        ]),
      ]);
    }

    return div(classes: 'eduma-streak__layout', [
      if (_error != null) p(classes: 'eduma-streak__error', [.text(_error!)]),
      div(classes: 'eduma-streak__overview', [
        streakHeroCard(_summary),
        streakWeekStrip(_summary),
        streakStatsRow(_summary),
      ]),
      streakLeaderboardSection(
        scope: _scope,
        status: _boardStatus,
        data: _boards[_scope],
        refreshing: _boardRefreshing,
        error: _boardError,
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        onSelectScope: _selectScope,
        onRetry: () {
          _boardUnavailable = false;
          unawaited(_loadBoard(_scope));
        },
      ),
      streakSettingsSection(
        showLeaderboardToggle: _boardStatus != StreakLeaderboardStatus.unavailable,
        leaderboardVisible: _leaderboardVisible,
        savingVisibility: _savingVisibility,
        onToggleVisibility: _toggleVisibility,
      ),
    ]);
  }
}
