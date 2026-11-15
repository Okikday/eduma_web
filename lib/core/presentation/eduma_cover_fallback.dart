import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Soft gradient wash + tinted Eduma brand mark used wherever a space cover
/// image is missing or loading, mirroring Flutter's `EdumaCoverFallback`.
Component edumaCoverFallback({
  String tint = 'var(--eduma-primary)',
  String classes = '',
  int logoPercent = 50,
}) => span(
  classes: classes.isEmpty ? 'eduma-cover-fallback' : 'eduma-cover-fallback $classes',
  attributes: {
    'aria-hidden': 'true',
    'style': '--eduma-fallback-tint: $tint; --eduma-fallback-logo-size: $logoPercent%;',
  },
  [
    span(classes: 'eduma-cover-fallback__mark', []),
  ],
);

