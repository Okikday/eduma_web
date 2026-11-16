import '../../../core/data/json_envelope.dart';

/// How the Library catalog is sorted (`GET /library/documents?sort=...`).
enum LibrarySort {
  popular('Popular'),
  recent('Newest'),
  title('A–Z');

  const LibrarySort(this.label);
  final String label;
}

/// Card density/layout options matching `LibraryCardStyle` in `../eduma`.
enum LibraryCardStyle {
  tall('Tall'),
  wide('Wide'),
  normal('Normal');

  const LibraryCardStyle(this.label);
  final String label;
}

/// Top-level Library show filter (`All`, `Collections`, `In my groups`).
enum LibraryShowFilter {
  everything('All'),
  collections('Collections'),
  grouped('In my groups');

  const LibraryShowFilter(this.label);
  final String label;
}

/// Book group card gradient palette matching `LibraryGroupTint` in `../eduma`.
enum LibraryGroupTint {
  brand('Eduma', '#4b24d2', '#7091fc'),
  ocean('Ocean', '#1d6fd8', '#1554a6'),
  teal('Teal', '#0f8b80', '#0b6860'),
  forest('Forest', '#2f8f46', '#216932'),
  amber('Amber', '#c46a0a', '#954e06'),
  rose('Rose', '#d0315a', '#9e2142'),
  plum('Plum', '#8e3ab8', '#682889'),
  slate('Slate', '#475569', '#313b4a');

  const LibraryGroupTint(this.label, this.startHex, this.endHex);
  final String label;
  final String startHex;
  final String endHex;

  static LibraryGroupTint parse(String? raw) {
    final clean = (raw ?? '').trim().toLowerCase();
    for (final value in values) {
      if (value.name == clean) return value;
    }
    return .brand;
  }
}

/// User-created book group (`/library/groups`).
class LibraryGroup {
  const LibraryGroup({
    required this.id,
    required this.name,
    this.tint = .brand,
    this.documentIds = const [],
  });

  final String id;
  final String name;
  final LibraryGroupTint tint;
  final List<String> documentIds;

  factory LibraryGroup.fromMap(Map<String, dynamic> map) {
    final rawIds = (map['documentIds'] as List?) ?? (map['documents'] as List?) ?? const [];
    final ids = <String>[];
    for (final item in rawIds) {
      if (item is Map) {
        final docId = '${item['_id'] ?? item['id'] ?? item['documentId'] ?? ''}'.trim();
        if (docId.isNotEmpty) ids.add(docId);
      } else {
        final s = '${item ?? ''}'.trim();
        if (s.isNotEmpty) ids.add(s);
      }
    }
    return LibraryGroup(
      id: '${map['_id'] ?? map['id'] ?? ''}'.trim(),
      name: '${map['name'] ?? map['title'] ?? 'Untitled group'}'.trim(),
      tint: LibraryGroupTint.parse(map['tint']?.toString()),
      documentIds: ids,
    );
  }
}

/// Curated Library collection (`/library/collections`).
class LibraryCollection {
  const LibraryCollection({
    required this.id,
    required this.title,
    this.shelf,
    this.tint = .brand,
    this.documentCount = 0,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String? shelf;
  final LibraryGroupTint tint;
  final int documentCount;
  final String? coverUrl;

  factory LibraryCollection.fromMap(Map<String, dynamic> map) => LibraryCollection(
    id: '${map['_id'] ?? map['id'] ?? ''}'.trim(),
    title: '${map['title'] ?? map['name'] ?? 'Collection'}'.trim(),
    shelf: '${map['shelf'] ?? ''}'.trim().isEmpty ? null : '${map['shelf']}'.trim(),
    tint: LibraryGroupTint.parse(map['tint']?.toString()),
    documentCount: int.tryParse('${map['documentCount'] ?? map['count'] ?? ''}') ??
        ((map['documentIds'] as List?)?.length ?? 0),
    coverUrl: '${map['coverUrl'] ?? map['thumbnailUrl'] ?? ''}'.trim().isEmpty
        ? null
        : '${map['coverUrl'] ?? map['thumbnailUrl']}'.trim(),
  );
}

/// Document entry returned by `/library/documents` or `/library/recents`.
class LibraryDocument {
  const LibraryDocument({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.url,
    this.thumbnailUrl,
    this.mimeType = '',
    this.pageCount,
    this.sizeBytes,
    this.tags = const [],
    this.courseCodes = const [],
    this.institutions = const [],
    this.academicLevel,
    this.isVerified = false,
    this.shelf,
    this.isLocked = false,
  });

  final String id;
  final String title;
  final String author;
  final String category;
  final String description;
  final String url;
  final String? thumbnailUrl;
  final String mimeType;
  final int? pageCount;
  final int? sizeBytes;
  final List<String> tags;
  final List<String> courseCodes;
  final List<String> institutions;
  final String? academicLevel;
  final bool isVerified;
  final String? shelf;
  final bool isLocked;

  String resolvedFileUrl(String apiBaseUrl) {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed != null && parsed.hasAuthority) return trimmed;
    }
    return '$apiBaseUrl/library/documents/${Uri.encodeComponent(id)}/file.pdf';
  }

