import 'main_space.dart';

/// Preview payload returned by `GET /spaces/invite/{code}`.
class MainSpacePreview {
  const MainSpacePreview({
    required this.title,
    required this.badgeLabel,
    required this.memberCount,
    required this.ownerName,
    required this.alreadyMember,
    this.spaceId,
    this.description,
    this.isVerified = false,
    this.coverUrl,
  });

  final String? spaceId;
  final String title;
  final String? description;
  final String badgeLabel;
  final int memberCount;
  final String ownerName;
  final bool alreadyMember;
  final bool isVerified;
  final String? coverUrl;

  factory MainSpacePreview.fromMap(Map<String, dynamic> map) {
    final spaceId = '${map['spaceId'] ?? map['_id'] ?? map['id'] ?? ''}'.trim();
    final title = '${map['title'] ?? ''}'.trim();
    if (title.isEmpty) {
      throw const MainApiException(
        'Eduma returned a space preview without a title.',
      );
    }
    return MainSpacePreview(
      spaceId: spaceId.isEmpty ? null : spaceId,
      title: title,
      description: _optional(map['description']),
      badgeLabel: _optional(map['badgeLabel']) ?? 'meeting',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      ownerName: '${map['ownerName'] ?? ''}'.trim(),
      alreadyMember: map['alreadyMember'] == true,
      isVerified: _verified(map),
      coverUrl: _safeUrl(map['coverUrl'] ?? map['coverImage'] ?? map['cover']),
    );
  }
}

/// Outcome returned by `POST /spaces/join`.
class MainSpaceJoinResult {
  const MainSpaceJoinResult({
    this.spaceId,
    this.pending = false,
    this.requestId,
    this.space,
  });

  final String? spaceId;
  final bool pending;
  final String? requestId;
  final MainSpace? space;

  factory MainSpaceJoinResult.fromMap(
    Map<String, dynamic> map, {
    String currentUserId = '',
  }) {
    final rawSpace = map['space'];
    final parsedSpace = rawSpace is Map
        ? tryParseMainSpace(
            Map<String, dynamic>.from(rawSpace),
            currentUserId: currentUserId,
          )
        : null;
    final id = '${map['spaceId'] ?? parsedSpace?.id ?? ''}'.trim();
    final status = '${map['status'] ?? ''}'.trim().toLowerCase();
    final request = map['request'];
    final reqId = '${map['requestId'] ?? (request is Map ? (request['_id'] ?? request['id'] ?? '') : '')}'.trim();
    return MainSpaceJoinResult(
      spaceId: id.isEmpty ? null : id,
      pending: status == 'pending' || map['pending'] == true,
      requestId: reqId.isEmpty ? null : reqId,
      space: parsedSpace,
    );
  }
}

MainSpace? tryParseMainSpace(
  Map<String, dynamic> map, {
  String currentUserId = '',
}) {
  try {
    return MainSpace.fromMap(map, currentUserId: currentUserId);
  } on MainApiException {
    return null;
  }
}

String? _optional(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _verified(Map<String, dynamic> map) {
  final flag = map['isVerified'] ?? map['verified'];
  if (flag is bool) return flag;
  if (flag is String) return flag == 'true';
  final verification = map['verification'];
  return verification is Map && '${verification['status']}' == 'verified';
}

String? _safeUrl(Object? raw) {
  final text = _optional(raw);
  if (text == null) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri.toString();
}
