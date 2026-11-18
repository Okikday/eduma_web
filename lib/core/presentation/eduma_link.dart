import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

/// Counts navigations pushed inside this app (vs. the page the tab opened
/// on), so "back" can return to the previous in-app screen instead of
/// leaving the site, and fall back to a sensible screen otherwise.
abstract final class EdumaHistory {
  static int _depth = 0;
  static bool _listening = false;

  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    // Browser back/forward: assume back (the common case) so the count never
    // claims history that isn't there.
    web.window.addEventListener(
      'popstate',
      ((web.Event _) {
        if (_depth > 0) _depth--;
      }).toJS,
    );
  }

  static void markPush() {
    _ensureListening();
    _depth++;
  }

  /// Whether a browser "back" stays inside this app.
  static bool get canGoBack => _depth > 0;
}

/// Goes back to the previous in-app screen, or to [fallbackHref].
void edumaBack(BuildContext context, {String fallbackHref = '/main'}) {
  if (EdumaHistory.canGoBack) {
    web.window.history.back();
  } else {
    edumaNavigate(context, fallbackHref, replace: true);
  }
}

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
            EdumaHistory.markPush();
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
      EdumaHistory.markPush();
      router.push(to);
    }
    return;
  }
  web.window.location.assign(to);
}
