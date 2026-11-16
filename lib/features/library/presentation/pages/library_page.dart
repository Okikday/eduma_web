import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../auth/logic/auth_actions.dart';
import '../../../main/presentation/widgets/app_tab_shell.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../../notifications/data/notifications_api.dart';
import '../../logic/library_actions.dart';
import '../widgets/library_dialogs.dart';
import '../widgets/library_document_card.dart';
import '../widgets/library_reader_dialog.dart';
import '../widgets/library_shelves_section.dart';

/// Native Eduma Library view matching `LibraryDesktopView` + `LibraryTab`
/// in `../eduma` (`/libraryTab` & `/library`).
class LibraryPage extends StatefulComponent {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _pageLimit = 24;
  static const _searchDelay = Duration(milliseconds: 350);

  EdumaSession? _session = AuthActions.currentSession;
  bool _loadingSession = AuthActions.currentSession == null;
  String? _sessionError;
  int _unreadNotifications = 0;

  List<LibraryDocument> _documents = const [];
  List<LibraryDocument> _recents = const [];
  List<LibraryGroup> _groups = const [];
  List<LibraryCollection> _collections = const [];
  List<String> _knownCategories = const [];

  String _query = '';
  String _selectedCategory = '';
  String _selectedShelf = '';
  LibraryShowFilter _showFilter = .everything;
  LibrarySort _sort = .popular;
  LibraryCardStyle _cardStyle = .tall;

  int _page = 1;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String? _notice;