  String resolvedThumbnailUrl(String apiBaseUrl) {
    final trimmed = thumbnailUrl?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed != null && parsed.hasAuthority) return trimmed;
    }
    return '$apiBaseUrl/library/documents/${Uri.encodeComponent(id)}/thumbnail?sz=w400&w=400';
  }

  String get formatLabel {
    final mime = mimeType.toLowerCase();
    if (mime.contains('epub')) return 'EPUB';
    if (url.toLowerCase().contains('.epub')) return 'EPUB';
    return 'PDF';
  }

  String get formattedSize {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory LibraryDocument.fromMap(Map<String, dynamic> map) {
    final rawAccess = map['access'];
    final locked = rawAccess is Map && (rawAccess['locked'] == true || rawAccess['isLocked'] == true);
    return LibraryDocument(
      id: '${map['_id'] ?? map['id'] ?? map['documentId'] ?? ''}'.trim(),
      title: '${map['title'] ?? 'Untitled document'}'.trim(),
      author: '${map['author'] ?? ''}'.trim(),
      category: '${map['category'] ?? ''}'.trim(),
      description: '${map['description'] ?? ''}'.trim(),
      url: '${map['url'] ?? map['fileUrl'] ?? ''}'.trim(),
      thumbnailUrl: _nonEmpty(map['thumbnailUrl'] ?? map['coverUrl']),
      mimeType: '${map['mimeType'] ?? ''}'.trim(),
      pageCount: _int(map['pageCount'] ?? map['pages']),
      sizeBytes: _int(map['sizeBytes'] ?? map['size']),
      tags: _stringList(map['tags']),
      courseCodes: _stringList(map['courseCodes']),
      institutions: _stringList(map['institutions']),
      academicLevel: _nonEmpty(map['academicLevel']),
      isVerified: map['isVerified'] == true,
      shelf: _nonEmpty(map['shelf']),
      isLocked: locked,
    );
  }

  static String? _nonEmpty(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _int(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse('${raw ?? ''}');
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if ('${entry ?? ''}'.trim().isNotEmpty) '$entry'.trim(),
    ];
  }
}

class LibraryDocumentsPageResult {
  const LibraryDocumentsPageResult({
    required this.documents,
    required this.hasMore,
  });

  final List<LibraryDocument> documents;
  final bool hasMore;
}

abstract final class LibraryCatalogLogic {
  static LibraryDocumentsPageResult parseDocumentsPage(
    Map<String, dynamic> payload, {
    required int limit,
  }) {
    final list = extractResponseList(
      payload,
      const ['documents', 'recents', 'items', 'data'],
    );
    final docs = <LibraryDocument>[];
    for (final raw in list) {
      final map = raw['document'] is Map ? Map<String, dynamic>.from(raw['document'] as Map) : raw;
      if ('${map['_id'] ?? map['id'] ?? map['documentId'] ?? ''}'.trim().isNotEmpty) {
        docs.add(LibraryDocument.fromMap(map));
      }
    }

    final pagination = payload['pagination'];
    bool hasMore = docs.length >= limit;
    if (pagination is Map) {
      if (pagination['hasMore'] is bool) {
        hasMore = pagination['hasMore'] as bool;
      } else if (pagination['totalPages'] is num && pagination['page'] is num) {
        hasMore = (pagination['page'] as num) < (pagination['totalPages'] as num);
      }
    }

    return LibraryDocumentsPageResult(documents: docs, hasMore: hasMore);
  }

  static List<String> categoriesFrom(List<LibraryDocument> docs) {
    final seen = <String>{};
    final result = <String>[];
    for (final doc in docs) {
      final cat = doc.category.trim();
      if (cat.isNotEmpty && seen.add(cat.toLowerCase())) {
        result.add(cat);
      }
    }
    return result..sort();
  }

  /// Deterministic FNV-1a category tint pair matching Flutter's `LibraryBookTints`.
  static ({String main, String end}) bookTintsFor(LibraryDocument doc) {
    const palette = [
      'var(--eduma-accent-violet)',
      'var(--eduma-accent-sky)',
      'var(--eduma-accent-teal)',
      'var(--eduma-accent-amber)',
      'var(--eduma-accent-rose)',
      'var(--eduma-accent-green)',
    ];
    final category = doc.category.trim().toLowerCase();
    final key = category.isNotEmpty
        ? category
        : (doc.id.isNotEmpty ? doc.id : doc.title);
    var hash = 0x811c9dc5;
    for (final code in key.codeUnits) {
      hash = ((hash ^ code) * 0x01000193) & 0xffffffff;
    }
    final index = hash % palette.length;
    return (
      main: palette[index],
      end: palette[(index + 2) % palette.length],
    );
  }

  static List<LibraryGroup> parseGroups(Map<String, dynamic> payload) {
    final list = extractResponseList(payload, const ['groups', 'items', 'data']);
    return [
      for (final map in list)
        if ('${map['_id'] ?? map['id'] ?? ''}'.trim().isNotEmpty) LibraryGroup.fromMap(map),
    ];
  }

  static List<LibraryCollection> parseCollections(Map<String, dynamic> payload) {
    final list = extractResponseList(payload, const ['collections', 'items', 'data']);
    return [
      for (final map in list)
        if ('${map['_id'] ?? map['id'] ?? ''}'.trim().isNotEmpty) LibraryCollection.fromMap(map),
    ];
  }
}
