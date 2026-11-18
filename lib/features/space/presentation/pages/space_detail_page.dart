import 'dart:async';
import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_confirm_dialog.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../auth/data/auth_api.dart';
import '../../../calendar/presentation/widgets/calendar_create_dialog.dart';
import '../../../main/data/main_api.dart';
import '../../../main/data/main_preferences.dart';
import '../../../main/data/main_space.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../../main/presentation/widgets/main_home_space_context_menu.dart';
import '../../data/space_detail_models.dart';
import '../../logic/space_detail_actions.dart';
import '../widgets/space_detail_dialogs.dart';
import '../widgets/space_detail_hero.dart';
import '../widgets/space_detail_pages_tab.dart';
import '../widgets/space_detail_tabs_content.dart';
import '../widgets/space_options_dialog.dart';

class SpaceDetailPage extends StatefulComponent {
  const SpaceDetailPage({required this.spaceId, super.key});

  final String spaceId;

  @override
  State<SpaceDetailPage> createState() => _SpaceDetailPageState();
}

class _SpaceDetailPageState extends State<SpaceDetailPage> {
  EdumaSession? _session = SpaceDetailActions.currentSession;
  SpaceDetailData? _space;
  List<SpacePage> _pages = const [];
  List<SpaceAsset> _assets = const [];
  List<SpaceEvent> _events = const [];
  List<SpaceMember> _members = const [];

  int _tabIndex = 0; // 0: Pages, 1: Assets, 2: Events
  SpacePageFilter _pageFilter = .all;
  bool _filterMenuOpen = false;
  bool _mobileSearchOpen = false;
  bool _selectingPages = false;
  Set<String> _selectedPageIds = const {};
  SpacePage? _optionsPage;
  String _query = '';

  bool _loading = true;
  bool _pinning = false;
  String? _error;
  String? _notice;
  bool _noticeIsError = false;

  Set<String> _mutatingPageIds = const {};
  Set<String> _mutatingMemberIds = const {};

  bool _editDialogOpen = false;
  bool _createPageDialogOpen = false;
  bool _createEventDialogOpen = false;
  bool _inviteDialogOpen = false;
  bool _membersModalOpen = false;
  bool _archivedModalOpen = false;
  bool _optionsOpen = false;
  bool _reportOpen = false;
  bool _removeOpen = false;
  bool _refreshing = false;
  bool _pageGridView = false;
  bool _assetGridView = true;
  bool _pageViewTouched = false;
  bool _assetViewTouched = false;

  @override
  void initState() {
    super.initState();
    final hasCached = _hydrateFromCache(component.spaceId.trim());
    unawaited(_loadViewPreferences());
    Future<void>.microtask(
      () => _load(keepCachedContent: hasCached),
    );
  }

