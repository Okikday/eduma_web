import '../../auth/data/auth_api.dart';
import 'library_models.dart';

/// Client for `/library/documents`, `/library/recents`, `/library/groups`, and `/library/collections`.
class LibraryApi {
  LibraryApi._();

  static final LibraryApi instance = LibraryApi._();

  final _auth = EdumaAuthApi.instance;

  Future<LibraryDocumentsPageResult> loadDocuments({
    String query = '',
    String category = '',
    String shelf = '',
    LibrarySort sort = .popular,
    int page = 1,
    int limit = 24,
  }) async {
    final cleanQuery = query.trim();
    final cleanCategory = category.trim();
    final cleanShelf = shelf.trim();
    final payload = await _auth.getAuthenticated(
      '/library/documents',
      queryParameters: {
        if (cleanQuery.isNotEmpty) ...{
          'query': cleanQuery,
          'search': cleanQuery,
          'q': cleanQuery,
        },
        if (cleanCategory.isNotEmpty) 'category': cleanCategory,
        if (cleanShelf.isNotEmpty) 'shelf': cleanShelf,
        'sort': sort.name,
        'page': '$page',
        'limit': '$limit',
      },
    );
    return LibraryCatalogLogic.parseDocumentsPage(payload, limit: limit);
  }

  Future<List<LibraryDocument>> loadRecents() async {
    try {
      final payload = await _auth.getAuthenticated('/library/recents');
      return LibraryCatalogLogic.parseDocumentsPage(payload, limit: 20).documents;
    } catch (_) {
      return const [];
    }
  }

  Future<List<LibraryGroup>> loadGroups() async {
    try {
      final payload = await _auth.getAuthenticated('/library/groups');
      return LibraryCatalogLogic.parseGroups(payload);
    } catch (_) {
      return const [];
    }
  }

  Future<List<LibraryCollection>> loadCollections() async {
    try {
      final payload = await _auth.getAuthenticated('/library/collections');
      return LibraryCatalogLogic.parseCollections(payload);
    } catch (_) {
      return const [];
    }
  }

  Future<LibraryGroup?> saveGroup({
    required String id,
    required String name,
    LibraryGroupTint tint = .brand,
    List<String> documentIds = const [],
  }) async {
    final payload = await _auth.requestAuthenticated(
      'PUT',
      '/library/groups/${Uri.encodeComponent(id)}',
      body: {
        'id': id,
        'name': name.trim(),
        if (tint != .brand) 'tint': tint.name,
        'documentIds': documentIds,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    final raw = payload['group'] ?? payload['data'] ?? payload;
    if (raw is Map<String, dynamic>) {
      return LibraryGroup.fromMap(raw);
    }
    if (raw is Map) {
      return LibraryGroup.fromMap(Map<String, dynamic>.from(raw));
    }
    return LibraryGroup(id: id, name: name.trim(), tint: tint, documentIds: documentIds);
  }

  Future<void> recordRecent(String documentId) async {
    if (documentId.trim().isEmpty) return;
    try {
      await _auth.postAuthenticated(
        '/library/recents/${Uri.encodeComponent(documentId)}',
      );
    } catch (_) {
      // Quietly best-effort when recents sync is unavailable.
    }
  }
}
