import 'space_detail_models.dart';

/// Represents a structured display block parsed from either a static section's
/// `delta` (Quill ops) or its outline `blocks`.
class StaticDisplayLine {
  const StaticDisplayLine({
    required this.kind,
    required this.text,
    this.headingLevel = 0,
    this.checked,
    this.url,
  });

  /// `heading`, `paragraph`, `checklist`, `code`, `callout`, `bullet`, `reference`
  final String kind;
  final String text;
  final int headingLevel;
  final bool? checked;
  final String? url;
}

class StaticPageSection {
  const StaticPageSection({
    required this.id,
    required this.name,
    required this.lines,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<StaticDisplayLine> lines;
  final DateTime? updatedAt;

  factory StaticPageSection.fromMap(Map<String, dynamic> map, {int index = 0}) {
    final rawName = '${map['name'] ?? map['title'] ?? ''}'.trim();
    final lines = <StaticDisplayLine>[];

    final delta = map['delta'];
    if (delta is List && delta.isNotEmpty) {
      lines.addAll(_linesFromDelta(delta));
    }

    if (lines.isEmpty && map['blocks'] is List) {
      lines.addAll(_linesFromBlocks(map['blocks'] as List));
    }

    final plain = '${map['content'] ?? map['text'] ?? ''}'.trim();
    if (lines.isEmpty && plain.isNotEmpty) {
      for (final part in plain.split('\n')) {
        if (part.trim().isNotEmpty) {
          lines.add(StaticDisplayLine(kind: 'paragraph', text: part.trim()));
        }
      }
    }

    return StaticPageSection(
      id: '${map['id'] ?? map['_id'] ?? 'sec_$index'}',
      name: rawName.isEmpty || _isPlaceholder(rawName)
          ? 'Section ${index + 1}'
          : rawName,
      lines: lines,
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}'),
    );
  }

  static bool _isPlaceholder(String s) => RegExp(
    r'^(untitled( section)?|section)( \d+)?$',
    caseSensitive: false,
  ).hasMatch(s.trim());
}

class DynamicCanvasCard {
  const DynamicCanvasCard({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    required this.checklist,
    this.colorIndex = 0,
    this.referenceUrl,
    this.x = 0,
    this.y = 0,
  });

  final String id;
  final String type;
  final String title;
  final String text;
  final List<({String text, bool done})> checklist;
  final int colorIndex;
  final String? referenceUrl;
  final double x;
  final double y;

