import '../../auth/data/auth_api.dart';
import '../../main/logic/main_actions.dart';
import '../data/space_detail_api.dart';
import '../data/space_detail_models.dart';

abstract final class SpaceDetailActions {
  static EdumaSession? get currentSession => MainActions.currentSession;

  static Future<EdumaSession?> restoreSession() => MainActions.restoreSession();

  static Future<SpaceDetailBundle> loadSpace(EdumaSession session, String spaceId) =>
      SpaceDetailApi.instance.loadSpace(session, spaceId);

  static Future<SpaceDetailData> loadSpaceSummary(String spaceId) => SpaceDetailApi.instance.loadSpaceSummary(spaceId);

  static Future<void> leaveOrDeleteSpace(
    String spaceId, {
    required String userId,
    required bool deleteSpace,
    required bool deleteMedia,
  }) => SpaceDetailApi.instance.leaveOrDeleteSpace(
    spaceId,
    userId: userId,
    deleteSpace: deleteSpace,
    deleteMedia: deleteMedia,
  );

  static Future<void> reportSpace({
    required String spaceId,
    required String reason,
    String? details,
  }) => SpaceDetailApi.instance.reportSpace(
    spaceId: spaceId,
    reason: reason,
    details: details,
  );

  static Future<void> setPinned(String spaceId, {required bool pinned}) =>
      MainActions.setSpacePinned(spaceId, pinned: pinned);

  static Future<SpaceDetailData> updateSpace(
    String spaceId, {
    required String title,
    String? description,
  }) => SpaceDetailApi.instance.updateSpace(spaceId, title: title, description: description);

  static Future<({String inviteCode, DateTime? expiresAt})> renewInviteCode(String spaceId) =>
      SpaceDetailApi.instance.renewInviteCode(spaceId);

  static Future<SpacePage> createPage(
    String spaceId, {
    required String title,
    String? description,
    required SpacePageType pageType,
  }) => SpaceDetailApi.instance.createPage(
    spaceId,
    title: title,
    description: description,
    pageType: pageType,
  );

  static Future<SpacePage> updatePage(
    String spaceId,
    String pageId, {
    String? title,
    String? description,
    bool? isArchived,
  }) => SpaceDetailApi.instance.updatePage(
    spaceId,
    pageId,
    title: title,
    description: description,
    isArchived: isArchived,
  );

  static Future<void> deletePage(String spaceId, String pageId) => SpaceDetailApi.instance.deletePage(spaceId, pageId);

  static Future<void> removeMember(String spaceId, String userId) =>
      SpaceDetailApi.instance.removeMember(spaceId, userId);

  static Future<void> setAdmin(String spaceId, String userId, {required bool promote}) =>
      SpaceDetailApi.instance.setAdmin(spaceId, userId, promote: promote);
}
