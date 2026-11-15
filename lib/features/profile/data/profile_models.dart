import '../../auth/logic/auth_link_logic.dart';

/// User counts from `GET /users/me/stats`.
class ProfileStats {
  const ProfileStats({
    this.notebooks = 0,
    this.spaces = 0,
    this.studySeconds = 0,
  });

  final int notebooks;
  final int spaces;
  final int studySeconds;

  String get formattedStudyTime {
    if (studySeconds < 60) return '0m';
    final hours = studySeconds ~/ 3600;
    final minutes = (studySeconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  factory ProfileStats.fromMap(Map<String, dynamic> map) {
    final source = map['stats'] is Map
        ? Map<String, dynamic>.from(map['stats'] as Map)
        : map;
    return ProfileStats(
      notebooks: _int(source['notebooks'] ?? source['pages'] ?? source['canvases']),
      spaces: _int(source['spaces']),
      studySeconds: _int(source['studySeconds'] ?? source['totalStudySeconds']),
    );
  }

  static int _int(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse('${raw ?? ''}') ?? 0;
  }
}

/// Pure rules for Edit Profile (name + username).
abstract final class EditProfileLogic {
  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_.]{3,30}$');

  static String normalizeUsername(String raw) {
    final trimmed = raw.trim();
    return trimmed.startsWith('@') ? trimmed.substring(1).trim() : trimmed;
  }

  static bool usernameChanged(String raw, String? current) {
    final next = normalizeUsername(raw);
    return next.isNotEmpty && next != (current ?? '').trim();
  }

  static String? usernameProblem(String raw, String? current) {
    if (!usernameChanged(raw, current)) return null;
    final normalized = normalizeUsername(raw);
    if (!_usernamePattern.hasMatch(normalized)) {
      return 'Use 3–30 letters, digits, "_" or "."';
    }
    return null;
  }

  static bool nameChanged(String raw, String current) {
    final next = raw.trim();
    return next.isNotEmpty && next != current.trim();
  }

  static bool canSave({
    required String name,
    required String currentName,
    required String username,
    required String? currentUsername,
    required bool? usernameAvailable,
    required bool isCheckingUsername,
  }) {
    if (name.trim().isEmpty) return false;
    final nameDiff = nameChanged(name, currentName);
    final userDiff = usernameChanged(username, currentUsername);
    if (!nameDiff && !userDiff) return false;
    if (!userDiff) return true;
    if (usernameProblem(username, currentUsername) != null) return false;
    return !isCheckingUsername && usernameAvailable == true;
  }
}

/// Pure rules for changing/setting password with an emailed reset token.
abstract final class ChangePasswordLogic {
  static const minLength = 8;

  static String? tokenFrom(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return AuthLinkLogic.tokenFrom(trimmed, expect: .resetPassword) ?? trimmed;
  }

  static String? passwordProblem(String password, String confirm) {
    if (password.isEmpty) return null;
    if (password.length < minLength) {
      return 'Use at least $minLength characters.';
    }
    if (confirm.isNotEmpty && confirm != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static bool canSubmit({
    required String codeInput,
    required String password,
    required String confirm,
  }) =>
      tokenFrom(codeInput) != null &&
      password.length >= minLength &&
      password == confirm;
}
