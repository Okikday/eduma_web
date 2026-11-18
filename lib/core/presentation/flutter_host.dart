import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// One long-lived Flutter app (the `../eduma` web build under `/flutter/`)
/// shared by every embedded view: Canvas, Notes and the new AI chat.
///
/// The iframe lives directly under `<body>`, outside the Jaspr tree, so it
/// survives route changes. [warmUp] boots it once in idle time after sign-in,
/// parked on the source's blank, transparent `/embedHost` route; every later
/// [open] only routes that running app (no reload) and reveals it.
///
/// Protocol (same-origin `postMessage`, see `WebEmbedBridge` in the source):
/// - host → app: `eduma:open {location}`, `eduma:reset`.
/// - app → host: `eduma:ready`, then `eduma:location {location}` on every
///   navigation. Back on `/embedHost` closes the view; any other location
///   that isn't an embedded screen is handed to the Jaspr router.
abstract final class FlutterHost {
  static const _base = '/embedHost';
  static const _embeddedPaths = {'/spacePageCanvas', '/spacePageStatic', '/assistantNewChat', _base};

  static web.HTMLIFrameElement? _frame;
  static bool _ready = false;
  static bool _listening = false;
  static String? _pending;
  static bool _visible = false;
  static bool _reachedScreen = false;
  static int _owner = 0;
  static void Function()? _onClose;
  static void Function(String location)? _onNavigate;
  static final _readyListeners = <void Function()>[];

  /// Whether the embedded app has booted and can be routed instantly.
  static bool get isReady => _ready;

  /// Runs [listener] once the app is ready (immediately when it already is).
  static void whenReady(void Function() listener) {
    if (_ready) {
      listener();
    } else {
      _readyListeners.add(listener);
    }
  }

  /// Boots the shared app in the background when the browser is idle.
  /// Safe to call often; only the first call does anything.
  static void scheduleWarmUp() {
    if (_frame != null) return;
    void boot() => warmUp();
    try {
      web.window.requestIdleCallback(((web.IdleDeadline _) => boot()).toJS, web.IdleRequestOptions(timeout: 4000));
    } catch (_) {
      Timer(const Duration(milliseconds: 1500), boot);
    }
  }

  /// Boots the shared app now (hidden), if it isn't already.
  static void warmUp() {
    if (_frame != null) return;
    _listen();
    final frame = web.document.createElement('iframe') as web.HTMLIFrameElement;
    frame.src = Uri(path: '/flutter/index.html', queryParameters: {'edumaRoute': _base}).toString();
    frame.className = 'eduma-flutter-host';
    frame.title = 'Eduma';
    frame.setAttribute('aria-hidden', 'true');
    frame.setAttribute('tabindex', '-1');
    frame.setAttribute('allow', 'clipboard-read; clipboard-write; microphone; fullscreen');
    web.document.body?.append(frame);
    _frame = frame;
  }

  /// Shows [location] (an embedded screen) over the page.
  ///
  /// [onClose] runs when the user leaves the screen inside the app (its back
  /// button, closing the AI sheet); [onNavigate] when the app moves to a
  /// screen the Jaspr app renders itself (a space, AI chats, Home …).
  /// Returns a token for [hide], so a view leaving after another one opened
  /// doesn't hide the newer view.
  static int open(
    String location, {
    required void Function() onClose,
    required void Function(String location) onNavigate,
  }) {
    warmUp();
    final owner = ++_owner;
    _onClose = onClose;
    _onNavigate = onNavigate;
    _reachedScreen = false;
    _setVisible(true);
    if (_ready) {
      _post({'type': 'eduma:open', 'location': location});
    } else {
      _pending = location;
    }
    return owner;
  }

  /// Hides the app and parks it back on its blank base for the next [open].
  /// With an [owner] token from [open], only hides if that view still owns it.
  static void hide([int? owner]) {
    if (owner != null && owner != _owner) return;
    _onClose = null;
    _onNavigate = null;
    _pending = null;
    if (!_visible) return;
    _setVisible(false);
    if (_ready) _post({'type': 'eduma:reset'});
  }

  /// Removes the app (sign-out): the next session boots a fresh one.
  static void dispose() {
    hide();
    _frame?.remove();
    _frame = null;
    _ready = false;
    _readyListeners.clear();
  }

  static void _setVisible(bool visible) {
    _visible = visible;
    final frame = _frame;
    if (frame == null) return;
    frame.classList.toggle('is-visible', visible);
    if (visible) {
      frame.removeAttribute('aria-hidden');
      frame.removeAttribute('tabindex');
      // Keyboard focus follows the view (Esc, shortcuts inside the editor).
      Timer(const Duration(milliseconds: 50), () => frame.focus());
    } else {
      frame.setAttribute('aria-hidden', 'true');
      frame.setAttribute('tabindex', '-1');
    }
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    web.window.addEventListener(
      'message',
      ((web.MessageEvent event) {
        final frame = _frame;
        if (frame == null || event.origin != web.window.location.origin) return;
        if (event.source != frame.contentWindow) return;
        final data = event.data.dartify();
        if (data is! Map) return;
        switch (data['type']) {
          case 'eduma:ready':
            _ready = true;
            final pending = _pending;
            _pending = null;
            if (pending != null && _visible) _post({'type': 'eduma:open', 'location': pending});
            for (final listener in List.of(_readyListeners)) {
              listener();
            }
            _readyListeners.clear();
          case 'eduma:location':
            final location = data['location'];
            if (location is String) _onLocation(location);
        }
      }).toJS,
    );
  }

  static void _onLocation(String location) {
    if (!_visible) return;
    final path = Uri.tryParse(location)?.path ?? '';
    if (path == _base) {
      // Back on the base after showing a screen: the user left it.
      if (_reachedScreen) _onClose?.call();
      return;
    }
    if (_embeddedPaths.contains(path)) {
      _reachedScreen = true;
      return;
    }
    // e.g. a space, AI chats or Home: the Jaspr app owns those screens.
    _onNavigate?.call(location);
  }

  static void _post(Map<String, String> message) {
    final target = _frame?.contentWindow;
    target?.postMessage(message.jsify(), web.window.location.origin.toJS);
  }
}
