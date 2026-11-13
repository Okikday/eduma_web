enum PasswordStrength {
  empty(0, ''),
  tooShort(0, 'Use at least 8 characters'),
  weak(1, 'Weak · add numbers, symbols or length'),
  fair(2, 'Fair'),
  good(3, 'Good'),
  strong(4, 'Strong');

  const PasswordStrength(this.segments, this.label);

  final int segments;
  final String label;

  bool get acceptable => index >= PasswordStrength.weak.index;
}

enum UsernameCheck { idle, checking, available, taken, invalid, unknown }

abstract final class SignUpLogic {
  static final _notAllowed = RegExp(r'[^a-z0-9._]');

  static String firstName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words.isEmpty ? '' : words.first;
  }

  static String cleanUsername(String input) {
    var value = input.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '.').replaceAll(_notAllowed, '');
    value = value.replaceAll(RegExp(r'\.{2,}'), '.').replaceAll(RegExp(r'^[._]+|[._]+$'), '');
    return value.length > 30 ? value.substring(0, 30).replaceAll(RegExp(r'[._]+$'), '') : value;
  }

  static bool validUsername(String value) => RegExp(r'^[a-z0-9][a-z0-9._]{1,28}[a-z0-9]$').hasMatch(value);

  static List<String> usernameCandidates(String name) {
    final words = name.trim().split(RegExp(r'\s+')).map(cleanUsername).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final parts = words.length == 1 ? words : [words.first, words.last];
    final dotted = cleanUsername(parts.join('.'));
    if (dotted.length < 3) return const [];
    final joined = cleanUsername(parts.join());
    final suffix = 10 + _hash(name.trim().toLowerCase()) % 90;
    final numbered = cleanUsername(
      '${dotted.length > 27 ? dotted.substring(0, 27) : dotted}$suffix',
    );
    return {dotted, joined, numbered}.where((value) => value.length >= 3).toList();
  }

  static String? referralCodeFrom(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.hasScheme || uri.hasAuthority || trimmed.startsWith('/'))) {
      final fragments = [
        uri,
        if (uri.fragment.isNotEmpty) Uri.tryParse(uri.fragment),
      ];
      for (final candidate in fragments.whereType<Uri>()) {
        final segments = candidate.pathSegments.where((part) => part.isNotEmpty);
        final parts = segments.toList();
        final inviteIndex = parts.indexOf('invite');
        if (inviteIndex >= 0 && inviteIndex + 1 < parts.length) {
          final code = cleanReferralCode(Uri.decodeComponent(parts[inviteIndex + 1]));
          if (code != null) return code;
        }
        for (final key in const ['ref', 'referral']) {
          final code = cleanReferralCode(candidate.queryParameters[key]);
          if (code != null) return code;
        }
      }
    }
    return cleanReferralCode(trimmed);
  }

  static String? cleanReferralCode(String? raw) {
    final code = raw?.trim().replaceAll(RegExp(r'\s+'), '');
    if (code == null || code.isEmpty) return null;
    return RegExp(r'^[A-Za-z0-9._\-]{3,40}$').hasMatch(code) ? code : null;
  }

  static PasswordStrength strengthOf(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < 8) return PasswordStrength.tooShort;
    if (_commonPasswords.contains(password.toLowerCase())) {
      return PasswordStrength.weak;
    }

    final characterClasses = [
      RegExp(r'[a-z]'),
      RegExp(r'[A-Z]'),
      RegExp(r'\d'),
      RegExp(r'[^A-Za-z0-9]'),
    ].where((pattern) => pattern.hasMatch(password)).length;

    var points = 1;
    if (password.length >= 12) points++;
    if (characterClasses >= 2) points++;
    if (characterClasses >= 3) points++;
    if (password.length >= 16 || characterClasses == 4) points++;

    return switch (points) {
      <= 1 => PasswordStrength.weak,
      2 => PasswordStrength.fair,
      3 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }

  static bool validEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

  static int _hash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static const _commonPasswords = {
    'password',
    '12345678',
    '123456789',
    '1234567890',
    'qwertyui',
    'qwerty123',
    'password1',
    '11111111',
    'iloveyou',
    'abcd1234',
  };
}
