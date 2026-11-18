import '../../../core/presentation/flutter_host.dart';
import '../data/auth_api.dart';

export '../data/auth_api.dart'
    show
        AuthApiException,
        EdumaSession,
        edumaApiBaseUrl,
        edumaFlutterAppUrl,
        edumaGoogleWebClientId;

abstract final class AuthActions {
  static final _api = EdumaAuthApi.instance;

  static bool get canOpenFlutterApp => _api.canOpenFlutterApp;

  static EdumaSession? get currentSession => _api.currentSession;

  static Future<EdumaSession> signIn({
    required String email,
    required String password,
  }) => _api.signIn(email: email, password: password);

  static Future<EdumaSession> googleSignIn(
    String idToken, {
    String? referralCode,
  }) => _api.googleSignIn(idToken: idToken, referralCode: referralCode);

  static Future<EdumaSession?> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String referralCode,
  }) => _api.register(
    name: name,
    username: username,
    email: email,
    password: password,
    referralCode: referralCode,
  );

  static Future<void> acceptPendingSession(AuthApiException error) => _api.acceptPendingSession(error);

  static Future<void> requestPasswordReset(String email) => _api.requestPasswordReset(email);

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => _api.resetPassword(token: token, newPassword: newPassword);

  static Future<EdumaSession?> verifyEmail({
    required String code,
    String email = '',
    String token = '',
  }) => _api.verifyEmail(code: code, email: email, token: token);

  static Future<void> resendVerification({String email = ''}) => _api.resendVerification(email: email);

  static Future<bool?> checkUsername(String username) => _api.checkUsername(username);

  static Future<Map<String, dynamic>> lookupReferral(String code) => _api.lookupReferral(code);

  static Future<EdumaSession?> restoreSession({bool forceRefresh = false}) =>
      _api.restoreSession(forceRefresh: forceRefresh);

  static Future<Map<String, dynamic>> saveUpdatedUserProfile(
    Map<String, dynamic> rawUser,
  ) => _api.saveUpdatedUserProfile(rawUser);

  static Future<void> signOut() {
    FlutterHost.dispose();
    return _api.signOut();
  }

  static void scrubTokenFromAddressBar() => _api.scrubTokenFromAddressBar();
}
