/// Email auth link utilities for extracting verification and password-reset
/// tokens from full URLs, hash URLs, query fragments, or raw codes.
enum AuthLinkKind {
  verifyEmail('verify-email'),
  resetPassword('reset-password');

  const AuthLinkKind(this.path);

  final String path;
}

typedef AuthLink = ({AuthLinkKind kind, String token});

abstract final class AuthLinkLogic {
  static const scheme = 'eduma';
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9\-_.~+/=%]+$');

  /// Extracts [AuthLink] metadata from full `https://...`, `eduma://...`,
  /// hash-routed `#/...`, or bare `/path?token=...` URIs.
  static AuthLink? parseUri(Uri uri) {
    final fragment = uri.fragment.isEmpty ? null : Uri.tryParse(uri.fragment);
    for (final candidate in [uri, ?fragment]) {
      final segments = [
        if (candidate.scheme == scheme && candidate.host.isNotEmpty) candidate.host,
        ...candidate.pathSegments.where((s) => s.isNotEmpty),
      ];
      if (segments.isEmpty) continue;
      final kind = _kindFromPath(segments.last);
      final token = cleanToken(candidate.queryParameters['token']);
      if (kind != null && token != null) {
        return (kind: kind, token: token);
      }
    }
    return null;
  }

  /// Extracts a usable token from a pasted email link, `token=...` parameter,
  /// or 6-digit / raw token string. When [expect] is given, links pointing to
  /// a different auth action path are rejected (`null`).
  static String? tokenFrom(String input, {AuthLinkKind? expect}) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('?')) text = text.substring(1);
    if (text.startsWith('token=')) {
      return cleanToken(
        Uri.decodeQueryComponent(text.substring(6).split('&').first),
      );
    }
    if (!_looksLikeLink(text)) return cleanToken(text);

    final uri = text.startsWith('/') ? Uri.tryParse(text) : Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null) return null;

    final link = parseUri(uri);
    if (link != null) {
      return expect == null || link.kind == expect ? link.token : null;
    }

    final fragment = uri.fragment.isEmpty ? null : Uri.tryParse(uri.fragment);
    if (fragment != null && expect != null) {
      final kind = _kindFromUri(fragment);
      if (kind != null && kind != expect) return null;
    }
    return cleanToken(
      uri.queryParameters['token'] ?? fragment?.queryParameters['token'],
    );
  }

  /// Validates that [raw] is a plausible URL-safe token or 6+ char code.
  static String? cleanToken(String? raw) {
    final value = raw?.trim();
    if (value == null || value.length < 6 || value.length > 2048) return null;
    return _tokenPattern.hasMatch(value) ? value : null;
  }

  static AuthLinkKind? _kindFromPath(String segment) {
    for (final kind in AuthLinkKind.values) {
      if (kind.path == segment) return kind;
    }
    return null;
  }

  static AuthLinkKind? _kindFromUri(Uri uri) {
    final segments = [
      if (uri.scheme == scheme && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (segments.isEmpty) return null;
    return _kindFromPath(segments.last);
  }

  static bool _looksLikeLink(String value) =>
      value.contains('://') ||
      value.contains('token=') ||
      value.startsWith('/') ||
      RegExp(r'^[\w-]+(\.[\w-]+)+/').hasMatch(value);
}
