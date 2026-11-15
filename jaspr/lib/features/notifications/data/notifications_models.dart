import '../../../core/data/json_envelope.dart';

/// Filter tabs matching Inbox filter chips.
enum NotificationFilterTab {
  all('All', 'all'),
  unread('Unread', 'unread'),
  invites('Invites', 'invites'),
  schedule('Schedule', 'schedule');

  const NotificationFilterTab(this.label, this.queryValue);

  final String label;
  final String queryValue;

  bool matches(EdumaNotification item) => switch (this) {
    .all => true,
    .unread => !item.isRead,
    .invites =>
      item.kind == .invite ||
      item.kind == .joinRequest ||
      item.kind == .joinApproved ||
      item.kind == .joinDeclined,
    .schedule => item.kind == .schedule,
  };
}

/// All notification categories supported by Eduma.
enum EdumaNotificationKind {
  invite('INVITATION', 'invite'),
  schedule('SCHEDULE', 'schedule'),
  milestone('MILESTONE', 'milestone'),
  streak('STREAK', 'streak'),
  mention('MENTION', 'mention'),
  space('SPACE', 'space'),
  joinRequest('JOIN REQUEST', 'join-request'),
  joinApproved('APPROVED', 'join-approved'),
  joinDeclined('DECLINED', 'join-declined'),
  whatsapp('WHATSAPP', 'whatsapp'),
  system('UPDATE', 'system');

  const EdumaNotificationKind(this.label, this.cssModifier);

  final String label;
  final String cssModifier;

  static EdumaNotificationKind fromRaw(String rawType, {Map<String, dynamic> data = const {}, String title = ''}) {
    final normalized = rawType.toLowerCase().replaceAll(RegExp('[_-]'), '');
    if (const {'comment', 'reply', 'commentreply', 'mentionall'}.contains(normalized)) {
      return .mention;
    }
    if (normalized.contains('whatsapp') ||
        '${data['source'] ?? ''}'.toLowerCase().contains('whatsapp') ||
        title.toLowerCase().startsWith('whatsapp')) {
      return .whatsapp;
    }
    if (normalized.contains('invite')) return .invite;
    return switch (normalized) {
      'schedule' => .schedule,
      'milestone' => .milestone,
      'streak' => .streak,
      'mention' => .mention,
      'space' => .space,
      'joinrequest' => .joinRequest,
      'joinapproved' => .joinApproved,
      'joindeclined' => .joinDeclined,
      _ => .system,
    };
  }
}

/// Notification item returned by `/notifications`.
class EdumaNotification {
  const EdumaNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  EdumaNotificationKind get kind =>
      EdumaNotificationKind.fromRaw(type, data: data, title: title);

  bool get isInvite => kind == .invite;

  String? get spaceId => _stringValue(data['spaceId']);

  String? get inviteId => _stringValue(data['inviteId']);

  String? get inviteCode => _stringValue(data['inviteCode'] ?? data['code']);

  String? get inviteStatus => _stringValue(data['inviteStatus'])?.toLowerCase();

  String? get requestStatus => _stringValue(data['requestStatus'])?.toLowerCase();

  bool get canAcceptInvite =>
      isInvite && inviteStatus != 'accepted' && inviteStatus != 'requested' && (inviteId != null || inviteCode != null);

  EdumaNotification copyWith({bool? isRead}) => EdumaNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    data: data,
  );

  factory EdumaNotification.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    return EdumaNotification(
      id: '${map['_id'] ?? map['id'] ?? ''}'.trim(),
      type: '${map['type'] ?? 'general'}'.trim(),
      title: '${map['title'] ?? 'Notification'}'.trim(),
      body: '${map['body'] ?? map['message'] ?? ''}'.trim(),
      isRead: map['isRead'] == true || map['read'] == true,
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}')?.toLocal(),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
    );
  }

  static String? _stringValue(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class NotificationsPageResult {
  const NotificationsPageResult({
    required this.items,
    required this.hasMore,
    this.unreadCount,
  });

  final List<EdumaNotification> items;
  final bool hasMore;
  final int? unreadCount;
}

abstract final class NotificationsFeedLogic {
  static NotificationsPageResult parsePage(
    Map<String, dynamic> payload, {
    required int limit,
  }) {
    final list = extractResponseList(
      payload,
      const ['notifications', 'items', 'data'],
    );
    final items = [
      for (final map in list)
        if ('${map['_id'] ?? map['id'] ?? ''}'.trim().isNotEmpty) EdumaNotification.fromMap(map),
    ];

    final pagination = payload['pagination'];
    bool hasMore = items.length >= limit;
    if (pagination is Map) {
      if (pagination['hasMore'] is bool) {
        hasMore = pagination['hasMore'] as bool;
      } else if (pagination['totalPages'] is num && pagination['page'] is num) {
        hasMore = (pagination['page'] as num) < (pagination['totalPages'] as num);
      }
    }

    return NotificationsPageResult(
      items: items,
      hasMore: hasMore,
      unreadCount: unreadCountFromPayload(payload),
    );
  }

  static int? unreadCountFromPayload(Map<String, dynamic> payload) {
    final raw = payload['unreadCount'] ?? payload['count'] ?? payload['totalUnread'];
    if (raw is num) return raw.toInt();
    return int.tryParse('${raw ?? ''}');
  }
}
