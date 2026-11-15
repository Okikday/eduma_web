import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

bool _isPlainPrimaryClick(web.Event rawEvent) {
  if (!rawEvent.isA<web.MouseEvent>()) return true;
  final event = rawEvent as web.MouseEvent;
  return event.button == 0 &&
      !event.metaKey &&
      !event.ctrlKey &&
      !event.shiftKey &&
      !event.altKey;
}

/// Client-side SPA anchor using [Router] when available while preserving
/// normal `<a href>` semantics, modifier-click open-in-new-tab, and context menu.
Component edumaLink({
  required String to,
  String? classes,
  Map<String, String>? attributes,
  VoidCallback? onClick,
  EventCallback? onContextMenu,
  Target? target,
  required List<Component> children,
}) => Builder(
  builder: (context) {
    final basePath = context.binding.basePath;
    final prefix = basePath.endsWith('/') ? basePath.substring(0, basePath.length - 1) : basePath;
    final resolvedHref = to.startsWith('/') && !to.startsWith('//') ? '$prefix$to' : to;

    return a(
      href: resolvedHref,
      target: target,
      classes: classes,
      attributes: attributes,
      events: {
        'click': (event) {
          onClick?.call();
          if (target == Target.blank) return;
          if (!to.startsWith('/') || to.startsWith('//')) return;
          if (!_isPlainPrimaryClick(event)) return;
          final router = Router.maybeOf(context);
          if (router != null) {
            event.preventDefault();
            router.push(to);
          }
        },
        if (onContextMenu != null) 'contextmenu': onContextMenu,
      },
      children,
    );
  },
);

/// Navigates via [Router] without a full page reload when inside an active router.
void edumaNavigate(
  BuildContext context,
  String to, {
  bool replace = false,
}) {
  final router = Router.maybeOf(context);
  if (router != null && to.startsWith('/') && !to.startsWith('//')) {
    if (replace) {
      router.replace(to);
    } else {
      router.push(to);
    }
    return;
  }
  web.window.location.assign(to);
}
