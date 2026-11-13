import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'icon_data.dart';

class HugeIcon extends StatelessComponent {
  const HugeIcon({
    required this.icon,
    this.size = 20,
    this.label,
  });

  final IconData icon;
  final int size;
  final String? label;

  @override
  Component build(BuildContext context) {
    final family = icon.fontFamily == 'HugeIconsSolid' ? 'eduma-huge-solid' : 'eduma-huge-stroke';
    return span(
      classes: 'eduma-icon $family',
      attributes: {
        'style': 'font-size: ${size}px',
        if (label case final text?) 'aria-label': text,
        if (label == null) 'aria-hidden': 'true',
      },
      [Component.text(String.fromCharCode(icon.codePoint))],
    );
  }
}