  bool _newGroupOpen = false;
  LibraryDocument? _readingDoc;
  Timer? _debounce;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    final session = _session;
    if (session != null) {
      EdumaMemoryCache.instance.ensureUser(session.userId);
      final cached = EdumaMemoryCache.instance.library;
      if (cached != null) {
        _documents = cached.documents;
        _knownCategories = cached.categories;
        _hasMore = cached.hasMore;
        _recents = cached.recents;
        _groups = cached.groups;
        _collections = cached.collections;
      }
      _unreadNotifications = EdumaMemoryCache.instance.unreadNotifications ?? 0;
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final hasCached = _documents.isNotEmpty;
    setState(() {
      _loadingSession = _session == null;
      _loading = !hasCached;
      _sessionError = null;
      _error = null;
    });

    try {
      final session = await AuthActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _session = null;
          _documents = const [];
          _recents = const [];
          _groups = const [];
          _collections = const [];
        });
        return;
      }
      EdumaMemoryCache.instance.ensureUser(session.userId);
      setState(() => _session = session);
      await Future.wait([
        _loadCatalog(resetPage: true),
        _loadRecents(),
        _loadShelves(),
        _loadUnread(),
      ]);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _sessionError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sessionError = 'Could not load your session.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loading = false;
        });
      }
    }
  }

  void _syncLibraryCache() {
    if (_selectedCategory.isNotEmpty ||
        _selectedShelf.isNotEmpty ||
        _query.trim().isNotEmpty ||
        _showFilter != .everything) {
      return;
    }
    EdumaMemoryCache.instance.library = LibraryCacheData(
      documents: _documents,
      categories: _knownCategories,
      hasMore: _hasMore,
      recents: _recents,
      groups: _groups,
      collections: _collections,
    );
  }

  Future<void> _loadUnread() async {
    final unread = await NotificationsApi.instance.loadUnreadCount();
    if (!mounted) return;
    EdumaMemoryCache.instance.unreadNotifications = unread;
    setState(() => _unreadNotifications = unread);
  }

  Future<void> _loadRecents() async {
    final recents = await LibraryActions.loadRecents();
    if (!mounted) return;
    setState(() => _recents = recents);
    _syncLibraryCache();
  }

  Future<void> _loadShelves() async {
    final results = await Future.wait([
      LibraryActions.loadGroups(),
      LibraryActions.loadCollections(),
    ]);
    if (!mounted) return;
    setState(() {
      _groups = results[0] as List<LibraryGroup>;
      _collections = results[1] as List<LibraryCollection>;
    });
    _syncLibraryCache();
  }

  Future<void> _loadCatalog({required bool resetPage}) async {
    final nextPage = resetPage ? 1 : _page + 1;
    final token = ++_generation;
    final hasCachedDefault =
        resetPage &&
        _documents.isNotEmpty &&
        _query.trim().isEmpty &&
        _selectedCategory.isEmpty &&
        _selectedShelf.isEmpty;
    setState(() {
      if (resetPage) {
        _loading = !hasCachedDefault;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final result = await LibraryActions.loadDocuments(
        query: _query,
        category: _selectedCategory,
        shelf: _selectedShelf,
        sort: _sort,
        page: nextPage,
        limit: _pageLimit,
      );
      if (!mounted || token != _generation) return;
      final merged = resetPage ? result.documents : [..._documents, ...result.documents];
      setState(() {
        _documents = merged;
        _page = nextPage;
        _hasMore = result.hasMore;
        if (_selectedCategory.isEmpty && _selectedShelf.isEmpty && _query.trim().isEmpty) {
          _knownCategories = LibraryCatalogLogic.categoriesFrom(merged);
        }
      });
      _syncLibraryCache();
    } on AuthApiException catch (error) {
      if (!mounted || token != _generation) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted || token != _generation) return;
      setState(() => _error = 'Could not load library documents right now.');
    } finally {
      if (mounted && token == _generation) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(_searchDelay, () => unawaited(_loadCatalog(resetPage: true)));
  }

  void _selectCategory(String category) {
    setState(() {
      _showFilter = .everything;
      _selectedShelf = '';
      _selectedCategory = category;
    });
    unawaited(_loadCatalog(resetPage: true));
  }

  void _selectShow(LibraryShowFilter filter) {
    setState(() {
      _showFilter = filter;
      _selectedCategory = '';
      _selectedShelf = '';
    });
    unawaited(_loadCatalog(resetPage: true));
  }

  void _selectCollection(LibraryCollection col) {
    setState(() {
      _showFilter = .everything;
      _selectedCategory = '';
      _selectedShelf = col.shelf ?? col.id;
    });
    unawaited(_loadCatalog(resetPage: true));
  }

  void _recordOpen(LibraryDocument doc) {
    unawaited(LibraryActions.recordRecent(doc.id));
    setState(() {
      _readingDoc = doc;
      _recents = [doc, ..._recents.where((item) => item.id != doc.id)].take(12).toList();
    });
  }

  List<LibraryDocument> _visibleDocuments() {
    var list = _documents;
    if (_showFilter == .grouped && _groups.isNotEmpty) {
      final groupedIds = {for (final g in _groups) ...g.documentIds};
      list = list.where((doc) => groupedIds.contains(doc.id)).toList();
    } else if (_showFilter == .collections && _collections.isNotEmpty) {
      final shelves = {
        for (final c in _collections)
          if (c.shelf != null) c.shelf!.toLowerCase(),
      };
      list = list.where((doc) => doc.shelf != null && shelves.contains(doc.shelf!.toLowerCase())).toList();
    }
    if (_sort == .title) {
      return [...list]..sort((first, second) => first.title.compareTo(second.title));
    }
    return list;
  }

  List<LibraryDocument> _visibleRecents() {
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return _recents;
    return _recents
        .where(
          (doc) =>
              doc.title.toLowerCase().contains(term) ||
              doc.author.toLowerCase().contains(term) ||
              doc.category.toLowerCase().contains(term),
        )
        .toList();
  }

  @override
  Component build(BuildContext context) {
    final visibleRecents = _visibleRecents();
    final visibleDocs = _visibleDocuments();

    return appTabShell(
      session: _session,
      loadingSession: _loadingSession,
      sessionError: _sessionError,
      onRetrySession: () => unawaited(_load()),
      activeTab: .library,
      title: 'Library',
      subtitle: 'Explore vast collections of books',
      unreadNotifications: _unreadNotifications,
      showAgendaPanel: true,
      showQuickNoteFab: true,
      headerActions: [
        button(
          classes: 'eduma-circle-icon-btn',
          type: ButtonType.button,
          disabled: _loading,
          attributes: {'aria-label': 'Refresh library', 'title': 'Refresh'},
          onClick: () => unawaited(_load()),
          [edumaIcon(EdumaIcons.refresh, size: 19)],
        ),
        div(classes: 'eduma-library__header-search', [
          edumaIcon(EdumaIcons.search, size: 17),
          input<String>(
            type: InputType.search,
            value: _query,
            attributes: {'placeholder': 'Search documents'},
            onInput: _onQueryChanged,
          ),
          if (_query.isNotEmpty)
            button(
              classes: 'eduma-search-box__clear',
              type: ButtonType.button,
              attributes: {'aria-label': 'Clear search'},
              onClick: () => _onQueryChanged(''),
              [edumaIcon(EdumaIcons.closePlain, size: 15)],
            ),
        ]),
        button(
          classes: 'eduma-circle-icon-btn',
          type: ButtonType.button,
          attributes: {'aria-label': 'New group', 'title': 'New group'},
          onClick: () => setState(() => _newGroupOpen = true),
          [edumaIcon(EdumaIcons.folderAdd, size: 19)],
        ),
      ],
      body: [
        if (_notice case final info?) mainHomeNotice(info, isError: false),
        if (_error case final err?)
          mainHomeNotice(
            err,
            isError: true,
            onRetry: () => unawaited(_loadCatalog(resetPage: true)),
          ),
        if (visibleRecents.isNotEmpty)
          libraryRecentsStrip(
            recents: visibleRecents,
            cardStyle: _cardStyle,
            searching: _query.trim().isNotEmpty,
            onOpenDoc: _recordOpen,
            onSeeAll: () => setState(() {
              _query = '';
              _selectedCategory = '';
              _selectedShelf = '';
              _showFilter = .everything;
            }),
          ),
        libraryShelvesSection(
          groups: _groups,
          collections: _collections,
          query: _query,
          onNewGroup: () => setState(() => _newGroupOpen = true),
          onSelectGroup: (group) => setState(() {
            _showFilter = .grouped;
            _query = '';
            _selectedCategory = '';
            _notice = 'Showing books in “${group.name}”.';
          }),
          onSelectCollection: _selectCollection,
        ),
        div(classes: 'eduma-search-box eduma-library__mobile-search', [
          edumaIcon(EdumaIcons.search, size: 18),
          input<String>(
            type: InputType.search,
            value: _query,
            attributes: {'placeholder': 'Search documents'},
            onInput: _onQueryChanged,
          ),
          if (_query.isNotEmpty)
            button(
              classes: 'eduma-search-box__clear',
              type: ButtonType.button,
              attributes: {'aria-label': 'Clear search'},
              onClick: () => _onQueryChanged(''),
              [edumaIcon(EdumaIcons.closePlain, size: 16)],
            ),
        ]),
        section(classes: 'eduma-library__section', [
          div(classes: 'eduma-library__section-head', [
            h2([.text('Browse')]),
            if (_selectedShelf.isNotEmpty)
              button(
                classes: 'main-home__see-all-btn',
                type: ButtonType.button,
                onClick: () {
                  setState(() => _selectedShelf = '');
                  unawaited(_loadCatalog(resetPage: true));
                },
                [.text('Show all')],
              ),
          ]),
          libraryFilterRow(
            categories: _knownCategories,
            showFilter: _showFilter,
            selectedCategory: _selectedCategory,
            hasCollections: _collections.isNotEmpty,
            hasGroups: _groups.isNotEmpty,
            sort: _sort,
            cardStyle: _cardStyle,
            onSelectShow: _selectShow,
            onSelectCategory: _selectCategory,
            onSelectSort: (sort) {
              setState(() => _sort = sort);
              unawaited(_loadCatalog(resetPage: true));
            },
            onSelectCardStyle: (style) => setState(() => _cardStyle = style),
          ),
          if (visibleDocs.isEmpty && !_loading)
            appFeatureStateCard(
              icon: .book,
              title: _query.trim().isEmpty ? 'No documents available yet' : 'No matching documents',
              message: _query.trim().isEmpty
                  ? 'Resources added to your library catalog will appear here.'
                  : 'Try another title, author name, or course code.',
              actionLabel: _query.trim().isEmpty && _selectedCategory.isEmpty && _selectedShelf.isEmpty
                  ? null
                  : 'Reset filters',
              onAction: () {
                setState(() {
                  _query = '';
                  _selectedCategory = '';
                  _selectedShelf = '';
                  _showFilter = .everything;
                });
                unawaited(_loadCatalog(resetPage: true));
              },
            )
          else
            div(
              classes: _cardStyle == .wide ? 'eduma-library__grid is-wide' : 'eduma-library__grid',
              [
                for (final doc in visibleDocs)
                  libraryDocumentCard(
                    doc,
                    style: _cardStyle,
                    onOpen: () => _recordOpen(doc),
                  ),
              ],
            ),
        ]),
        if (_hasMore)
          div(classes: 'main-home__load-more', [
            button(
              classes: 'main-home__load-more-button',
              type: ButtonType.button,
              disabled: _loadingMore,
              onClick: () => unawaited(_loadCatalog(resetPage: false)),
              [
                edumaIcon(EdumaIcons.refresh, size: 16),
                .text(_loadingMore ? 'Loading…' : 'Load more resources'),
              ],
            ),
          ]),
      ],
      overlays: [
        LibraryNewGroupModal(
          open: _newGroupOpen,
          onClose: () => setState(() => _newGroupOpen = false),
          onCreated: (created) => setState(() {
            _groups = [created, ..._groups];
            _notice = 'Created group “${created.name}”.';
          }),
        ),
        libraryDocumentReaderModal(
          document: _readingDoc,
          onClose: () => setState(() => _readingDoc = null),
        ),
      ],
    );
  }
}
