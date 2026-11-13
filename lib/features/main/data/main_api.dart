import '../../auth/data/auth_api.dart';
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
    required this.hasMore,
  });

  final EdumaSession session;
  final List<MainSpace> spaces;
  final List<MainSpace> pinnedSpaces;
  final bool hasMore;
}

class MainApi {
  MainApi._();

  static final instance = MainApi._();
  static const pageSize = 20;

  final EdumaAuthApi _authApi = EdumaAuthApi.instance;

  Future<MainHomeData> loadHome(EdumaSession session) async {
    final responses = await Future.wait([
      _loadSpaces(page: 1),
      _loadSpaces(page: 1, pinned: true),
    ]);
    final firstPage = responses.first;
    return MainHomeData(
      session: session,
      spaces: firstPage.spaces,
      pinnedSpaces: responses.last.spaces,
      hasMore: firstPage.hasMore,
    );
  }

  Future<MainSpacesPage> loadSpaces({
    required int page,
    String query = '',
  }) => _loadSpaces(page: page, search: query);

  Future<MainSpacesPage> _loadSpaces({
    required int page,
    String search = '',
    bool? pinned,
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
      spaces.add(MainSpace.fromMap(Map<String, dynamic>.from(item)));
    }
    return MainSpacesPage(spaces: spaces, hasMore: spaces.length >= pageSize);
  }
}
