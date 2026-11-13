class MainApiException implements Exception {
  const MainApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MainSpace {
  const MainSpace({
    required this.id,
    required this.title,
    required this.isPinned,
    required this.memberCount,
    this.description,
    this.coverUrl,
    this.lastActivity,
  });

  final String id;
  final String title;
  final bool isPinned;
  final int memberCount;
  final String? description;
  final String? coverUrl;
  final DateTime? lastActivity;

  factory MainSpace.fromMap(Map<String, dynamic> data) {
    final id = '${data['_id'] ?? data['id'] ?? ''}'.trim();
    final title = '${data['title'] ?? ''}'.trim();
    if (id.isEmpty || title.isEmpty) {
      throw const MainApiException(
        'Eduma returned a space without its required identity.',
      );
    }

    final rawMembers = data['memberIds'];
    final members = rawMembers is List ? rawMembers : const <dynamic>[];
    final rawCount = data['memberCount'];
    final image = data['coverUrl'] ?? data['coverImage'] ?? data['imageUrl'];
    final activity = DateTime.tryParse(
      '${data['lastEditedAt'] ?? data['updatedAt'] ?? data['lastAccessedAt'] ?? ''}',
    );

    return MainSpace(
      id: id,
      title: title,
      isPinned: data['isPinned'] == true,
      memberCount: rawCount is num ? rawCount.toInt() : members.length,
      description: _optionalText(data['description']),
      coverUrl: _safeImageUrl(image),
      lastActivity: activity,
    );
  }
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String? _safeImageUrl(Object? value) {
  final text = _optionalText(value);
  if (text == null) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri.toString();
}
