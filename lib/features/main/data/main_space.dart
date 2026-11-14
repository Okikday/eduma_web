class MainApiException implements Exception {
  const MainApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum MainSpaceRole { owner, admin, member }

enum MainSpaceActivityType { edited, opened }

enum MainSpaceFilter {
  all('All'),
  owned('Owned by me'),
  joined('Joined'),
  pinned('Pinned');

  const MainSpaceFilter(this.label);

  final String label;
}

enum MainSpaceSort {
  recent('Recently updated'),
  name('Name A–Z'),
  date('Date created'),
  accessed('Recently opened by me');

  const MainSpaceSort(this.label);

  final String label;
}

class MainSpaceMember {
  const MainSpaceMember({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String? id;
  final String? name;
  final String? avatarUrl;
}

class MainSpace {
  const MainSpace({
    required this.id,
    required this.title,
    required this.isPinned,
    required this.memberCount,
    required this.role,
    required this.isPersonal,
    required this.isVerified,
    required this.memberPreview,
    this.createdAt,
    this.updatedAt,
    this.lastAccessedAt,
    this.description,
    this.coverUrl,
    this.lastActivity,
    this.activityType,
  });

  final String id;
  final String title;
  final bool isPinned;
  final int memberCount;
  final MainSpaceRole role;
  final bool isPersonal;
  final bool isVerified;
  final List<MainSpaceMember> memberPreview;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastAccessedAt;
  final String? description;
  final String? coverUrl;
  final DateTime? lastActivity;
  final MainSpaceActivityType? activityType;

  factory MainSpace.fromMap(
    Map<String, dynamic> data, {
    String currentUserId = '',
  }) {
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
    final editedAt = DateTime.tryParse('${data['lastEditedAt'] ?? ''}');
    final openedAt = DateTime.tryParse('${data['lastAccessedAt'] ?? ''}');
    final ownerId = '${data['ownerId'] ?? ''}';
    final admins = data['admins'] is List ? data['admins'] as List : const <dynamic>[];
    final MainSpaceRole role = switch ('${data['role'] ?? ''}'.toLowerCase()) {
      'owner' => .owner,
      'admin' => .admin,
      _ when currentUserId.isNotEmpty && ownerId == currentUserId => .owner,
      _
          when currentUserId.isNotEmpty &&
              admins.any((admin) {
                final id = admin is Map ? (admin['_id'] ?? admin['id'] ?? admin['userId']) : admin;
                return '$id' == currentUserId;
              }) =>
        .admin,
      _ => .member,
    };

    return MainSpace(
      id: id,
      title: title,
      isPinned: data['isPinned'] == true,
      memberCount: rawCount is num ? rawCount.toInt() : members.length,
      role: role,
      isPersonal: data['kind'] == 'personal',
      isVerified: _isVerified(data),
      memberPreview: [
        for (final member in members.take(4))
          if (member is Map)
            MainSpaceMember(
              id: _optionalText(member['_id'] ?? member['id']),
              name: _optionalText(member['name']),
              avatarUrl: _safeImageUrl(member['avatarUrl']),
            ),
      ],
      createdAt: DateTime.tryParse('${data['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${data['updatedAt'] ?? ''}'),
      lastAccessedAt: openedAt,
      description: _optionalText(data['description']),
      coverUrl: _safeImageUrl(image),
      lastActivity: editedAt ?? openedAt,
      activityType: editedAt != null
          ? .edited
          : openedAt != null
          ? .opened
          : null,
    );
  }
}

bool _isVerified(Map<String, dynamic> data) {
  final flag = data['isVerified'] ?? data['verified'];
  if (flag is bool) return flag;
  if (flag is String) return flag == 'true';
  return data['verification'] is Map && '${(data['verification'] as Map)['status']}' == 'verified';
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
