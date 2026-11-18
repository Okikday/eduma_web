import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import 'eduma_link.dart';

/// Floating-page widths from `DesktopWidths` in `../eduma`.
abstract final class FloatingWidths {
  /// Floating pages with lists / grids (see-all, streak).
  static const page = 880;

  /// Floating pages that read like a column (notifications, AI chats).
  static const narrow = 640;
}

/// The last full screen shown, so a floating page can draw it underneath
/// (and close back to it when opened directly from a link).
abstract final class FloatingRouteMemory {
  static String lastScreen = '/main';
}

/// Web port of the source's desktop popup pages (`AdaptivePage` →
/// `DesktopPopupFrame`): the page floats centred over the screen it was
/// opened from, at most [maxWidth] wide and 940 tall with a 32px margin.
///
/// Closes (back to that screen) from the page's own back button, Esc, or a
/// click on the dimmed backdrop. Below the wide breakpoint it fills the
/// window, like the phone layout.
class FloatingRoutePage extends StatefulComponent {
  const FloatingRoutePage({
    required this.background,
    required this.maxWidth,
    required this.child,
    super.key,
  });

  /// The screen underneath (inert while the page floats).
  final Component background;
  final int maxWidth;
  final Component child;

  @override
  State<FloatingRoutePage> createState() => _FloatingRoutePageState();
}

class _FloatingRoutePageState extends State<FloatingRoutePage> {
  JSFunction? _keyListener;

  @override
  void initState() {
    super.initState();
    final listener = ((web.KeyboardEvent event) {
      if (event.key != 'Escape' || event.defaultPrevented) return;
      // A dialog inside the page handles its own Escape first.
      if (web.document.querySelector('dialog[open]') != null) return;
      _close();
    }).toJS;
    _keyListener = listener;
    web.document.addEventListener('keydown', listener);
  }

  @override
  void dispose() {
    final listener = _keyListener;
    if (listener != null) web.document.removeEventListener('keydown', listener);
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    edumaBack(context, fallbackHref: FloatingRouteMemory.lastScreen);
  }

  @override
  Component build(BuildContext context) => div(classes: 'eduma-floating-route', [
    div(
      classes: 'eduma-floating-route__background',
      attributes: {'inert': '', 'aria-hidden': 'true'},
      [component.background],
    ),
    div(classes: 'eduma-floating-route__layer', [
      button(
        classes: 'eduma-floating-route__barrier',
        type: ButtonType.button,
        attributes: {'aria-label': 'Close', 'tabindex': '-1'},
        onClick: _close,
        [],
      ),
      div(
        classes: 'eduma-floating-route__frame',
        attributes: {'role': 'dialog', 'aria-modal': 'true'},
        styles: Styles(raw: {'--eduma-floating-width': '${component.maxWidth}px'}),
        [component.child],
      ),
    ]),
  ]);
}
