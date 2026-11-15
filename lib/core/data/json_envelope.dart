/// Shared JSON envelope helpers for Eduma REST endpoints.
///
/// The backend wraps payloads in varying keys (`{data: ...}`, `{items: [...]}`,
/// `{events: [...]}`), or returns bare maps/lists after `EdumaAuthApi` unwrapping.
List<Map<String, dynamic>> extractResponseList(
  Map<String, dynamic> payload,
  List<String> keys,
) {
  for (final key in keys) {
    final value = payload[key];
    if (value is List) {
      return [
        for (final entry in value)
          if (entry is Map) Map<String, dynamic>.from(entry),
      ];
    }
    if (value is Map) {
      final nested = extractResponseList(Map<String, dynamic>.from(value), keys);
      if (nested.isNotEmpty) return nested;
    }
  }
  return const [];
}

Map<String, dynamic>? extractResponseMap(
  Map<String, dynamic> payload,
  List<String> keys,
) {
  for (final key in keys) {
    final value = payload[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  if (payload.containsKey('_id') || payload.containsKey('id')) return payload;
  return null;
}
