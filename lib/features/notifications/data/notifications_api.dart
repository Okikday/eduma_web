import '../../auth/data/auth_api.dart';
import 'notifications_models.dart';

/// Client for `/notifications/*` and `/spaces/invites/{inviteId}/accept|decline`.
class NotificationsApi {
  NotificationsApi._();

  static final NotificationsApi instance = NotificationsApi._();

  final _auth = EdumaAuthApi.instance;

  Future<NotificationsPageResult> loadNotifications({
    NotificationFilterTab filter = .all,
    int page = 1,
    int limit = 25,
  }) async {
    final payload = await _auth.getAuthenticated(
      '/notifications',
      queryParameters: {
        'filter': filter.queryValue,
        if (filter == .unread) 'unreadOnly': 'true',
        'page': '$page',
        'limit': '$limit',
      },
    );
    return NotificationsFeedLogic.parsePage(payload, limit: limit);
  }

  Future<int> loadUnreadCount() async {
    try {
      final payload = await _auth.getAuthenticated('/notifications/unread-count');
      return NotificationsFeedLogic.unreadCountFromPayload(payload) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(String id) async {
    await _auth.patchAuthenticated('/notifications/${Uri.encodeComponent(id)}/read');
  }

  Future<void> markUnread(String id) async {
    await _auth.patchAuthenticated('/notifications/${Uri.encodeComponent(id)}/unread');
  }

  Future<void> markAllRead() async {
    await _auth.postAuthenticated('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _auth.deleteAuthenticated('/notifications/${Uri.encodeComponent(id)}');
  }

  Future<String?> acceptInvite(String inviteId) async {
    final payload = await _auth.postAuthenticated(
      '/spaces/invites/${Uri.encodeComponent(inviteId)}/accept',
    );
    final rawSpace = payload['space'];
    if (rawSpace is Map) {
      final id = '${rawSpace['_id'] ?? rawSpace['id'] ?? ''}'.trim();
      if (id.isNotEmpty) return id;
    }
    final spaceId = '${payload['spaceId'] ?? ''}'.trim();
    return spaceId.isEmpty ? null : spaceId;
  }

  Future<void> declineInvite(String inviteId) async {
    await _auth.postAuthenticated(
      '/spaces/invites/${Uri.encodeComponent(inviteId)}/decline',
    );
  }
}
