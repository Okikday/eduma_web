import '../../auth/data/auth_api.dart';
import '../data/main_api.dart';

abstract final class MainActions {
  static Future<EdumaSession?> restoreSession() => EdumaAuthApi.instance.restoreSession();

  static Future<MainHomeData> loadHome(EdumaSession session) => MainApi.instance.loadHome(session);

  static Future<MainSpacesPage> loadSpaces({
    required int page,
    String query = '',
  }) => MainApi.instance.loadSpaces(page: page, query: query);
}
