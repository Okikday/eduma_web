import 'dart:async';
import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

const edumaApiBaseUrl = String.fromEnvironment(
  'EDUMA_API_BASE_URL',
  defaultValue: 'https://eduma-backend1.onrender.com/api/v1',
);

const edumaFlutterAppUrl = String.fromEnvironment(
  'EDUMA_FLUTTER_APP_URL',
  defaultValue: '',
);

const edumaGoogleWebClientId = String.fromEnvironment(
  'EDUMA_GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);

Map<String, dynamic>? _pendingUser(Map<String, dynamic> details) {
  final raw = details['user'] is Map
      ? details['user']
      : details['email'] != null
      ? details
      : null;
  return raw is Map ? Map<String, dynamic>.from(raw) : null;
}

String _userEmail(Map<String, dynamic> user) {
  final value = user['email'];
  return value is Map ? '${value['email'] ?? ''}' : '${value ?? ''}';
}

class AuthApiException implements Exception {
  const AuthApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details = const {},
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic> details;

  bool get isEmailNotVerified =>
      code?.toUpperCase() == 'EMAIL_NOT_VERIFIED' ||
      (statusCode == 403 && _pendingUser(details)?['isEmailVerified'] == false);

  bool get isDefinitiveRefusal =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500 && statusCode != 408 && statusCode != 429;

  Map<String, dynamic>? get pendingSession {
    final nested = details['session'] ?? details['tokens'];
    final data = nested is Map ? Map<String, dynamic>.from(nested) : details;
    if ('${data['accessToken'] ?? ''}'.isEmpty) return null;
    final user = _pendingUser(details);
    return {
      ...data,
      if (user != null) 'user': user,
    };
  }

  @override
  String toString() => message;
}

class EdumaSession {
  const EdumaSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.warning,
  });

  final Map<String, dynamic> user;
  final String accessToken;
  final String refreshToken;
  final String? warning;

  String get name => '${user['name'] ?? user['fullName'] ?? 'Eduma learner'}';
  String get email => _userEmail(user);
  String get role => '${user['role'] ?? 'student'}';
  String get userId => '${user['_id'] ?? user['id'] ?? ''}';
}

class EdumaAuthApi {
  EdumaAuthApi._();

  static final instance = EdumaAuthApi._();
  static const _appBoxName = 'kickin_box';
  static const _timeout = Duration(seconds: 25);

  final BrowserClient _client = BrowserClient()..withCredentials = true;
  Future<LazyBox<dynamic>>? _openingBox;
  bool _hiveInitialized = false;
  String? _accessToken;

  bool get canOpenFlutterApp {
    final legacy = Uri.tryParse(edumaFlutterAppUrl);
    return legacy != null &&
        (legacy.scheme == 'http' || legacy.scheme == 'https') &&
        legacy.hasAuthority &&
        legacy.path != '/' &&
        legacy.origin == Uri.base.origin;
  }

  Future<EdumaSession> signIn({
    required String email,
    required String password,
  }) async {
    final payload = await _post('/auth/login', {
      'email': email.trim(),
      'password': password,
      'termsAccepted': true,
    });
    final session = _readSession(payload);
    if (session == null) {
      throw const AuthApiException(
        message: 'The server returned an incomplete sign-in response. Please try again.',
      );
    }
    await _saveSession(session);
    return session;
  }

  Future<EdumaSession> googleSignIn({
    required String idToken,
    String? referralCode,
  }) async {
    final code = referralCode?.trim() ?? '';
    late final Map<String, dynamic> payload;
    try {
      payload = await _post('/auth/google', {
        'idToken': idToken,
        if (code.isNotEmpty) 'referralCode': code,
        'termsAccepted': true,
      });
    } on AuthApiException catch (error) {
      final text = '${error.message} ${error.code ?? ''} ${error.details}'.toLowerCase();
      final referralRejected = error.statusCode == 400 || error.statusCode == 422;
      if (code.isEmpty || !referralRejected || (!text.contains('referral') && !text.contains('invite'))) {
        rethrow;
      }
      payload = await _post('/auth/google', {
        'idToken': idToken,
        'termsAccepted': true,
      });
    }
    final session = _readSession(payload);
    if (session == null) {
      throw const AuthApiException(
        message: 'The server returned an incomplete Google sign-in response. Please try again.',
      );
    }
    await _saveSession(session);
    return session;
  }

