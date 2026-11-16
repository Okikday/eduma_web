import '../../auth/data/auth_api.dart';
import 'ai_history_models.dart';

class AiHistoryApi {
  AiHistoryApi._();

  static final instance = AiHistoryApi._();
  final EdumaAuthApi _authApi = EdumaAuthApi.instance;

  Future<List<AiHistoryEntry>> listHistory({int limit = 50}) async {
    final payload = await _authApi.getAuthenticated(
      '/ai/history',
      queryParameters: {'limit': '$limit'},
    );
    Object? rawList =
        payload['items'] ??
        payload['history'] ??
        payload['conversations'] ??
        payload['data'];
    if (rawList is Map) {
      rawList =
          rawList['items'] ??
          rawList['history'] ??
          rawList['conversations'] ??
          rawList['data'];
    }
    if (rawList is! List) return const [];
    final items = [
      for (final item in rawList)
        if (AiHistoryEntry.tryParse(item) case final parsed?) parsed,
    ];
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<AiHistoryEntry?> getConversation(String id) async {
    final payload = await _authApi.getAuthenticated(
      '/ai/history/${Uri.encodeComponent(id)}',
    );
    return AiHistoryEntry.tryParse(payload['item'] ?? payload['data'] ?? payload);
  }

  Future<void> deleteConversation(String id) => _authApi.deleteAuthenticated(
    '/ai/history/${Uri.encodeComponent(id)}',
  );
}
