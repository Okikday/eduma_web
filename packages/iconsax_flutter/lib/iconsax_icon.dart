import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'src/icon_data.dart';

class IconsaxIcon extends StatelessComponent {
  const IconsaxIcon({required this.icon, this.size = 20, this.label});

  final IconData icon;
  final int size;
  final String? label;

  @override
  Component build(BuildContext context) => span(
    classes: 'eduma-icon eduma-iconsax',
    attributes: {
      'style': 'font-size: ${size}px',
      if (label case final text?) 'aria-label': text,
      if (label == null) 'aria-hidden': 'true',
    },
    [Component.text(String.fromCharCode(icon.codePoint))],
  );
}