  Future<EdumaSession?> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String referralCode,
  }) async {
    final payload = await _post('/auth/register', {
      'name': name.trim(),
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      if (referralCode.trim().isNotEmpty) 'referralCode': referralCode.trim(),
      'termsAccepted': true,
    });
    final session = _readSession(payload);
    if (session != null) await _saveSession(session);
    return session;
  }

  Future<void> acceptPendingSession(AuthApiException error) async {
    final pending = error.pendingSession;
    if (pending == null) return;
    final session = _readSession(pending);
    if (session != null) await _saveSession(session);
  }

  Future<bool?> checkUsername(String username) async {
    final uri = Uri.parse(
      '$_baseUrl/users/check-username',
    ).replace(queryParameters: {'username': username});
    final payload = await _send('GET', uri);
    final value =
        payload['available'] ??
        payload['isAvailable'] ??
        (payload['exists'] is bool ? !(payload['exists'] as bool) : null) ??
        (payload['taken'] is bool ? !(payload['taken'] as bool) : null);
    return value is bool ? value : null;
  }

  Future<Map<String, dynamic>> lookupReferral(String code) => _send(
    'GET',
    Uri.parse('$_baseUrl/referrals/${Uri.encodeComponent(code)}'),
  );

  Future<Map<String, dynamic>> getAuthenticated(
    String path, {
    Map<String, String> queryParameters = const {},
  }) {
    if (!path.startsWith('/') || path.startsWith('//')) {
      throw const AuthApiException(
        message: 'Eduma received an invalid API path.',
      );
    }
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw const AuthApiException(
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return _send('GET', uri, authenticated: true);
  }

  Future<void> requestPasswordReset(String email) async {
    await _post('/auth/forgot-password', {'email': email.trim()});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _post('/auth/reset-password', {
      'token': token.trim(),
      'newPassword': newPassword,
    });
  }

  Future<EdumaSession?> verifyEmail({
    required String code,
    String email = '',
    String token = '',
  }) async {
    Map<String, dynamic> payload;
    if (token.trim().isNotEmpty) {
      payload = await _post('/auth/verify-email', {'token': token.trim()});
    } else {
      final authenticated = email.trim().isEmpty;
      if (authenticated) await restoreSession();
      payload = await _post(
        '/auth/verify-email',
        {
          'code': code.replaceAll(RegExp(r'\D'), ''),
          if (!authenticated) 'email': email.trim(),
        },
        authenticated: authenticated,
      );
    }

    final session = _readSession(payload);
    if (session != null) {
      await _saveSession(session);
    } else {
      final user = _readUser(payload);
      if (user != null) {
        user['isEmailVerified'] = true;
        await _saveProfile(user);
      }
    }
    return session;
  }

  Future<void> resendVerification({String email = ''}) async {
    if (email.trim().isEmpty) {
      await restoreSession();
      await _post('/auth/verify-email/resend', const {}, authenticated: true);
    } else {
      await _post('/auth/verify-email/resend-by-email', {
        'email': email.trim(),
      });
    }
  }

  Future<EdumaSession?> restoreSession() async {
    final box = await _appBox();
    if (await box.get('isUserSignedIn') != true) return null;

    final storedProfile = _asStringMap(await box.get('profile'));
    final refreshToken = '${await box.get('refreshToken') ?? ''}';
    try {
      final payload = await _post(
        '/auth/refresh',
        {if (refreshToken.isNotEmpty) 'refreshToken': refreshToken},
      );
      final accessToken = '${payload['accessToken'] ?? ''}';
      if (accessToken.isEmpty) {
        throw const AuthApiException(
          message: 'The server did not return a refreshed session.',
        );
      }
      _accessToken = accessToken;
      final nextRefreshToken = '${payload['refreshToken'] ?? ''}';
      await _saveRefreshToken(box, nextRefreshToken);

      var user = _readUser(payload) ?? storedProfile;
      if (user == null || _userId(user).isEmpty) {
        final me = await _send(
          'GET',
          Uri.parse('$_baseUrl/auth/me'),
          authenticated: true,
        );
        user = _readUser(me);
      }
      if (user == null || _userId(user).isEmpty) {
        throw const AuthApiException(
          message: 'The refreshed session did not include an Eduma profile.',
        );
      }
      await _saveProfile(user);
      return EdumaSession(
        user: user,
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );
    } on AuthApiException catch (error) {
      if (error.isDefinitiveRefusal) {
        await _clearSession(box);
        return null;
      }
      if (storedProfile != null && _userId(storedProfile).isNotEmpty) {
        return EdumaSession(
          user: storedProfile,
          accessToken: '',
          refreshToken: refreshToken,
          warning: error.message,
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final box = await _appBox();
    final refreshToken = '${await box.get('refreshToken') ?? ''}';
    try {
      await _post('/auth/logout', {
        if (refreshToken.isNotEmpty) 'refreshToken': refreshToken,
      });
    } finally {
      await _clearSession(box);
    }
  }

  void scrubTokenFromAddressBar() {
    final current = Uri.base;
    final query = Map<String, String>.from(current.queryParameters)..remove('token');
    final cleanUri = Uri(
      path: current.path,
      queryParameters: query.isEmpty ? null : query,
      fragment: current.fragment.isEmpty ? null : current.fragment,
    );
    web.window.history.replaceState(null, '', cleanUri.toString());
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body, {
    bool authenticated = false,
  }) => _send(
    'POST',
    Uri.parse('$_baseUrl$path'),
    body: body,
    authenticated: authenticated,
  );

  String get _baseUrl {
    final value = edumaApiBaseUrl.trim();
    if (value.isEmpty) {
      throw const AuthApiException(
        message: 'Eduma API is not configured. Set EDUMA_API_BASE_URL and rebuild.',
      );
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    bool authenticated = false,
  }) async {
    final request = http.Request(method, uri)..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final token = _accessToken ?? '';
    if (authenticated && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    late final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const AuthApiException(
        message: 'The Eduma server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        message: 'Could not reach Eduma. Check your connection and try again.',
      );
    }

    final decoded = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseError(response, decoded);
    }
    return _payload(decoded);
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const AuthApiException(
        message: 'Eduma returned an unreadable response. Please try again.',
      );
    }
    throw const AuthApiException(
      message: 'Eduma returned an unexpected response. Please try again.',
    );
  }

  AuthApiException _responseError(
    http.Response response,
    Map<String, dynamic> body,
  ) {
    final error = body['error'] is Map ? Map<String, dynamic>.from(body['error'] as Map) : body;
    final details = error['details'] is Map
        ? Map<String, dynamic>.from(error['details'] as Map)
        : body['details'] is Map
        ? Map<String, dynamic>.from(body['details'] as Map)
        : <String, dynamic>{};
    final fieldErrors = details['fieldErrors'];
    final message = '${error['message'] ?? body['message'] ?? ''}'.trim();
    final code = '${error['code'] ?? body['code'] ?? ''}'.trim();
    final seconds =
        int.tryParse(
          '${details['retryAfter'] ?? response.headers['retry-after'] ?? ''}',
        ) ??
        0;
    return AuthApiException(
      statusCode: response.statusCode,
      code: code.isEmpty ? null : code,
      details: {
        ...details,
        if (seconds > 0) 'retryAfter': seconds,
      },
      message: switch (response.statusCode) {
        429 when seconds > 0 => 'Too many attempts. Please wait $seconds seconds and try again.',
        429 => 'Too many attempts. Please wait a moment and try again.',
        401 => 'Your session has expired. Please sign in again.',
        _ when message.isNotEmpty && message != 'Validation failed' => message,
        _ when fieldErrors is Map => _fieldErrorMessage(fieldErrors),
        400 || 403 || 404 || 409 || 422 => 'Please check your details and try again.',
        _ => 'Eduma could not complete that request. Please try again.',
      },
    );
  }

  String _fieldErrorMessage(Map fieldErrors) {
    final parts = <String>[];
    for (final entry in fieldErrors.entries.take(3)) {
      final raw = entry.value;
      final message = raw is List && raw.isNotEmpty ? raw.first : raw;
      if (message is String && message.trim().isNotEmpty) {
        parts.add('${entry.key}: ${message.trim()}');
      }
    }
    return parts.isEmpty ? 'Please check your details and try again.' : parts.join(' · ');
  }

  Map<String, dynamic> _payload(Map<String, dynamic> body) {
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : body;
  }

  EdumaSession? _readSession(Map<String, dynamic> payload) {
    final accessToken = '${payload['accessToken'] ?? ''}';
    if (accessToken.isEmpty) return null;
    final user = _readUser(payload);
    if (user == null || _userId(user).isEmpty) {
      throw const AuthApiException(
        message: 'The server returned a session without an Eduma profile.',
      );
    }
    return EdumaSession(
      user: user,
      accessToken: accessToken,
      refreshToken: '${payload['refreshToken'] ?? ''}',
    );
  }

  Map<String, dynamic>? _readUser(Map<String, dynamic> payload) {
    final raw = payload['user'] ?? payload;
    if (raw is! Map || (raw['_id'] == null && raw['id'] == null) || raw['email'] == null) {
      return null;
    }
    final user = Map<String, dynamic>.from(raw);
    user['id'] ??= user['_id'];
    user['name'] ??= user['fullName'] ?? '';
    user['role'] ??= 'student';
    user['isEmailVerified'] ??= false;
    return user;
  }

  Future<void> _saveSession(EdumaSession session) async {
    if (session.accessToken.isEmpty || session.userId.isEmpty) {
      throw const AuthApiException(
        message: 'The server returned an incomplete Eduma session.',
      );
    }
    final box = await _appBox();
    _accessToken = session.accessToken;
    await box.putAll({
      'profile': session.user,
      'userId': session.userId,
      'userRole': session.role,
      'isUserSignedIn': true,
      'auth_signed_in_here_v1': true,
    });
    await _saveRefreshToken(box, session.refreshToken);
  }

  Future<void> _saveProfile(Map<String, dynamic> user) async {
    final box = await _appBox();
    await box.putAll({
      'profile': user,
      'userId': _userId(user),
      'userRole': '${user['role'] ?? 'student'}',
    });
  }

  Future<void> _saveRefreshToken(
    LazyBox<dynamic> box,
    String refreshToken,
  ) async {
    if (refreshToken.isEmpty) {
      await box.delete('refreshToken');
    } else {
      await box.put('refreshToken', refreshToken);
    }
  }

  Future<void> _clearSession(LazyBox<dynamic> box) async {
    _accessToken = null;
    await box.deleteAll([
      'accessToken',
      'refreshToken',
      'profile',
      'userId',
      'userRole',
      'isUserSignedIn',
      'auth_signed_in_here_v1',
    ]);
  }

  Future<LazyBox<dynamic>> _appBox() async {
    if (Hive.isBoxOpen(_appBoxName)) return Hive.lazyBox<dynamic>(_appBoxName);
    final opening = _openingBox;
    if (opening != null) return opening;
    if (!_hiveInitialized) {
      Hive.init(null);
      _hiveInitialized = true;
    }
    final future = Hive.openLazyBox<dynamic>(_appBoxName);
    _openingBox = future;
    try {
      return await future;
    } finally {
      _openingBox = null;
    }
  }

  Map<String, dynamic>? _asStringMap(Object? value) => value is Map ? Map<String, dynamic>.from(value) : null;

  static String _userId(Map<String, dynamic> user) => '${user['_id'] ?? user['id'] ?? ''}';
}
