import '../../main/data/main_space.dart';

enum SpaceDetailRole {
  owner,
  admin,
  member;

  bool get isManager => this == owner || this == admin;

  String get label => switch (this) {
    owner => 'Owner',
    admin => 'Admin',
    member => 'Member',
  };

  static SpaceDetailRole fromApi(String? raw) => switch (raw?.toLowerCase()) {
    'owner' => owner,
    'admin' => admin,
    _ => member,
  };
}

class SpaceSettings {
  const SpaceSettings({
    this.membersCanEditDetails = false,
    this.membersCanAddPages = true,
    this.membersCanAddEvents = true,
    this.membersCanInvite = true,
  });

  static const defaults = SpaceSettings();

  final bool membersCanEditDetails;
  final bool membersCanAddPages;
  final bool membersCanAddEvents;
  final bool membersCanInvite;

  factory SpaceSettings.fromMap(Object? raw) {
    if (raw is! Map) return defaults;
    return SpaceSettings(
      membersCanEditDetails: raw['membersCanEditDetails'] == true,
      membersCanAddPages: raw['membersCanAddPages'] != false,
      membersCanAddEvents: raw['membersCanAddEvents'] != false,
      membersCanInvite: raw['membersCanInvite'] != false,
    );
  }
}

class SpaceDetailData {
  const SpaceDetailData({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.memberCount,
    required this.isPinned,
    required this.isPersonal,
    required this.isVerified,
    required this.inviteCode,
    required this.settings,
    required this.memberPreview,
    this.description,
    this.coverUrl,
    this.role,
    this.adminIds = const [],
    this.onlineMemberIds = const [],
    this.inviteCodeExpiresAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? coverUrl;
  final int memberCount;
  final bool isPinned;
  final bool isPersonal;
  final bool isVerified;
  final String inviteCode;
  final DateTime? inviteCodeExpiresAt;
  final SpaceSettings settings;
  final String? role;
  final List<String> adminIds;
  final List<String> onlineMemberIds;
  final List<MainSpaceMember> memberPreview;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SpaceDetailData.fromMap(Map<String, dynamic> data) {
    final id = '${data['_id'] ?? data['id'] ?? ''}'.trim();
    final title = '${data['title'] ?? ''}'.trim();
    if (id.isEmpty || title.isEmpty) {
      throw const MainApiException('Eduma returned a space without required details.');
    }

    final rawMembers = data['memberIds'];
    final membersList = rawMembers is List ? rawMembers : const <dynamic>[];
    final rawAdmins = data['admins'];
    final adminIds = <String>[
      if (rawAdmins is List)
        for (final entry in rawAdmins)
          if ('${entry is Map ? (entry['_id'] ?? entry['id'] ?? entry['userId'] ?? '') : entry}'.trim()
              case final adminId when adminId.isNotEmpty)
            adminId,
    ];
    final rawOnline = data['onlineMemberIds'];
    final onlineIds = <String>[
      if (rawOnline is List)
        for (final entry in rawOnline)
          if ('$entry'.trim().isNotEmpty) '$entry'.trim(),
    ];

    final rawCount = data['memberCount'];
    return SpaceDetailData(
      id: id,
      ownerId: '${data['ownerId'] ?? ''}'.trim(),
      title: title,
      description: _optionalText(data['description']),
      coverUrl: _safeImageUrl(data['coverUrl'] ?? data['coverImage'] ?? data['imageUrl']),
      memberCount: rawCount is num ? rawCount.toInt() : membersList.length,
      isPinned: data['isPinned'] == true,
      isPersonal: data['kind'] == 'personal',
      isVerified: _verifiedFlag(data),
      inviteCode: '${data['inviteCode'] ?? ''}'.trim(),
      inviteCodeExpiresAt: DateTime.tryParse(
        '${data['inviteCodeExpiresAt'] ?? data['inviteExpiresAt'] ?? ''}',
      ),
      settings: SpaceSettings.fromMap(data['settings']),
      role: _optionalText(data['role']),
      adminIds: adminIds,
      onlineMemberIds: onlineIds,
      memberPreview: [
        for (final member in membersList.take(4))
          if (member is Map)
            MainSpaceMember(
              id: _optionalText(member['_id'] ?? member['id']),
              name: _optionalText(member['name']),
              avatarUrl: _safeImageUrl(member['avatarUrl']),
            ),
      ],
      createdAt: DateTime.tryParse('${data['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${data['updatedAt'] ?? ''}'),
    );
  }

  SpaceDetailData copyWith({
    String? title,
    String? description,
    bool? isPinned,
    String? inviteCode,
    DateTime? inviteCodeExpiresAt,
    int? memberCount,
  }) => SpaceDetailData(
    id: id,
    ownerId: ownerId,
    title: title ?? this.title,
    description: description ?? this.description,
    coverUrl: coverUrl,
    memberCount: memberCount ?? this.memberCount,
    isPinned: isPinned ?? this.isPinned,
    isPersonal: isPersonal,
    isVerified: isVerified,
    inviteCode: inviteCode ?? this.inviteCode,
    inviteCodeExpiresAt: inviteCodeExpiresAt ?? this.inviteCodeExpiresAt,
    settings: settings,
    role: role,
    adminIds: adminIds,
    onlineMemberIds: onlineMemberIds,
    memberPreview: memberPreview,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

enum SpacePageType {
  dynamicCanvas,
  staticCanvas;

  bool get isDynamic => this == dynamicCanvas;

  String get label => isDynamic ? 'Canvas' : 'Notes';

  String get blurb =>
      isDynamic ? 'Free-form board for cards, sketches & links' : 'Sections of writing with checklists & embeds';

  String toApi() => isDynamic ? 'dynamicCanvas' : 'staticPage';

  static SpacePageType fromApi(Object? raw) {
    final lower = '${raw ?? ''}'.trim().toLowerCase();
    if (lower == 'staticpage' || lower == 'static' || lower == 'document' || lower == 'doc') {
      return staticCanvas;
    }
    return dynamicCanvas;
  }
}

class SpacePage {
  const SpacePage({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.pageType,
    required this.isArchived,
    this.description,
    this.coverImage,
    this.previewUrl,
    this.checklistDone = 0,
    this.checklistTotal = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String spaceId;
  final String title;
  final String? description;
  final SpacePageType pageType;
  final String? coverImage;
  final String? previewUrl;
  final bool isArchived;
  final int checklistDone;
  final int checklistTotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get visualPreview => previewUrl ?? coverImage;

  factory SpacePage.fromMap(Map<String, dynamic> map, {String fallbackSpaceId = ''}) {
    final id = '${map['_id'] ?? map['id'] ?? ''}'.trim();
    if (id.isEmpty) {
      throw const MainApiException('Eduma returned a page without an id.');
    }
    final checklist = map['checklist'];
    final done = checklist is Map ? (checklist['done'] as num?)?.toInt() ?? 0 : 0;
    final total = checklist is Map ? (checklist['total'] as num?)?.toInt() ?? 0 : 0;
    final archived = map['isArchived'] == true || map['archived'] == true || '${map['status']}' == 'archived';
    final rawTitle = '${map['title'] ?? ''}'.trim();
    final pageType = SpacePageType.fromApi(map['pageType']);
    return SpacePage(
      id: id,
      spaceId: _optionalText(map['spaceId']) ?? fallbackSpaceId,
      title: rawTitle.isEmpty ? (pageType.isDynamic ? 'Untitled canvas' : 'Untitled note') : rawTitle,
      description: _optionalText(map['description']),
      pageType: pageType,
      coverImage: _safeImageUrl(map['coverImage'] ?? map['coverUrl']),
      previewUrl: _safeImageUrl(map['previewUrl'] ?? map['thumbnailUrl']),
      isArchived: archived,
      checklistDone: done,
      checklistTotal: total,
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}'),
    );
  }

  SpacePage copyWith({String? title, String? description, bool? isArchived}) => SpacePage(
    id: id,
    spaceId: spaceId,
    title: title ?? this.title,
    description: description ?? this.description,
    pageType: pageType,
    coverImage: coverImage,
    previewUrl: previewUrl,
    isArchived: isArchived ?? this.isArchived,
    checklistDone: checklistDone,
    checklistTotal: checklistTotal,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class SpaceMember {
  const SpaceMember({
    required this.id,
    required this.name,
    required this.role,
    required this.isOnline,
    this.username,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final SpaceDetailRole role;
  final bool isOnline;
  final bool isVerified;

  factory SpaceMember.fromMap(Map<String, dynamic> map) => SpaceMember(
    id: '${map['_id'] ?? map['id'] ?? map['userId'] ?? ''}'.trim(),
    name: _optionalText(map['name']) ?? 'Member',
    username: _optionalText(map['username']),
    avatarUrl: _safeImageUrl(map['avatarUrl']),
    role: SpaceDetailRole.fromApi(map['role']?.toString()),
    isOnline: map['isOnline'] == true || map['online'] == true,
    isVerified: _verifiedFlag(map),
  );

  SpaceMember copyWith({SpaceDetailRole? role}) => SpaceMember(
    id: id,
    name: name,
    username: username,
    avatarUrl: avatarUrl,
    role: role ?? this.role,
    isOnline: isOnline,
    isVerified: isVerified,
  );
}

class SpacePermissionsLogic {
  const SpacePermissionsLogic({required this.space, required this.currentUserId});

  final SpaceDetailData? space;
  final String currentUserId;

  SpaceDetailRole get role {
    final current = space;
    if (current == null || currentUserId.isEmpty) return .member;
    if (current.ownerId == currentUserId) return .owner;
    final fromApi = SpaceDetailRole.fromApi(current.role);
    if (fromApi != .member) return fromApi;
    if (current.adminIds.contains(currentUserId)) return .admin;
    return .member;
  }

  bool get isOwner => role == .owner;
  bool get isManager => role.isManager;
  bool get isPersonal => space?.isPersonal ?? false;
  bool get canEditSpaceDetails => isManager || (space?.settings.membersCanEditDetails ?? false);
  bool get canAddPages => isManager || (space?.settings.membersCanAddPages ?? true);
  bool get canAddEvents => isManager || (space?.settings.membersCanAddEvents ?? true);
  bool get canManageMembers => isManager && !isPersonal;
  bool get canInvite => !isPersonal && (isManager || (space?.settings.membersCanInvite ?? true));
  bool get canRenewInvite => isManager && !isPersonal;
}

class SpaceAsset {
  const SpaceAsset({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.assetType,
    required this.size,
    required this.url,
    required this.createdAt,
    this.pageId,
    this.fileName,
    this.pageTitle,
  });

  final String id;
  final String spaceId;
  final String? pageId;
  final String title;
  final String? fileName;
  final String size;
  final String assetType;
  final String url;
  final String? pageTitle;
  final DateTime createdAt;

  String get displayName {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) return trimmedTitle;
    final raw = (fileName ?? '').trim();
    if (raw.isEmpty) return 'Untitled file';
    final dot = raw.lastIndexOf('.');
    return dot > 0 ? raw.substring(0, dot) : raw;
  }

  String get extension {
    final raw = (fileName ?? title).trim();
    final dot = raw.lastIndexOf('.');
    return dot >= 0 && dot + 1 < raw.length ? raw.substring(dot + 1) : '';
  }

  factory SpaceAsset.fromMap(Map<String, dynamic> map, {String fallbackSpaceId = ''}) => SpaceAsset(
    id: '${map['_id'] ?? map['id'] ?? ''}'.trim(),
    spaceId: _optionalText(map['spaceId']) ?? fallbackSpaceId,
    pageId: _optionalText(map['pageId']),
    title: '${map['title'] ?? ''}'.trim(),
    fileName: _optionalText(map['fileName'] ?? map['originalName']),
    size: '${map['size'] ?? ''}'.trim(),
    assetType: '${map['assetType'] ?? 'document'}'.trim(),
    url: '${map['url'] ?? ''}'.trim(),
    pageTitle: _optionalText(map['pageTitle']),
    createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}')?.toLocal() ?? DateTime.now(),
  );
}

class SpaceEvent {
  const SpaceEvent({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
  });

  final String id;
  final String spaceId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;

  factory SpaceEvent.fromMap(Map<String, dynamic> map, {String fallbackSpaceId = ''}) {
    final start = DateTime.tryParse('${map['startTime'] ?? map['start'] ?? ''}')?.toLocal() ?? DateTime.now();
    final parsedEnd = DateTime.tryParse('${map['endTime'] ?? map['end'] ?? ''}')?.toLocal();
    final end = parsedEnd != null && parsedEnd.isAfter(start)
        ? parsedEnd
        : start.add(const Duration(hours: 1));
    return SpaceEvent(
      id: '${map['_id'] ?? map['id'] ?? ''}'.trim(),
      spaceId: _optionalText(map['spaceId']) ?? fallbackSpaceId,
      title: _optionalText(map['title']) ?? 'Study Session',
      description: _optionalText(map['description']),
      location: _optionalText(map['location']),
      startTime: start,
      endTime: end,
    );
  }
}

abstract final class SpaceInviteExpiryLogic {
  static bool isExpired(DateTime? expiresAt, {DateTime? now}) =>
      expiresAt != null && !expiresAt.isAfter(now ?? DateTime.now());

  static String? label(DateTime? expiresAt, {DateTime? now}) {
    if (expiresAt == null) return null;
    final at = now ?? DateTime.now();
    if (isExpired(expiresAt, now: at)) return 'Expired';
    final local = expiresAt.toLocal();
    final today = DateTime(at.year, at.month, at.day);
    final day = DateTime(local.year, local.month, local.day);
    final days = day.difference(today).inDays;
    if (days <= 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires in $days days';
  }
}

enum SpacePageFilter {
  all('All'),
  canvas('Canvas'),
  notes('Notes'),
  archived('Archived');

  const SpacePageFilter(this.label);

  final String label;
}

abstract final class SpacePageQuery {
  static List<SpacePage> apply(
    List<SpacePage> pages, {
    required SpacePageFilter filter,
    String query = '',
  }) {
    final term = query.trim().toLowerCase();
    return [
      for (final page in pages)
        if (_matches(page, filter, term)) page,
    ];
  }

  static bool _matches(SpacePage page, SpacePageFilter filter, String term) {
    final matchesFilter = switch (filter) {
      .archived => page.isArchived,
      .canvas => !page.isArchived && page.pageType == .dynamicCanvas,
      .notes => !page.isArchived && page.pageType == .staticCanvas,
      .all => !page.isArchived,
    };
    if (!matchesFilter) return false;
    if (term.isEmpty) return true;
    return page.title.toLowerCase().contains(term) || (page.description?.toLowerCase().contains(term) ?? false);
  }
}

bool _verifiedFlag(Map<String, dynamic> data) {
  final flag = data['isVerified'] ?? data['verified'];
  if (flag is bool) return flag;
  if (flag is String) return flag == 'true';
  return data['verification'] is Map && '${(data['verification'] as Map)['status']}' == 'verified';
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String? _safeImageUrl(Object? value) {
  final text = _optionalText(value);
  if (text == null) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri.toString();
}
