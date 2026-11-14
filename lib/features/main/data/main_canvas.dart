enum MainCanvasType { dynamicCanvas, staticPage }

class MainCanvas {
  const MainCanvas({
    required this.id,
    required this.spaceId,
    required this.type,
    required this.title,
    required this.spaceTitle,
    required this.updatedAt,
    this.previewUrl,
    this.openedAt,
  });

  final String id;
  final String spaceId;
  final MainCanvasType type;
  final String title;
  final String? spaceTitle;
  final DateTime? updatedAt;
  final DateTime? openedAt;
  final String? previewUrl;

  static MainCanvas? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final item = Map<String, dynamic>.from(raw);
    final nested = item['page'];
    if (item['deleted'] == true || item['exists'] == false || item['isDeleted'] == true) {
      return null;
    }

    final page = nested is Map
        ? Map<String, dynamic>.from(nested)
        : item.containsKey('page') || item.containsKey('pageId')
        ? null
        : item;
    if (page == null) return null;

    final pageId = _text(item['pageId'] ?? page['_id'] ?? page['id']);
    final space = item['space'] is Map ? Map<String, dynamic>.from(item['space'] as Map) : const <String, dynamic>{};
    final spaceId = _text(
      item['spaceId'] ?? space['_id'] ?? space['id'] ?? page['spaceId'],
    );
    if (pageId == null || spaceId == null) return null;

    final pageType = '${page['pageType'] ?? 'dynamicCanvas'}';
    final updatedAt = DateTime.tryParse(
      '${page['updatedAt'] ?? page['lastEditedAt'] ?? ''}',
    );
    return MainCanvas(
      id: pageId,
      spaceId: spaceId,
      type: pageType == 'staticPage' ? .staticPage : .dynamicCanvas,
      title: _text(page['title']) ?? '',
      spaceTitle: _text(
        item['spaceTitle'] ?? space['title'] ?? page['spaceTitle'],
      ),
      updatedAt: updatedAt,
      openedAt: DateTime.tryParse(
        '${item['openedAt'] ?? item['lastOpenedAt'] ?? page['openedAt'] ?? ''}',
      ),
      previewUrl: _safeImageUrl(
        page['coverImage'] ?? page['previewUrl'] ?? page['thumbnailUrl'],
      ),
    );
  }
}

String? _text(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String? _safeImageUrl(Object? value) {
  final text = _text(value);
  if (text == null) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri.toString();
}
