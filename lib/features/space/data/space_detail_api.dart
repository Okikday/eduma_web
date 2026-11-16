import '../../auth/data/auth_api.dart';
import '../../main/data/main_space.dart';
import 'space_detail_models.dart';
import 'space_page_content_models.dart';

class SpaceDetailBundle {
  const SpaceDetailBundle({
    required this.session,
    required this.space,
    required this.pages,
    required this.members,
    this.assets = const [],
    this.events = const [],
  });

  final EdumaSession session;
  final SpaceDetailData space;
  final List<SpacePage> pages;
  final List<SpaceMember> members;
  final List<SpaceAsset> assets;
  final List<SpaceEvent> events;
}

class SpaceDetailApi {
  SpaceDetailApi._();

  static final instance = SpaceDetailApi._();
  final EdumaAuthApi _authApi = EdumaAuthApi.instance;

  Future<SpaceDetailBundle> loadSpace(EdumaSession session, String spaceId) async {
    final encodedId = Uri.encodeComponent(spaceId);
    final spaceFuture = _authApi.getAuthenticated('/spaces/$encodedId');
    final pagesFuture = _authApi.getAuthenticated(
      '/spaces/$encodedId/pages',
      queryParameters: {'includeArchived': 'true'},
    );
    final membersFuture = _loadMembersSafe(encodedId);
    final assetsFuture = _loadAssetsSafe(encodedId, spaceId);
    final eventsFuture = _loadEventsSafe(spaceId);

    final spacePayload = await spaceFuture;
    final pagesPayload = await pagesFuture;
    final members = await membersFuture;
    final assets = await assetsFuture;
    final events = await eventsFuture;

    final rawSpace = spacePayload['space'] ?? spacePayload['data'] ?? spacePayload;
    if (rawSpace is! Map) {
      throw const MainApiException('Eduma returned an unexpected space response.');
    }
    final space = SpaceDetailData.fromMap(Map<String, dynamic>.from(rawSpace));

    Object? rawPages = pagesPayload['data'] ?? pagesPayload['pages'] ?? pagesPayload['items'];
    if (rawPages is Map) {
      rawPages = rawPages['pages'] ?? rawPages['items'] ?? rawPages['data'];
    }
    if (rawPages is! List) {
      throw const MainApiException('Eduma returned an unexpected pages response.');
    }
    final pages = [
      for (final item in rawPages)
        if (item is Map)
          SpacePage.fromMap(
            Map<String, dynamic>.from(item),
            fallbackSpaceId: space.id,
          ),
    ];

    return SpaceDetailBundle(
      session: session,
      space: space,
      pages: pages,
      members: members,
      assets: assets,
      events: events,
    );
  }

