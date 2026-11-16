import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/see_all_bottom_bar.dart';
import '../../../auth/logic/auth_actions.dart';
import '../../data/main_space.dart';
import '../../logic/main_actions.dart';
import '../../logic/main_space_query.dart';
import '../widgets/app_tab_shell.dart';
import '../widgets/main_home_icons.dart';
import '../widgets/main_home_notices.dart';
import '../widgets/main_home_space_context_menu.dart';
import '../widgets/main_home_spaces_section.dart';

/// Full list of pinned or recent spaces (`/pinnedSpacesSeeAll` & `/recentSpacesSeeAll`),
/// matching `PinnedSpacesSeeAllView` & `RecentSpacesSeeAllView` via `adaptivePageScaffold`.
class SpacesSeeAllPage extends StatefulComponent {
  const SpacesSeeAllPage({required this.pinnedOnly, super.key});

  final bool pinnedOnly;

  @override
  State<SpacesSeeAllPage> createState() => _SpacesSeeAllPageState();
}

class _SpacesSeeAllPageState extends State<SpacesSeeAllPage> {
  EdumaSession? _session = AuthActions.currentSession;
  bool _loadingSession = AuthActions.currentSession == null;
  String? _sessionError;
  List<MainSpace> _spaces = const [];
  String _query = '';
  MainSpaceFilter _filter = .all;
  MainSpaceSort _sort = .recent;
  bool _filterMenuOpen = false;
  Set<String> _pinningIds = const {};
  MainSpace? _menuSpace;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loadingSession = _session == null;
      _loading = true;
      _sessionError = null;
      _error = null;
    });

    try {
      final session = await AuthActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() => _session = null);
        return;
      }
      setState(() => _session = session);
      final home = await MainActions.loadHome(session);
      if (!mounted) return;
      setState(() {
        _spaces = component.pinnedOnly ? home.pinnedSpaces : home.spaces;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _sessionError = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load spaces right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _togglePin(MainSpace space) async {
    if (_pinningIds.contains(space.id)) return;
    final nextPinned = !space.isPinned;
    setState(() => _pinningIds = {..._pinningIds, space.id});
    try {
      await MainActions.setSpacePinned(space.id, pinned: nextPinned);
      if (!mounted) return;
      setState(() {
        if (component.pinnedOnly && !nextPinned) {
          _spaces = _spaces.where((item) => item.id != space.id).toList();
        } else {
          _spaces = [
            for (final item in _spaces) item.id == space.id ? item.copyWith(isPinned: nextPinned) : item,
          ];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not update pin state.');
    } finally {
      if (mounted) setState(() => _pinningIds = {..._pinningIds}..remove(space.id));
    }
  }

  List<MainSpace> get _visibleSpaces {
    final sorted = MainSpaceQuery.apply(
      _spaces,
      filter: _filter,
      sort: _sort,
    );
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sorted;
    return sorted
        .where(
          (item) => item.title.toLowerCase().contains(q) || (item.description?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Component build(BuildContext context) {
    final visible = _visibleSpaces;
    final hasActiveFilter = _filter != .all || _sort != .recent;
    return adaptivePageScaffold(
      title: component.pinnedOnly ? 'Pinned' : 'Spaces',
      subtitle: '${_spaces.length} ${_spaces.length == 1 ? 'space' : 'spaces'}',
      maxWidth: 1120,
      showEdges: false,
      fullBleed: true,
      fallbackHref: '/main',
      body: [
        appSessionGateBody(
          session: _session,
          loadingSession: _loadingSession,
          sessionError: _sessionError,
          onRetrySession: () => unawaited(_load()),
          builder: (_) => [
            if (_error case final err?) mainHomeNotice(err, isError: true),
            if (_loading && _spaces.isEmpty)
              div(classes: 'eduma-page-loading', [
                div(classes: 'eduma-spinner', const []),
              ])
            else if (visible.isEmpty)
              appFeatureStateCard(
                icon: component.pinnedOnly ? .pin : .layer,
                title: _query.trim().isNotEmpty || _filter != .all
                    ? 'No matching spaces'
                    : (component.pinnedOnly ? 'No pinned spaces' : 'No spaces yet'),
                message: _query.trim().isNotEmpty || _filter != .all
                    ? 'Try another search term or adjust your filters.'
                    : (component.pinnedOnly
                          ? 'Right-click any space on Home to pin it here.'
                          : 'Create or join a space on Home to start collaborating.'),
              )
            else
              div(classes: 'eduma-see-all__list', [
                for (final space in visible)
                  mainHomeSpaceListCard(
                    space,
                    onOpenMenu: (selected) => setState(() => _menuSpace = selected),
                  ),
              ]),
          ],
        ),
      ],
      bottomFloatingBar: _session != null && _spaces.isNotEmpty
          ? seeAllBottomBar(
              query: _query,
              hintText: component.pinnedOnly ? 'Search pinned spaces…' : 'Search spaces…',
              onQueryChanged: (q) => setState(() => _query = q),
              filterActive: hasActiveFilter,
              filterMenuOpen: _filterMenuOpen,
              onToggleFilterMenu: () => setState(() => _filterMenuOpen = !_filterMenuOpen),
              onCloseFilterMenu: () => setState(() => _filterMenuOpen = false),
              filterMenuChildren: [
                if (!component.pinnedOnly)
                  seeAllFilterGroup('SHOW', [
                    for (final f in MainSpaceFilter.values)
                      seeAllFilterOption(
                        icon: switch (f) {
                          .all => EdumaIcons.layer,
                          .owned => EdumaIcons.crown,
                          .joined => EdumaIcons.people,
                          .pinned => EdumaIcons.pin,
                        },
                        label: f.label,
                        selected: _filter == f,
                        onTap: () => setState(() {
                          _filter = f;
                          _filterMenuOpen = false;
                        }),
                      ),
                  ]),
                seeAllFilterGroup('SORT BY', [
                  for (final s in MainSpaceSort.values)
                    seeAllFilterOption(
                      icon: switch (s) {
                        .recent => EdumaIcons.clock,
                        .name => EdumaIcons.sort,
                        .date => EdumaIcons.calendar,
                        .accessed => EdumaIcons.eye,
                      },
                      label: s.label,
                      selected: _sort == s,
                      onTap: () => setState(() {
                        _sort = s;
                        _filterMenuOpen = false;
                      }),
                    ),
                ]),
                if (hasActiveFilter)
                  seeAllFilterGroup('ACTIONS', [
                    button(
                      classes: 'eduma-see-all-bar__menu-item eduma-see-all-bar__menu-reset',
                      type: ButtonType.button,
                      onClick: () => setState(() {
                        _filter = .all;
                        _sort = .recent;
                        _filterMenuOpen = false;
                      }),
                      [
                        span(
                          classes: 'eduma-see-all-bar__menu-icon',
                          [edumaIcon(EdumaIcons.refresh, size: 16)],
                        ),
                        span(
                          classes: 'eduma-see-all-bar__menu-label',
                          [.text('Reset filters')],
                        ),
                      ],
                    ),
                  ]),
              ],
            )
          : null,
      overlays: [
        if (_session != null)
          MainHomeSpaceContextMenuDialog(
            space: _menuSpace,
            pinning: _menuSpace != null && _pinningIds.contains(_menuSpace!.id),
            onClose: () => setState(() => _menuSpace = null),
            onTogglePin: (space) => unawaited(_togglePin(space)),
            onSpaceRemoved: (space) => setState(() {
              _spaces = _spaces.where((item) => item.id != space.id).toList();
            }),
          ),
      ],
    );
  }
}
