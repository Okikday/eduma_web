import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

String flutterEmbeddedRouteUrl(String route) => Uri(
  path: '/flutter/index.html',
  queryParameters: {'edumaRoute': route},
).toString();

Component flutterEmbeddedPage({
  required String title,
  required String route,
}) => main_(
  classes: 'eduma-flutter-embedded',
  [
    iframe(
      src: flutterEmbeddedRouteUrl(route),
      classes: 'eduma-flutter-embedded__frame',
      loading: .eager,
      attributes: {'title': title},
      const [],
    ),
  ],
);
