import '../../auth/data/auth_api.dart';
import '../data/main_api.dart';
import '../data/main_preferences.dart';
import '../data/main_space.dart';
import '../data/main_space_mutations.dart';

abstract final class MainActions {
  static EdumaSession? get currentSession => EdumaAuthApi.instance.currentSession;

  static Future<EdumaSession?> restoreSession({bool forceRefresh = false}) =>
      EdumaAuthApi.instance.restoreSession(forceRefresh: forceRefresh);

  static Future<MainHomeData> loadHome(EdumaSession session) => MainApi.instance.loadHome(session);

  static Future<MainSpacesPage> loadSpaces({
    required int page,
    String query = '',
    String currentUserId = '',
  }) => MainApi.instance.loadSpaces(
    page: page,
    query: query,
    currentUserId: currentUserId,
  );

  static Future<MainSpace?> createSpace({
    required String title,
    String? description,
    String? clientRef,
    String currentUserId = '',
  }) => MainApi.instance.createSpace(
    title: title,
    description: description,
    clientRef: clientRef,
    currentUserId: currentUserId,
  );

  static Future<MainSpacePreview> previewInvite(String input) => MainApi.instance.previewInvite(input);

  static Future<MainSpaceJoinResult> joinSpace(
    String input, {
    String currentUserId = '',
  }) => MainApi.instance.joinSpace(input, currentUserId: currentUserId);

  static Future<void> setSpacePinned(String spaceId, {required bool pinned}) =>
      MainApi.instance.setSpacePinned(spaceId, pinned: pinned);

  static Future<MainUserPreferences> loadPreferences() => MainPreferences.instance.load();

  static Future<void> saveSpaceGridView(bool grid) => MainPreferences.instance.saveSpaceGridView(grid);

  static Future<void> saveSpaceSort(MainSpaceSort sort) => MainPreferences.instance.saveSpaceSort(sort);
}
