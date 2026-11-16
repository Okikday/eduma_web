import '../../auth/data/auth_api.dart';
import '../logic/space_invite_link.dart';
import 'main_canvas.dart';
import 'main_space.dart';
import 'main_space_mutations.dart';

class MainPinLimitException implements Exception {
  const MainPinLimitException();

  String get message => 'You can pin up to ${SpaceInviteLink.maxPinnedSpaces} spaces.';

  @override
  String toString() => message;
}

class MainSpacesPage {
  const MainSpacesPage({required this.spaces, required this.hasMore});

  final List<MainSpace> spaces;
  final bool hasMore;
}

class MainHomeData {
  const MainHomeData({
    required this.session,
    required this.spaces,
    required this.pinnedSpaces,
    required this.recentCanvases,
    required this.recentCanvasesError,
    required this.hasMore,
  });

  final EdumaSession session;
  final List<MainSpace> spaces;
  final List<MainSpace> pinnedSpaces;
  final List<MainCanvas> recentCanvases;
  final String? recentCanvasesError;
  final bool hasMore;
}

class MainApi {
  MainApi._();

  static final instance = MainApi._();
  static const pageSize = 20;

  final EdumaAuthApi _authApi = EdumaAuthApi.instance;

  Future<MainHomeData> loadHome(EdumaSession session) async {
    final spacesFuture = Future.wait([
      _loadSpaces(page: 1, currentUserId: session.userId),
      _loadSpaces(
        page: 1,
        pinned: true,
        currentUserId: session.userId,
      ),
    ]);
    final canvasesFuture = _loadRecentCanvases();
    await Future.wait<void>([
      spacesFuture.then<void>((_) {}),
      canvasesFuture.then<void>((_) {}),
    ]);
    final responses = await spacesFuture;
    final canvasesResult = await canvasesFuture;
    final firstPage = responses.first;
    return MainHomeData(
      session: session,
      spaces: firstPage.spaces,
      pinnedSpaces: responses.last.spaces,
      recentCanvases: canvasesResult.canvases,
      recentCanvasesError: canvasesResult.error,
      hasMore: firstPage.hasMore,
    );
  }

  Future<({List<MainCanvas> canvases, String? error})> _loadRecentCanvases() async {
    try {
      final payload = await _authApi.getAuthenticated(
        '/spaces/pages/recent',
        queryParameters: const {'limit': '3'},
      );
      Object? raw = payload['data'] ?? payload['pages'] ?? payload['items'];
      if (raw is Map) {
        raw = raw['pages'] ?? raw['items'] ?? raw['recent'] ?? raw['recents'];
      }
      if (raw is! List) {
        throw const MainApiException(
          'Eduma returned an unexpected recent canvases response.',
        );
      }
      return (
        canvases: [
          for (final item in raw)
            if (MainCanvas.tryParse(item) case final canvas?) canvas,
        ],
        error: null,
      );
    } on AuthApiException catch (error) {
      return (canvases: const <MainCanvas>[], error: error.message);
    } on MainApiException catch (error) {
      return (canvases: const <MainCanvas>[], error: error.message);
    }
  }

  Future<MainSpacesPage> loadSpaces({
    required int page,
    String query = '',
    String currentUserId = '',
  }) => _loadSpaces(
    page: page,
    search: query,
    currentUserId: currentUserId,
  );

  Future<MainSpacesPage> _loadSpaces({
    required int page,
    String search = '',
    bool? pinned,
    String currentUserId = '',
  }) async {
    final payload = await _authApi.getAuthenticated(
      '/spaces',
      queryParameters: {
        'page': '$page',
        'limit': '$pageSize',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (pinned != null) 'pinned': '$pinned',
      },
    );

    Object? raw = payload['data'] ?? payload['spaces'] ?? payload['items'];
    if (raw is Map) {
      raw = raw['spaces'] ?? raw['items'] ?? raw['data'];
    }
    if (raw is! List) {
      throw const MainApiException(
        'Eduma returned an unexpected spaces response.',
      );
    }

    final spaces = <MainSpace>[];
    for (final item in raw) {
      if (item is! Map) {
        throw const MainApiException(
          'Eduma returned an invalid space in the spaces list.',
        );
      }
      spaces.add(
        MainSpace.fromMap(
          Map<String, dynamic>.from(item),
          currentUserId: currentUserId,
        ),
      );
    }
    return MainSpacesPage(spaces: spaces, hasMore: spaces.length >= pageSize);
  }

  Future<MainSpace?> createSpace({
    required String title,
    String? description,
    String? clientRef,
    String currentUserId = '',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const MainApiException('Enter a title for this space.');
    }
    final trimmedDescription = description?.trim() ?? '';
    final payload = await _authApi.postAuthenticated(
      '/spaces',
      body: {
        'title': trimmedTitle,
        if (trimmedDescription.isNotEmpty) 'description': trimmedDescription,
        if (clientRef != null && clientRef.trim().isNotEmpty) 'clientRef': clientRef.trim(),
      },
    );
    final raw = payload['space'] ?? payload['data'] ?? payload;
    if (raw is! Map) return null;
    return tryParseMainSpace(
      Map<String, dynamic>.from(raw),
      currentUserId: currentUserId,
    );
  }

  Future<MainSpacePreview> previewInvite(String input) async {
    final code = SpaceInviteLink.extractCode(input);
    if (code.isEmpty) {
      throw const MainApiException('Enter an invite code or paste an invite link.');
    }
    try {
      final payload = await _authApi.getAuthenticated(
        '/spaces/invite/${Uri.encodeComponent(code)}',
      );
      final raw = payload['space'] ?? payload['preview'] ?? payload['data'] ?? payload;
      if (raw is! Map) {
        throw const MainApiException(
          'Eduma returned an unexpected invite preview response.',
        );
      }
      return MainSpacePreview.fromMap(Map<String, dynamic>.from(raw));
    } on AuthApiException catch (error) {
      final expired = SpaceInviteLink.expiredErrorMessage(
        statusCode: error.statusCode,
        code: error.code,
      );
      if (expired != null) throw MainApiException(expired);
      rethrow;
    }
  }

  Future<MainSpaceJoinResult> joinSpace(
    String input, {
    String currentUserId = '',
  }) async {
    final code = SpaceInviteLink.extractCode(input);
    if (code.isEmpty) {
      throw const MainApiException('Enter an invite code or paste an invite link.');
    }
    try {
      final payload = await _authApi.postAuthenticated(
        '/spaces/join',
        body: {'inviteCode': code},
      );
      final raw = payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'] as Map)
          : payload;
      return MainSpaceJoinResult.fromMap(raw, currentUserId: currentUserId);
    } on AuthApiException catch (error) {
      final expired = SpaceInviteLink.expiredErrorMessage(
        statusCode: error.statusCode,
        code: error.code,
      );
      if (expired != null) throw MainApiException(expired);
      rethrow;
    }
  }

  Future<void> setSpacePinned(String spaceId, {required bool pinned}) async {
    final path = '/spaces/${Uri.encodeComponent(spaceId)}/pin';
    try {
      if (pinned) {
        await _authApi.postAuthenticated(path);
      } else {
        await _authApi.deleteAuthenticated(path);
      }
    } on AuthApiException catch (error) {
      if (pinned && error.statusCode == 409) {
        throw const MainPinLimitException();
      }
      rethrow;
    }
  }
}
