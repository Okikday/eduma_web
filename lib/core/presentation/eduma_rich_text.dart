import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Parses inline `**bold**` markers into `strong` spans while stripping
/// unbalanced `**` tokens cleanly.
List<Component> edumaRichInlineSpans(String input) {
  final pattern = RegExp(r'\*\*(.+?)\*\*|\[([^\]]+)\]\(([^)]+)\)');
  final matches = pattern.allMatches(input).toList();
  if (matches.isEmpty) {
    return [.text(input.replaceAll('**', ''))];
  }
  final out = <Component>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start > cursor) {
      out.add(.text(input.substring(cursor, match.start).replaceAll('**', '')));
    }
    final bold = match.group(1);
    if (bold != null) {
      out.add(strong([.text(bold)]));
    } else {
      final label = match.group(2) ?? '';
      final uri = Uri.tryParse(match.group(3) ?? '');
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'mailto')) {
        out.add(
          a(
            href: uri.toString(),
            attributes: {
              if (uri.scheme == 'https') 'target': '_blank',
              if (uri.scheme == 'https') 'rel': 'noopener noreferrer',
            },
            [.text(label)],
          ),
        );
      } else {
        out.add(.text(label));
      }
    }
    cursor = match.end;
  }
  if (cursor < input.length) {
    out.add(.text(input.substring(cursor).replaceAll('**', '')));
  }
  return out;
}

/// Renders basic Markdown (`#` headings, tables, ordered/unordered lists,
/// inline `**bold**`) for AI responses without HTML injection.
List<Component> edumaRenderMarkdownBlocks(String markdown) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final out = <Component>[];
  var i = 0;

  while (i < lines.length) {
    final trimmed = lines[i].trim();
    if (trimmed.isEmpty) {
      i++;
      continue;
    }

    if (trimmed.startsWith('>')) {
      final quote = <String>[];
      while (i < lines.length && lines[i].trim().startsWith('>')) {
        quote.add(lines[i].trim().substring(1).trim());
        i++;
      }
      out.add(blockquote([for (final line in quote) p(edumaRichInlineSpans(line))]));
      continue;
    }

    if (trimmed.startsWith('|') && i + 1 < lines.length && _isTableSeparator(lines[i + 1].trim())) {
      final headers = _splitTableRow(trimmed);
      i += 2;
      final rows = <List<String>>[];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        rows.add(_splitTableRow(lines[i].trim()));
        i++;
      }
      out.add(
        div(classes: 'ai-history__md-table-wrap', [
          table(classes: 'ai-history__md-table', [
            thead([
              tr([
                for (final cell in headers) th(edumaRichInlineSpans(cell)),
              ]),
            ]),
            tbody([
              for (final row in rows)
                tr([
                  for (var c = 0; c < headers.length; c++) td(edumaRichInlineSpans(c < row.length ? row[c] : '')),
                ]),
            ]),
          ]),
        ]),
      );
      continue;
    }

    final headingMatch = RegExp(r'^#{1,6}\s+(.+)$').firstMatch(trimmed);
    if (headingMatch != null) {
      out.add(
        h4(
          classes: 'ai-history__md-heading',
          edumaRichInlineSpans(headingMatch.group(1) ?? ''),
        ),
      );
      i++;
      continue;
    }

    if (RegExp(r'^([-*]|\d+\.)\s+').hasMatch(trimmed)) {
      final isOrdered = RegExp(r'^\d+\.\s+').hasMatch(trimmed);
      final items = <Component>[];
      while (i < lines.length) {
        final lineTrim = lines[i].trim();
        final match = RegExp(r'^(?:[-*]|\d+\.)\s+(.+)$').firstMatch(lineTrim);
        if (match == null) break;
        items.add(li(edumaRichInlineSpans(match.group(1) ?? '')));
        i++;
      }
      out.add(
        isOrdered ? ol(classes: 'ai-history__md-list', items) : ul(classes: 'ai-history__md-list', items),
      );
      continue;
    }

    out.add(p(edumaRichInlineSpans(trimmed)));
    i++;
  }

  return out;
}

bool _isTableSeparator(String line) => line.startsWith('|') && RegExp(r'^[\|\s:\-]+$').hasMatch(line);

List<String> _splitTableRow(String line) {
  var core = line.trim();
  if (core.startsWith('|')) core = core.substring(1);
  if (core.endsWith('|')) core = core.substring(0, core.length - 1);
  return [for (final part in core.split('|')) part.trim()];
}
