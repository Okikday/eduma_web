import '../data/library_api.dart';
import '../data/library_models.dart';

export '../data/library_models.dart';

abstract final class LibraryActions {
  static final _api = LibraryApi.instance;

  static Future<LibraryDocumentsPageResult> loadDocuments({
    String query = '',
    String category = '',
    String shelf = '',
    LibrarySort sort = .popular,
    int page = 1,
    int limit = 24,
  }) => _api.loadDocuments(
    query: query,
    category: category,
    shelf: shelf,
    sort: sort,
    page: page,
    limit: limit,
  );

  static Future<List<LibraryDocument>> loadRecents() => _api.loadRecents();

  static Future<List<LibraryGroup>> loadGroups() => _api.loadGroups();

  static Future<List<LibraryCollection>> loadCollections() => _api.loadCollections();

  static Future<LibraryGroup?> saveGroup({
    required String id,
    required String name,
    LibraryGroupTint tint = .brand,
    List<String> documentIds = const [],
  }) => _api.saveGroup(id: id, name: name, tint: tint, documentIds: documentIds);

  static Future<void> recordRecent(String documentId) => _api.recordRecent(documentId);
}