  @override
  void didUpdateComponent(covariant SpaceDetailPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.spaceId != component.spaceId) {
      final hasCached = _hydrateFromCache(component.spaceId.trim());
      Future<void>.microtask(
        () => _load(keepCachedContent: hasCached),
      );
    }
  }

  Future<void> _loadViewPreferences() async {
    final preferences = await MainPreferences.instance.load();
    if (!mounted) return;
    setState(() {
      if (!_pageViewTouched) {
        _pageGridView = preferences.spaceContentGridView;
      }
      if (!_assetViewTouched) {
        _assetGridView = preferences.spaceAssetGridView;
      }
    });
  }

  void _togglePageView() {
    final next = !_pageGridView;
    setState(() {
      _pageViewTouched = true;
      _pageGridView = next;
    });
    unawaited(MainPreferences.instance.saveSpaceContentGridView(next));
  }

  void _toggleAssetView() {
    final next = !_assetGridView;
    setState(() {
      _assetViewTouched = true;
      _assetGridView = next;
    });
    unawaited(MainPreferences.instance.saveSpaceAssetGridView(next));
  }

  bool _hydrateFromCache(String id) {
    final session = _session;
    if (session == null || id.isEmpty) return false;
    EdumaMemoryCache.instance.ensureUser(session.userId);
    final cached = EdumaMemoryCache.instance.spaces[id];
    if (cached == null) {
      _space = null;
      _pages = const [];
      _assets = const [];
      _events = const [];
      _members = const [];
      _loading = true;
      return false;
    }
    _session = cached.session;
    _space = cached.space;
    _pages = cached.pages;
    _assets = cached.assets;
    _events = cached.events;
    _members = cached.members;
    _loading = false;
    return true;
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _load(keepCachedContent: true);
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _copySpaceLink(SpaceDetailData space) async {
    try {
      final link = Uri.base.resolve('/spaces/${Uri.encodeComponent(space.id)}').toString();
      await web.window.navigator.clipboard.writeText(link).toDart;
      if (!mounted) return;
      setState(() {
        _notice = 'Space link copied';
        _noticeIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = 'Could not copy the space link.';
        _noticeIsError = true;
      });
    }
  }

  Future<void> _leaveOrDelete(SpaceDetailData space, {required bool isOwner, required bool deleteMedia}) async {
    final session = _session ?? await SpaceDetailActions.restoreSession();
    if (session == null) {
      throw const AuthApiException(message: 'Your session has expired. Please sign in again.', statusCode: 401);
    }
    await SpaceDetailActions.leaveOrDeleteSpace(
      space.id,
      userId: session.userId,
      deleteSpace: isOwner,
      deleteMedia: deleteMedia,
    );
  }

  Future<void> _load({bool keepCachedContent = false}) async {
    final id = component.spaceId.trim();
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No space id was provided in the address.';
      });
      return;
    }

    setState(() {
      if (!keepCachedContent) {
        _loading = true;
      }
      _error = null;
    });

    try {
      final session = _session ?? await SpaceDetailActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _session = null;
          _loading = false;
        });
        return;
      }
      final bundle = await SpaceDetailActions.loadSpace(session, id);
      if (!mounted) return;
      EdumaMemoryCache.instance.ensureUser(bundle.session.userId);
      EdumaMemoryCache.instance.spaces[id] = bundle;
      setState(() {
        _session = bundle.session;
        _space = bundle.space;
        _pages = bundle.pages;
        _assets = bundle.assets;
        _events = bundle.events;
        _members = bundle.members;
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _togglePin() async {
    final space = _space;
    if (space == null || _pinning) return;
    final nextPinned = !space.isPinned;
    setState(() {
      _pinning = true;
      _notice = null;
      _space = space.copyWith(isPinned: nextPinned);
    });
    try {
      await SpaceDetailActions.setPinned(space.id, pinned: nextPinned);
      if (!mounted) return;
      setState(() {
        _notice = nextPinned ? 'Pinned “${space.title}”' : 'Unpinned “${space.title}”';
        _noticeIsError = false;
      });
    } on MainPinLimitException catch (error) {
      if (!mounted) return;
      setState(() {
        _space = space.copyWith(isPinned: !nextPinned);
        _notice = error.message;
        _noticeIsError = true;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _space = space.copyWith(isPinned: !nextPinned);
        _notice = error.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  Future<void> _toggleArchivePage(SpacePage page) async {
    if (_mutatingPageIds.contains(page.id)) return;
    final nextArchived = !page.isArchived;
    setState(() {
      _mutatingPageIds = {..._mutatingPageIds, page.id};
      _notice = null;
    });
    try {
      final updated = await SpaceDetailActions.updatePage(
        page.spaceId,
        page.id,
        isArchived: nextArchived,
      );
      if (!mounted) return;
      setState(() {
        _pages = [
          for (final item in _pages) item.id == page.id ? updated : item,
        ];
        _notice = nextArchived ? 'Archived “${page.title}”' : 'Restored “${page.title}”';
        _noticeIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _mutatingPageIds = {..._mutatingPageIds}..remove(page.id));
      }
    }
  }

  Future<void> _deletePage(SpacePage page) async {
    if (_mutatingPageIds.contains(page.id)) return;
    setState(() {
      _mutatingPageIds = {..._mutatingPageIds, page.id};
      _notice = null;
    });
    try {
      await SpaceDetailActions.deletePage(page.spaceId, page.id);
      if (!mounted) return;
      setState(() {
        _pages = _pages.where((item) => item.id != page.id).toList();
        _selectedPageIds = {..._selectedPageIds}..remove(page.id);
        _notice = 'Deleted “${page.title}”';
        _noticeIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _mutatingPageIds = {..._mutatingPageIds}..remove(page.id));
      }
    }
  }

  Future<void> _copyPageLink(SpacePage page) async {
    try {
      await web.window.navigator.clipboard.writeText(Uri.base.resolve(spacePageRoutePath(page)).toString()).toDart;
      if (!mounted) return;
      setState(() {
        _notice = 'Copied link to “${page.title}”';
        _noticeIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = 'Could not copy the page link. Check clipboard permissions and try again.';
        _noticeIsError = true;
      });
    }
  }

  void _selectPageFromOptions(SpacePage page) {
    setState(() {
      _optionsPage = null;
      _selectingPages = true;
      _selectedPageIds = {page.id};
    });
  }

  Future<void> _bulkArchiveSelected(List<SpacePage> selectedPages) async {
    if (selectedPages.isEmpty) return;
    final ids = selectedPages.map((page) => page.id).toSet();
    setState(() {
      _mutatingPageIds = {..._mutatingPageIds, ...ids};
      _notice = null;
    });
    var done = 0;
    try {
      for (final page in selectedPages) {
        final updated = await SpaceDetailActions.updatePage(
          page.spaceId,
          page.id,
          isArchived: true,
        );
        if (!mounted) return;
        _pages = [for (final item in _pages) item.id == page.id ? updated : item];
        done++;
      }
      setState(() {
        _selectingPages = false;
        _selectedPageIds = const {};
        _notice = 'Archived $done ${done == 1 ? 'page' : 'pages'}';
        _noticeIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _mutatingPageIds = {..._mutatingPageIds}..removeAll(ids));
      }
    }
  }

  Future<void> _bulkDeleteSelected(List<SpacePage> selectedPages) async {
    if (selectedPages.isEmpty) return;
    final ids = selectedPages.map((page) => page.id).toSet();
    setState(() {
      _mutatingPageIds = {..._mutatingPageIds, ...ids};
      _notice = null;
    });
    var done = 0;
    try {
      for (final page in selectedPages) {
        await SpaceDetailActions.deletePage(page.spaceId, page.id);
        if (!mounted) return;
        _pages = _pages.where((item) => item.id != page.id).toList();
        done++;
      }
      setState(() {
        _selectingPages = false;
        _selectedPageIds = const {};
        _notice = 'Deleted $done ${done == 1 ? 'page' : 'pages'}';
        _noticeIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _mutatingPageIds = {..._mutatingPageIds}..removeAll(ids));
      }
    }
  }

  Future<void> _toggleAdmin(SpaceMember member, bool promote) async {
    final space = _space;
    if (space == null || _mutatingMemberIds.contains(member.id)) return;
    setState(() {
      _mutatingMemberIds = {..._mutatingMemberIds, member.id};
      _notice = null;
    });
    try {
      await SpaceDetailActions.setAdmin(space.id, member.id, promote: promote);
      if (!mounted) return;
      setState(() {
        _members = [
          for (final item in _members) item.id == member.id ? item.copyWith(role: promote ? .admin : .member) : item,
        ];
        _notice = promote ? '${member.name} is now an admin' : 'Removed admin role from ${member.name}';
        _noticeIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _mutatingMemberIds = {..._mutatingMemberIds}..remove(member.id));
      }
    }
  }

  Future<void> _removeMember(SpaceMember member) async {
    final space = _space;
    if (space == null || _mutatingMemberIds.contains(member.id)) return;
    setState(() {
      _mutatingMemberIds = {..._mutatingMemberIds, member.id};
      _notice = null;
    });
    try {
      await SpaceDetailActions.removeMember(space.id, member.id);
      if (!mounted) return;
      setState(() {
        _members = _members.where((item) => item.id != member.id).toList();
        if (_space != null) {
          _space = _space!.copyWith(
            memberCount: _space!.memberCount > 0 ? _space!.memberCount - 1 : 0,
          );
        }
        _notice = 'Removed ${member.name} from ${space.title}';
        _noticeIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _mutatingMemberIds = {..._mutatingMemberIds}..remove(member.id));
      }
    }
  }

  @override
  Component build(BuildContext context) {
    final session = _session;
    final space = _space;

    if (_loading && space == null) {
      return div(
        classes: 'eduma-page-loading',
        attributes: {'role': 'status', 'aria-live': 'polite', 'aria-label': 'Loading space'},
        [span(classes: 'main-home__spinner', [])],
      );
    }

    if ((_error != null && space == null) || session == null || space == null) {
      return adaptivePageScaffold(
        title: 'Space',
        maxWidth: 640,
        fallbackHref: '/main',
        body: [
          if (_error != null && space == null)
            mainHomeSessionErrorState(_error!, onRetry: () => unawaited(_load()))
          else
            mainHomeSignInPromptState(),
        ],
      );
    }

    return _buildLoaded(session, space);
  }

  Component _buildLoaded(EdumaSession session, SpaceDetailData space) {
    final permissions = SpacePermissionsLogic(
      space: space,
      currentUserId: session.userId,
    );
    final activePages = _pages.where((page) => !page.isArchived).toList();
    final archivedPages = _pages.where((page) => page.isArchived).toList();
    final filteredPages = SpacePageQuery.apply(
      _pages,
      filter: _pageFilter == .archived ? .all : _pageFilter,
      query: _query,
    );

    final hero = spaceDetailDesktopHero(
      space: space,
      permissions: permissions,
      activePageCount: activePages.length,
      archivedCount: archivedPages.length,
      assetCount: _assets.length,
      eventCount: _events.length,
      pinning: _pinning,
      refreshing: _refreshing,
      onTogglePin: () => unawaited(_togglePin()),
      onRefresh: () => unawaited(_refresh()),
      onOpenOptions: () => setState(() => _optionsOpen = true),
      onOpenEdit: () => setState(() => _editDialogOpen = true),
      onOpenInvite: () => setState(() => _inviteDialogOpen = true),
      onOpenMembers: () => setState(() => _membersModalOpen = true),
      onOpenArchived: () => setState(() => _archivedModalOpen = true),
      onSelectTab: (idx) => setState(() => _tabIndex = idx),
    );

    final rightPane = div(classes: 'space-detail__pane', [
      spaceDetailMobileHeader(
        space: space,
        permissions: permissions,
        archivedCount: archivedPages.length,
        pinning: _pinning,
        onTogglePin: () => unawaited(_togglePin()),
        onOpenEdit: () => setState(() => _editDialogOpen = true),
        onOpenInvite: () => setState(() => _inviteDialogOpen = true),
        onOpenMembers: () => setState(() => _membersModalOpen = true),
        onOpenArchived: () => setState(() => _archivedModalOpen = true),
      ),
      div(classes: 'space-detail__pane-inner', [
        spaceDetailTabToolbar(
          activeTabIndex: _tabIndex,
          query: _query,
          pageFilter: _pageFilter,
          filterMenuOpen: _filterMenuOpen,
          mobileSearchOpen: _mobileSearchOpen,
          selectingPages: _selectingPages,
          visiblePagesCount: filteredPages.length,
          selectedPagesCount: _selectedPageIds.length,
          allVisibleSelected:
              filteredPages.isNotEmpty && filteredPages.every((page) => _selectedPageIds.contains(page.id)),
          canManagePages: permissions.isManager,
          canAddPages: permissions.canAddPages,
          canAddEvents: permissions.canAddEvents,
          gridView: _tabIndex == 0 ? _pageGridView : _assetGridView,
          onToggleView: _tabIndex == 0 ? _togglePageView : _toggleAssetView,
          onSelectTab: (idx) => setState(() {
            _tabIndex = idx;
            _filterMenuOpen = false;
            _selectingPages = false;
            _selectedPageIds = const {};
          }),
          onSearch: (next) => setState(() => _query = next),
          onToggleFilterMenu: (open) => setState(() => _filterMenuOpen = open),
          onSelectPageFilter: (next) => setState(() => _pageFilter = next),
          onToggleMobileSearch: () => setState(() => _mobileSearchOpen = !_mobileSearchOpen),
          onEnterSelection: () => setState(() {
            _selectingPages = true;
            _filterMenuOpen = false;
            _selectedPageIds = const {};
          }),
          onExitSelection: () => setState(() {
            _selectingPages = false;
            _selectedPageIds = const {};
          }),
          onToggleSelectAll: () {
            final allSelected =
                filteredPages.isNotEmpty && filteredPages.every((page) => _selectedPageIds.contains(page.id));
            setState(() {
              _selectedPageIds = allSelected ? const {} : {for (final page in filteredPages) page.id};
            });
          },
          onArchiveSelected: () => unawaited(
            _bulkArchiveSelected([
              for (final page in filteredPages)
                if (_selectedPageIds.contains(page.id)) page,
            ]),
          ),
          onDeleteSelected: () => unawaited(
            _bulkDeleteSelected([
              for (final page in filteredPages)
                if (_selectedPageIds.contains(page.id)) page,
            ]),
          ),
          onOpenCreatePage: () => setState(() => _createPageDialogOpen = true),
          onOpenCreateEvent: () => setState(() => _createEventDialogOpen = true),
        ),
        if (_notice case final message?)
          div(classes: 'space-detail__pane-notice', [
            mainHomeNotice(message, isError: _noticeIsError),
          ]),
        div(classes: 'space-detail__pane-body', [
          if (_tabIndex == 0)
            spaceDetailPagesTab(
              filteredPages: filteredPages,
              filter: _pageFilter,
              query: _query,
              gridView: _pageGridView,
              canManagePages: permissions.isManager,
              canCreatePage: permissions.canAddPages,
              selecting: _selectingPages,
              selectedPageIds: _selectedPageIds,
              mutatingPageIds: _mutatingPageIds,
              onSelectFilter: (next) => setState(() => _pageFilter = next),
              onOpenCreatePage: () => setState(() => _createPageDialogOpen = true),
              onToggleSelectPage: (page) => setState(() {
                final next = {..._selectedPageIds};
                if (!next.add(page.id)) {
                  next.remove(page.id);
                }
                _selectedPageIds = next;
              }),
              onOpenPageOptions: (page) => setState(() => _optionsPage = page),
            )
          else if (_tabIndex == 1)
            spaceDetailAssetsTab(
              assets: _assets,
              query: _query,
              gridView: _assetGridView,
            )
          else
            spaceDetailEventsTab(
              events: _events,
              query: _query,
              canAddEvents: permissions.canAddEvents,
              onOpenCreateEvent: () => setState(() => _createEventDialogOpen = true),
            ),
        ]),
      ]),
      if ((_tabIndex == 0 && permissions.canAddPages && !_selectingPages) ||
          (_tabIndex == 2 && permissions.canAddEvents))
        button(
          classes: 'space-detail__mobile-fab',
          type: ButtonType.button,
          attributes: {
            'aria-label': _tabIndex == 0 ? 'New page' : 'New event',
          },
          onClick: () => setState(() {
            if (_tabIndex == 0) {
              _createPageDialogOpen = true;
            } else {
              _createEventDialogOpen = true;
            }
          }),
          [
            edumaIcon(
              _tabIndex == 0 ? EdumaIcons.add : EdumaIcons.calendarAdd,
              size: 24,
            ),
          ],
        ),
    ]);

    return div(classes: 'space-detail', [
      desktopSplitScaffold(hero: hero, body: rightPane),
      SpaceOptionsDialog(
        open: _optionsOpen,
        space: space,
        permissions: permissions,
        onClose: () => setState(() => _optionsOpen = false),
        onInvite: () => setState(() => _inviteDialogOpen = true),
        onMembers: () => setState(() => _membersModalOpen = true),
        onEdit: () => setState(() => _editDialogOpen = true),
        onReport: () => setState(() => _reportOpen = true),
        onLeaveOrDelete: () => setState(() => _removeOpen = true),
        onCopyLink: () => unawaited(_copySpaceLink(space)),
      ),
      if (_reportOpen)
        SpaceReportDialog(
          spaceId: space.id,
          spaceTitle: space.title,
          onClose: () => setState(() => _reportOpen = false),
        ),
      EdumaConfirmDialog(
        id: 'space-remove-dialog',
        open: _removeOpen,
        title: permissions.isOwner ? 'Delete space?' : 'Leave space?',
        message: permissions.isOwner
            ? '“${space.title}” and everything in it will be deleted for all members. This can’t be undone.'
            : 'You’ll lose access to “${space.title}” and its shared materials until you’re invited again.',
        confirmLabel: permissions.isOwner ? 'Delete' : 'Leave',
        destructive: true,
        optionLabel: permissions.isOwner ? 'Delete all files in this space' : 'Also delete my files',
        optionSubtitle: permissions.isOwner
            ? 'Files stored for this space and copies on this device'
            : 'Files you added to this space and copies saved on this device',
        optionDefault: permissions.isOwner,
        onConfirmWithOption: (deleteMedia) =>
            _leaveOrDelete(space, isOwner: permissions.isOwner, deleteMedia: deleteMedia),
        onConfirmed: () => edumaNavigate(context, '/main'),
        onClose: () => setState(() => _removeOpen = false),
      ),
      SpaceEditDialog(
        open: _editDialogOpen,
        space: space,
        onClose: () => setState(() => _editDialogOpen = false),
        onUpdated: (updated) => setState(() {
          _space = updated;
          _notice = 'Space updated';
          _noticeIsError = false;
        }),
      ),
      SpaceCreatePageDialog(
        open: _createPageDialogOpen,
        spaceId: space.id,
        onClose: () => setState(() => _createPageDialogOpen = false),
        onCreated: (created) => setState(() {
          _pages = [created, ..._pages.where((item) => item.id != created.id)];
          _notice = 'Created “${created.title}”';
          _noticeIsError = false;
        }),
      ),
      SpaceInviteDialog(
        open: _inviteDialogOpen,
        space: space,
        canRenew: permissions.canRenewInvite,
        onClose: () => setState(() => _inviteDialogOpen = false),
        onInviteRenewed: (inviteCode, expiresAt) => setState(() {
          _space = space.copyWith(inviteCode: inviteCode, inviteCodeExpiresAt: expiresAt);
        }),
      ),
      CalendarCreateDialog(
        open: _createEventDialogOpen,
        initialDate: DateTime.now(),
        onClose: () => setState(() => _createEventDialogOpen = false),
        onCreated: (_) => unawaited(_load(keepCachedContent: true)),
      ),
      spaceMembersModal(
        open: _membersModalOpen,
        members: _members,
        currentUserId: session.userId,
        canManageMembers: permissions.canManageMembers,
        isOwner: permissions.isOwner,
        canInvite: permissions.canInvite,
        mutatingMemberIds: _mutatingMemberIds,
        onClose: () => setState(() => _membersModalOpen = false),
        onOpenInvite: () => setState(() => _inviteDialogOpen = true),
        onToggleAdmin: (member, promote) => unawaited(_toggleAdmin(member, promote)),
        onRemoveMember: (member) => unawaited(_removeMember(member)),
      ),
      spaceArchivedPagesModal(
        open: _archivedModalOpen,
        archivedPages: archivedPages,
        canManagePages: permissions.isManager,
        mutatingPageIds: _mutatingPageIds,
        onClose: () => setState(() => _archivedModalOpen = false),
        onRestorePage: (page) => unawaited(_toggleArchivePage(page)),
        onDeletePage: (page) => unawaited(_deletePage(page)),
      ),
      spacePageOptionsModal(
        page: _optionsPage,
        canManagePages: permissions.isManager,
        busy: _optionsPage != null && _mutatingPageIds.contains(_optionsPage!.id),
        onClose: () => setState(() => _optionsPage = null),
        onCopyPageLink: (page) => unawaited(_copyPageLink(page)),
        onSelectPage: _selectPageFromOptions,
        onToggleArchive: (page) => unawaited(_toggleArchivePage(page)),
        onDeletePage: (page) => unawaited(_deletePage(page)),
      ),
    ]);
  }
}
