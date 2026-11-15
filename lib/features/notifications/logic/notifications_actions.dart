import '../data/notifications_api.dart';
import '../data/notifications_models.dart';

export '../data/notifications_models.dart';

abstract final class NotificationsActions {
  static final _api = NotificationsApi.instance;

  static Future<NotificationsPageResult> loadNotifications({
    NotificationFilterTab filter = .all,
    int page = 1,
    int limit = 25,
  }) => _api.loadNotifications(filter: filter, page: page, limit: limit);

  static Future<int> loadUnreadCount() => _api.loadUnreadCount();

  static Future<void> markRead(String id) => _api.markRead(id);

  static Future<void> markUnread(String id) => _api.markUnread(id);

  static Future<void> markAllRead() => _api.markAllRead();

  static Future<void> deleteNotification(String id) => _api.deleteNotification(id);

  static Future<String?> acceptInvite(String inviteId) => _api.acceptInvite(inviteId);

  static Future<void> declineInvite(String inviteId) => _api.declineInvite(inviteId);
}
