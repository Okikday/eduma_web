import '../../auth/data/auth_api.dart';
import 'profile_models.dart';

/// Client for `/users/me`, `/users/me/stats`, and password change flow.
class ProfileApi {
  ProfileApi._();

  static final ProfileApi instance = ProfileApi._();

  final _auth = EdumaAuthApi.instance;

  Future<ProfileStats> loadStats() async {
    try {
      final payload = await _auth.getAuthenticated('/users/me/stats');
      return ProfileStats.fromMap(payload);
    } catch (_) {
      return const ProfileStats();
    }
  }

  Future<Map<String, dynamic>?> refreshMe() async {
    final payload = await _auth.getAuthenticated('/users/me');
    final rawUser = payload['user'] is Map ? Map<String, dynamic>.from(payload['user'] as Map) : payload;
    if (rawUser.isEmpty) return null;
    return _auth.saveUpdatedUserProfile(rawUser);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? username,
  }) async {
    final payload = await _auth.patchAuthenticated(
      '/users/me',
      body: {
        'name': name.trim(),
        if (username != null && username.trim().isNotEmpty) 'username': EditProfileLogic.normalizeUsername(username),
      },
    );
    final rawUser = payload['user'] is Map ? Map<String, dynamic>.from(payload['user'] as Map) : payload;
    return _auth.saveUpdatedUserProfile(rawUser);
  }

  Future<bool?> checkUsername(String username) => _auth.checkUsername(EditProfileLogic.normalizeUsername(username));

  Future<void> updatePrivacyPreferences({
    bool? allowSpaceAdds,
    bool? showPresence,
    bool? personalizationEnabled,
    String? aiPersonalityAccess,
  }) async {
    await _auth.patchAuthenticated(
      '/users/me/preferences',
      body: {
        'allowSpaceAdds': ?allowSpaceAdds,
        'showPresence': ?showPresence,
        'personalizationEnabled': ?personalizationEnabled,
        'aiPersonalityAccess': ?aiPersonalityAccess,
      },
    );
  }

  Future<void> sendPasswordResetCode(String email) => _auth.requestPasswordReset(email);

  Future<EdumaSession> resetPasswordAndSignIn({
    required String email,
    required String rawCodeOrLink,
    required String newPassword,
  }) async {
    final token = ChangePasswordLogic.tokenFrom(rawCodeOrLink) ?? rawCodeOrLink.trim();
    await _auth.resetPassword(token: token, newPassword: newPassword);
    return _auth.signIn(email: email, password: newPassword);
  }

  Future<Map<String, dynamic>> updateLearnerProfile({
    String? level,
    String? fieldOfStudy,
    String? school,
  }) async {
    final payload = await _auth.patchAuthenticated(
      '/users/me',
      body: {
        if (level != null && level.trim().isNotEmpty) 'level': level.trim(),
        if (fieldOfStudy != null && fieldOfStudy.trim().isNotEmpty) 'fieldOfStudy': fieldOfStudy.trim(),
        if (school != null && school.trim().isNotEmpty) 'school': school.trim(),
      },
    );
    final rawUser = payload['user'] is Map ? Map<String, dynamic>.from(payload['user'] as Map) : payload;
    return _auth.saveUpdatedUserProfile(rawUser);
  }

  Future<void> signOutAllDevices() async {
    try {
      await _auth.postAuthenticated('/auth/logout-all');
    } finally {
      await _auth.signOut();
    }
  }

  Future<void> deleteAccount() async {
    await _auth.deleteAuthenticated('/users/me');
    await _auth.signOut();
  }
}