  Future<SpaceDetailData> loadSpaceSummary(String spaceId) async {
    final payload = await _authApi.getAuthenticated(
      '/spaces/${Uri.encodeComponent(spaceId)}',
    );
    final raw = payload['space'] ?? payload['data'] ?? payload;
    if (raw is! Map) {
      throw const MainApiException('Eduma returned an unexpected space response.');
    }
    return SpaceDetailData.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<List<SpaceAsset>> _loadAssetsSafe(String encodedSpaceId, String spaceId) async {
    try {
      final payload = await _authApi.getAuthenticated('/spaces/$encodedSpaceId/pages/assets');
      Object? raw = payload['data'] ?? payload['assets'] ?? payload['items'];
      if (raw is Map) {
        raw = raw['assets'] ?? raw['items'] ?? raw['data'];
      }
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map) SpaceAsset.fromMap(Map<String, dynamic>.from(item), fallbackSpaceId: spaceId),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<SpaceEvent>> _loadEventsSafe(String spaceId) async {
    try {
      final payload = await _authApi.getAuthenticated(
        '/events',
        queryParameters: {'spaceId': spaceId},
      );
      Object? raw = payload['data'] ?? payload['events'] ?? payload['items'];
      if (raw is Map) {
        raw = raw['events'] ?? raw['items'] ?? raw['data'];
      }
      if (raw is! List) return const [];
      final events = [
        for (final item in raw)
          if (item is Map) SpaceEvent.fromMap(Map<String, dynamic>.from(item), fallbackSpaceId: spaceId),
      ];
      return events.where((e) => e.spaceId == spaceId).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (_) {
      return const [];
    }
  }

  Future<List<SpaceMember>> _loadMembersSafe(String encodedSpaceId) async {
    try {
      final payload = await _authApi.getAuthenticated('/spaces/$encodedSpaceId/members');
      Object? raw = payload['data'] ?? payload['members'] ?? payload['items'];
      if (raw is Map) {
        raw = raw['members'] ?? raw['items'] ?? raw['data'];
      }
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map) SpaceMember.fromMap(Map<String, dynamic>.from(item)),
      ];
    } on AuthApiException {
      return const [];
    }
  }

  Future<SpaceDetailData> updateSpace(
    String spaceId, {
    required String title,
    String? description,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const MainApiException('Enter a title for this space.');
    }
    final payload = await _authApi.patchAuthenticated(
      '/spaces/${Uri.encodeComponent(spaceId)}',
      body: {
        'title': trimmed,
        if (description != null) 'description': description.trim(),
      },
    );
    final raw = payload['space'] ?? payload['data'] ?? payload;
    if (raw is! Map) {
      throw const MainApiException('Eduma returned an unexpected updated space response.');
    }
    return SpaceDetailData.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<({String inviteCode, DateTime? expiresAt})> renewInviteCode(String spaceId) async {
    final payload = await _authApi.postAuthenticated(
      '/spaces/${Uri.encodeComponent(spaceId)}/invite-code',
    );
    final raw = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : payload;
    final code = '${raw['inviteCode'] ?? ''}'.trim();
    if (code.isEmpty) {
      throw const MainApiException('Could not generate an invite code for this space.');
    }
    final expiresAt = DateTime.tryParse(
      '${raw['inviteCodeExpiresAt'] ?? raw['inviteExpiresAt'] ?? ''}',
    );
    return (inviteCode: code, expiresAt: expiresAt);
  }

  Future<SpacePage> createPage(
    String spaceId, {
    required String title,
    String? description,
    required SpacePageType pageType,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const MainApiException('Enter a title for this page.');
    }
    final desc = description?.trim() ?? '';
    final payload = await _authApi.postAuthenticated(
      '/spaces/${Uri.encodeComponent(spaceId)}/pages',
      body: {
        'title': trimmed,
        if (desc.isNotEmpty) 'description': desc,
        'pageType': pageType.toApi(),
      },
    );
    final raw = payload['page'] ?? payload['data'] ?? payload;
    if (raw is! Map) {
      throw const MainApiException('Eduma returned an unexpected create page response.');
    }
    return SpacePage.fromMap(
      Map<String, dynamic>.from(raw),
      fallbackSpaceId: spaceId,
    );
  }

  Future<SpacePage> updatePage(
    String spaceId,
    String pageId, {
    String? title,
    String? description,
    bool? isArchived,
  }) async {
    final payload = await _authApi.patchAuthenticated(
      '/spaces/${Uri.encodeComponent(spaceId)}/pages/${Uri.encodeComponent(pageId)}',
      body: {
        if (title != null) 'title': title.trim(),
        if (description != null) 'description': description.trim(),
        if (isArchived != null) 'isArchived': isArchived,
        if (isArchived != null) 'archived': isArchived,
      },
    );
    final raw = payload['page'] ?? payload['data'] ?? payload;
    if (raw is! Map) {
      throw const MainApiException('Eduma returned an unexpected page update response.');
    }
    return SpacePage.fromMap(
      Map<String, dynamic>.from(raw),
      fallbackSpaceId: spaceId,
    );
  }

  Future<void> deletePage(String spaceId, String pageId) => _authApi.deleteAuthenticated(
    '/spaces/${Uri.encodeComponent(spaceId)}/pages/${Uri.encodeComponent(pageId)}',
  );

  Future<void> leaveOrDeleteSpace(
    String spaceId, {
    required String userId,
    required bool deleteSpace,
    required bool deleteMedia,
  }) async {
    final encodedSpaceId = Uri.encodeComponent(spaceId);
    if (deleteSpace) {
      await _authApi.deleteAuthenticated(
        '/spaces/$encodedSpaceId',
        queryParameters: {'deleteMedia': '$deleteMedia'},
      );
      return;
    }
    if (userId.trim().isEmpty) {
      throw const MainApiException('Your session expired. Please sign in again.');
    }
    await _authApi.deleteAuthenticated(
      '/spaces/$encodedSpaceId/members/${Uri.encodeComponent(userId)}',
      queryParameters: {'deleteMyUploads': '$deleteMedia'},
    );
  }

  Future<void> reportSpace({
    required String spaceId,
    required String reason,
    String? details,
  }) async {
    final trimmedDetails = details?.trim() ?? '';
    await _authApi.postAuthenticated(
      '/reports',
      body: {
        'targetType': 'space',
        'targetId': spaceId,
        'reason': reason,
        if (trimmedDetails.isNotEmpty) 'details': trimmedDetails,
      },
    );
  }

  Future<void> removeMember(String spaceId, String userId) => _authApi.deleteAuthenticated(
    '/spaces/${Uri.encodeComponent(spaceId)}/members/${Uri.encodeComponent(userId)}',
  );

  Future<void> setAdmin(String spaceId, String userId, {required bool promote}) {
    final path = '/spaces/${Uri.encodeComponent(spaceId)}/admins/${Uri.encodeComponent(userId)}';
    return promote ? _authApi.postAuthenticated(path) : _authApi.deleteAuthenticated(path);
  }

  Future<FullSpacePageData> loadFullPage(String spaceId, String pageId) async {
    final encodedSpace = Uri.encodeComponent(spaceId);
    final encodedPage = Uri.encodeComponent(pageId);
    final payload = await _authApi.getAuthenticated('/spaces/$encodedSpace/pages/$encodedPage');
    final raw = payload['page'] ?? payload['data'] ?? payload;
    if (raw is! Map) {
      throw const MainApiException('Eduma returned an unexpected page response.');
    }
    return FullSpacePageData.fromMap(
      Map<String, dynamic>.from(raw),
      fallbackSpaceId: spaceId,
    );
  }

  Future<void> markPageOpened(String spaceId, String pageId) async {
    try {
      await _authApi.postAuthenticated(
        '/spaces/${Uri.encodeComponent(spaceId)}/pages/${Uri.encodeComponent(pageId)}/opened',
      );
    } catch (_) {}
  }

  Future<void> savePageContent(
    String spaceId,
    String pageId, {
    List<Map<String, dynamic>>? sections,
    List<Map<String, dynamic>>? elements,
    int? baseVersion,
  }) => _authApi.requestAuthenticated(
    'PUT',
    '/spaces/${Uri.encodeComponent(spaceId)}/pages/${Uri.encodeComponent(pageId)}/content',
    body: {
      if (sections != null) 'sections': sections,
      if (elements != null) 'elements': elements,
      if (baseVersion != null) 'baseVersion': baseVersion,
    },
  );
}