  factory DynamicCanvasCard.fromMap(Map<String, dynamic> map, {int index = 0}) {
    final type = '${map['type'] ?? 'stickyNote'}';
    final title = '${map['title'] ?? map['heading'] ?? ''}'.trim();
    final rawDelta = map['deltaJson'] ?? map['delta'];
    var text = '${map['text'] ?? map['content'] ?? ''}'.trim();
    if (text.isEmpty && rawDelta is List) {
      text = _plainTextFromDelta(rawDelta);
    }

    final rawList = map['checklist'];
    final checklist = <({String text, bool done})>[
      if (rawList is List)
        for (final item in rawList)
          if (item is Map && '${item['text'] ?? ''}'.trim().isNotEmpty)
            (
              text: '${item['text']}'.trim(),
              done: item['isDone'] == true || item['done'] == true,
            ),
    ];

    final meta = '${map['metadata'] ?? ''}'.trim();
    final refUrl = meta.startsWith('http://') || meta.startsWith('https://')
        ? meta
        : null;

    return DynamicCanvasCard(
      id: '${map['id'] ?? map['_id'] ?? 'el_$index'}',
      type: type,
      title: title,
      text: text,
      checklist: checklist,
      colorIndex: (map['colorIndex'] as num?)?.toInt() ?? 0,
      referenceUrl: refUrl,
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FullSpacePageData {
  const FullSpacePageData({
    required this.page,
    required this.sections,
    required this.rawSections,
    required this.elements,
    required this.rawElements,
    this.version,
  });

  final SpacePage page;
  final List<StaticPageSection> sections;
  final List<Map<String, dynamic>> rawSections;
  final List<DynamicCanvasCard> elements;
  final List<Map<String, dynamic>> rawElements;
  final int? version;

  factory FullSpacePageData.fromMap(
    Map<String, dynamic> map, {
    String fallbackSpaceId = '',
  }) {
    final page = SpacePage.fromMap(map, fallbackSpaceId: fallbackSpaceId);
    final rawSecs = [
      if (map['sections'] is List)
        for (final s in map['sections'] as List)
          if (s is Map) Map<String, dynamic>.from(s),
    ];
    final sections = [
      for (var i = 0; i < rawSecs.length; i++)
        StaticPageSection.fromMap(rawSecs[i], index: i),
    ];

    final rawEls = [
      if (map['elements'] is List)
        for (final e in map['elements'] as List)
          if (e is Map) Map<String, dynamic>.from(e),
    ];
    final elements = [
      for (var i = 0; i < rawEls.length; i++)
        DynamicCanvasCard.fromMap(rawEls[i], index: i),
    ];

    return FullSpacePageData(
      page: page,
      sections: sections,
      rawSections: rawSecs,
      elements: elements,
      rawElements: rawEls,
      version: (map['version'] as num?)?.toInt(),
    );
  }
}

List<StaticDisplayLine> _linesFromDelta(List<dynamic> delta) {
  final lines = <StaticDisplayLine>[];
  final buf = StringBuffer();
  for (final op in delta) {
    if (op is! Map) continue;
    final insert = op['insert'];
    if (insert is Map) {
      final ref = insert['reference'];
      if (ref is String && ref.isNotEmpty) {
        lines.add(StaticDisplayLine(kind: 'reference', text: ref));
      }
      continue;
    }
    if (insert is! String) continue;
    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      buf.write(parts[i]);
      if (i == parts.length - 1) break;
      final lineText = buf.toString().replaceAll('\uFFFC', '').trim();
      buf.clear();
      final attrs = op['attributes'] is Map ? op['attributes'] as Map : const {};
      final header = attrs['header'];
      final list = '${attrs['list'] ?? ''}';
      if (lineText.isEmpty) continue;
      if (header is num) {
        lines.add(
          StaticDisplayLine(
            kind: 'heading',
            text: lineText,
            headingLevel: header.toInt().clamp(1, 3),
          ),
        );
      } else if (list == 'checked' || list == 'unchecked') {
        lines.add(
          StaticDisplayLine(
            kind: 'checklist',
            text: lineText,
            checked: list == 'checked',
          ),
        );
      } else if (list == 'bullet' || list == 'ordered') {
        lines.add(StaticDisplayLine(kind: 'bullet', text: lineText));
      } else if (attrs['code-block'] == true) {
        lines.add(StaticDisplayLine(kind: 'code', text: lineText));
      } else if (attrs['blockquote'] == true) {
        lines.add(StaticDisplayLine(kind: 'callout', text: lineText));
      } else {
        lines.add(StaticDisplayLine(kind: 'paragraph', text: lineText));
      }
    }
  }
  final tail = buf.toString().trim();
  if (tail.isNotEmpty) {
    lines.add(StaticDisplayLine(kind: 'paragraph', text: tail));
  }
  return lines;
}

List<StaticDisplayLine> _linesFromBlocks(List<dynamic> blocks) {
  final lines = <StaticDisplayLine>[];
  for (final raw in blocks) {
    if (raw is! Map) continue;
    final type = '${raw['type'] ?? 'plainText'}';
    final heading = '${raw['heading'] ?? ''}'.trim();
    final content = '${raw['content'] ?? ''}'.trim();
    final level = ((raw['headingLevel'] as num?)?.toInt() ?? 2).clamp(1, 3);
    if (heading.isNotEmpty) {
      lines.add(
        StaticDisplayLine(
          kind: 'heading',
          text: heading,
          headingLevel: level,
        ),
      );
    }
    if (type == 'checklist' && raw['checkItems'] is List) {
      for (final item in raw['checkItems'] as List) {
        if (item is! Map) continue;
        final t = '${item['text'] ?? ''}'.trim();
        if (t.isNotEmpty) {
          lines.add(
            StaticDisplayLine(
              kind: 'checklist',
              text: t,
              checked: item['isDone'] == true || item['done'] == true,
            ),
          );
        }
      }
    } else if (content.isNotEmpty) {
      final kind = switch (type) {
        'code' => 'code',
        'callout' || 'thoughtNote' => 'callout',
        'reference' => 'reference',
        _ => 'paragraph',
      };
      for (final part in content.split('\n')) {
        if (part.trim().isNotEmpty) {
          lines.add(
            StaticDisplayLine(
              kind: kind,
              text: part.trim(),
              url: '${raw['metadata'] ?? ''}'.trim().startsWith('http')
                  ? '${raw['metadata']}'.trim()
                  : null,
            ),
          );
        }
      }
    }
  }
  return lines;
}

String _plainTextFromDelta(List<dynamic> delta) {
  final buf = StringBuffer();
  for (final op in delta) {
    if (op is Map && op['insert'] is String) {
      buf.write(op['insert'] as String);
    }
  }
  return buf.toString().trim();
}
