import '../../auth/data/auth_api.dart';
import 'main_canvas.dart';
import 'main_space.dart';

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
}
