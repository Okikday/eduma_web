import '../../../core/presentation/flutter_host.dart';
import '../../auth/data/auth_api.dart';
import '../data/profile_api.dart';
import '../data/profile_models.dart';

export '../data/profile_models.dart';

abstract final class ProfileActions {
  static final _api = ProfileApi.instance;

  static Future<ProfileStats> loadStats() => _api.loadStats();

  static Future<Map<String, dynamic>?> refreshMe() => _api.refreshMe();

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? username,
  }) => _api.updateProfile(name: name, username: username);

  static Future<bool?> checkUsername(String username) => _api.checkUsername(username);

  static Future<void> updatePrivacyPreferences({
    bool? allowSpaceAdds,
    bool? showPresence,
    bool? personalizationEnabled,
    String? aiPersonalityAccess,
  }) => _api.updatePrivacyPreferences(
    allowSpaceAdds: allowSpaceAdds,
    showPresence: showPresence,
    personalizationEnabled: personalizationEnabled,
    aiPersonalityAccess: aiPersonalityAccess,
  );

  static Future<void> sendPasswordResetCode(String email) => _api.sendPasswordResetCode(email);

  static Future<EdumaSession> resetPasswordAndSignIn({
    required String email,
    required String rawCodeOrLink,
    required String newPassword,
  }) => _api.resetPasswordAndSignIn(
    email: email,
    rawCodeOrLink: rawCodeOrLink,
    newPassword: newPassword,
  );

  static Future<Map<String, dynamic>> updateLearnerProfile({
    String? level,
    String? fieldOfStudy,
    String? school,
  }) => _api.updateLearnerProfile(
    level: level,
    fieldOfStudy: fieldOfStudy,
    school: school,
  );

  static Future<void> signOutAllDevices() {
    FlutterHost.dispose();
    return _api.signOutAllDevices();
  }

  static Future<void> deleteAccount() => _api.deleteAccount();
}
