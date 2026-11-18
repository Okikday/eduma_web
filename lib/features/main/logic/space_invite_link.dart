/// Builds and extracts Eduma space invite codes and links.
///
/// Mirrors `SpaceInviteLink` and `InviteExpiryLogic` from `../eduma`.
abstract final class SpaceInviteLink {
  static const maxPinnedSpaces = 16;

  static const expiredInviteMessage = 'This invite link has expired. Ask someone in the space for a new one.';

  /// Builds a shareable join URL for [inviteCode] given the web origin.
  static String buildForOrigin(String origin, String inviteCode) {
    final cleanOrigin = origin.replaceFirst(RegExp(r'/+$'), '');
    return '$cleanOrigin/join/${Uri.encodeComponent(inviteCode.trim())}';
  }

  /// Extracts a raw invite code from `"SPC-1234"` or `"https://.../join/SPC-1234?from=share"`.
  static String extractCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final marker = trimmed.indexOf('/join/');
    if (marker < 0) return trimmed;
    final tail = trimmed.substring(marker + '/join/'.length);
    return tail.split(RegExp(r'[/?#]')).first.trim();
  }

  /// Normalizes invite API errors so expired invites show the exact source copy.
  static String? expiredErrorMessage({int? statusCode, String? code}) {
    if (statusCode == 410) return expiredInviteMessage;
    if ((code ?? '').trim().toUpperCase() == 'INVITE_EXPIRED') {
      return expiredInviteMessage;
    }
    return null;
  }
}
