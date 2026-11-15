import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/presentation/see_all_bottom_bar.dart';
import '../../../auth/logic/auth_actions.dart';
import '../../data/main_canvas.dart';
import '../../data/main_space.dart';
import '../../logic/main_actions.dart';
import '../widgets/app_tab_shell.dart';
import '../widgets/main_home_helpers.dart';
import '../widgets/main_home_notices.dart';

/// Full list of recently opened canvases & structured notes (`/recentCanvasesSeeAll`),
/// matching `RecentCanvasesSeeAllView` + `RecentCanvasListTile` in `../eduma`.
class RecentCanvasesSeeAllPage extends StatefulComponent {
  const RecentCanvasesSeeAllPage({super.key});

  @override
  State<RecentCanvasesSeeAllPage> createState() =>
      _RecentCanvasesSeeAllPageState();
}

class _RecentCanvasesSeeAllPageState extends State<RecentCanvasesSeeAllPage> {
  EdumaSession? _session = AuthActions.currentSession;
  bool _loadingSession = AuthActions.currentSession == null;
  String? _sessionError;
  List<MainCanvas> _canvases = const [];
  String _query = '';
  MainCanvasType? _typeFilter;
  bool _sortByTitle = false;
  bool _filterMenuOpen = false;
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
      setState(() => _canvases = home.recentCanvases);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _sessionError = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load recent pages right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loading = false;
        });
      }
    }
  }

  List<MainCanvas> get _visibleCanvases {
    final q = _query.trim().toLowerCase();
    final filtered = _canvases.where((c) {
      if (_typeFilter != null && c.type != _typeFilter) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          (c.spaceTitle?.toLowerCase().contains(q) ?? false);
    }).toList();
    if (_sortByTitle) {
      filtered.sort(
        (first, second) => first.title.toLowerCase().compareTo(second.title.toLowerCase()),
      );
    }
    return filtered;
  }

  @override
  Component build(BuildContext context) {
    final visible = _visibleCanvases;
    final hasActiveFilter = _typeFilter != null || _sortByTitle;
    return adaptivePageScaffold(
      title: 'Recent pages',
      subtitle:
          '${_canvases.length} recently opened ${_canvases.length == 1 ? 'page' : 'pages'}',
      maxWidth: 1120,
      showEdges: false,
      fallbackHref: '/main',
      trailing: button(
        classes: 'main-home__icon-link main-home__refresh',
        type: ButtonType.button,
        disabled: _loading,
        attributes: {'aria-label': 'Refresh'},
        onClick: () => unawaited(_load()),
        [edumaIcon(EdumaIcons.refresh, size: 18)],
      ),
      body: [
        appSessionGateBody(
          session: _session,
          loadingSession: _loadingSession,
          sessionError: _sessionError,
          onRetrySession: () => unawaited(_load()),
          builder: (_) => [
            if (_error case final err?) mainHomeNotice(err, isError: true),
            if (_loading && _canvases.isEmpty)
              div(classes: 'eduma-page-loading', [
                div(classes: 'eduma-spinner', const []),
              ])
            else if (visible.isEmpty)
              appFeatureStateCard(
                icon: .canvas,
                title: _query.trim().isNotEmpty || _typeFilter != null
                    ? 'No matching pages'
                    : 'No recent pages yet',
                message: _query.trim().isNotEmpty || _typeFilter != null
                    ? 'Try another search term or adjust your filters.'
                    : 'Canvases and structured notes you open across your spaces will appear here.',
              )
            else
              div(classes: 'eduma-see-all__list', [
                for (final canvas in visible) _recentCanvasListTile(canvas),
              ]),
          ],
        ),
      ],
      bottomFloatingBar: _session != null && _canvases.isNotEmpty
          ? seeAllBottomBar(
              query: _query,
              hintText: 'Search recent pages…',
              onQueryChanged: (q) => setState(() => _query = q),
              filterActive: hasActiveFilter,
              filterMenuOpen: _filterMenuOpen,
              onToggleFilterMenu: () =>
                  setState(() => _filterMenuOpen = !_filterMenuOpen),
              onCloseFilterMenu: () => setState(() => _filterMenuOpen = false),
              filterMenuChildren: [
                seeAllFilterGroup('TYPE', [
                  seeAllFilterOption(
                    icon: EdumaIcons.layer,
                    label: 'All pages',
                    selected: _typeFilter == null,
                    onTap: () => setState(() {
                      _typeFilter = null;
                      _filterMenuOpen = false;
                    }),
                  ),
                  seeAllFilterOption(
                    icon: EdumaIcons.canvas,
                    label: 'Canvases',
                    selected: _typeFilter == .dynamicCanvas,
                    onTap: () => setState(() {
                      _typeFilter = .dynamicCanvas;
                      _filterMenuOpen = false;
                    }),
                  ),
                  seeAllFilterOption(
                    icon: EdumaIcons.note,
                    label: 'Notes',
                    selected: _typeFilter == .staticPage,
                    onTap: () => setState(() {
                      _typeFilter = .staticPage;
                      _filterMenuOpen = false;
                    }),
                  ),
                ]),
                seeAllFilterGroup('SORT BY', [
                  seeAllFilterOption(
                    icon: EdumaIcons.clock,
                    label: 'Recently opened',
                    selected: !_sortByTitle,
                    onTap: () => setState(() {
                      _sortByTitle = false;
                      _filterMenuOpen = false;
                    }),
                  ),
                  seeAllFilterOption(
                    icon: EdumaIcons.sort,
                    label: 'Title A–Z',
                    selected: _sortByTitle,
                    onTap: () => setState(() {
                      _sortByTitle = true;
                      _filterMenuOpen = false;
                    }),
                  ),
                ]),
              ],
            )
          : null,
    );
  }
}

Component _recentCanvasListTile(MainCanvas canvas) {
  final isDynamic = canvas.type == .dynamicCanvas;
  final kind = isDynamic ? 'Canvas' : 'Note';
  final path = isDynamic ? '/spacePageCanvas' : '/spacePageStatic';
  final title = canvas.title.isEmpty
      ? 'Untitled ${kind.toLowerCase()}'
      : canvas.title;
  final spaceTitle = (canvas.spaceTitle ?? '').trim();
  final activity = mainHomeCanvasActivityLabel(canvas);
  final meta = spaceTitle.isEmpty ? activity : '$spaceTitle · $activity';
  final route = Uri(
    path: path,
    queryParameters: {'id': canvas.id, 'spaceId': canvas.spaceId},
  ).toString();

  return edumaLink(
    to: route,
    classes: 'eduma-recent-tile',
    children: [
      span(classes: 'eduma-recent-tile__cover', [
        if (canvas.previewUrl case final cover?) ...[
          img(src: cover, alt: ''),
          span(classes: 'eduma-recent-tile__kind-mark', [
            edumaIcon(
              isDynamic ? EdumaIcons.canvas : EdumaIcons.note,
              size: 11,
            ),
          ]),
        ] else
          span(classes: 'eduma-recent-tile__placeholder', [
            edumaIcon(
              isDynamic ? EdumaIcons.canvas : EdumaIcons.note,
              size: 22,
            ),
          ]),
      ]),
      span(classes: 'eduma-recent-tile__copy', [
        strong([.text(title)]),
        span(classes: 'eduma-recent-tile__meta', [.text(meta)]),
      ]),
      span(classes: 'eduma-recent-tile__chevron', [
        edumaIcon(EdumaIcons.chevronRight, size: 15),
      ]),
    ],
  );
}
