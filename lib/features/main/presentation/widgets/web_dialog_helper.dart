import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Pointer coordinates as doubles. `MouseEvent.clientX/Y` are typed `int` in
/// package:web, but browsers report fractional pixels under display scaling
/// or zoom, which throws a TypeError on access.
double pointerClientX(web.MouseEvent event) => (event as JSObject).getProperty<JSNumber>('clientX'.toJS).toDartDouble;
double pointerClientY(web.MouseEvent event) => (event as JSObject).getProperty<JSNumber>('clientY'.toJS).toDartDouble;

/// Coordinates native `<dialog>.showModal()`, `close()` synchronization, and the
/// `closedby="any"` light-dismiss fallback for browsers lacking native `closedBy`.
abstract final class WebDialogHelper {
  static final _boundFallbacks = Expando<bool>('edumaDialogLightDismiss');

  static web.HTMLDialogElement? dialogById(String id) {
    final element = web.document.getElementById(id);
    if (element != null && element.tagName.toLowerCase() == 'dialog') {
      return element as web.HTMLDialogElement;
    }
    return null;
  }

  /// Spread into a `<dialog>`'s `attributes` so Jaspr keeps the `open`
  /// attribute that `showModal()` sets. Jaspr's element update removes every
  /// DOM attribute missing from the component's attribute map, so without
  /// this the first rebuild after `showModal()` hides the dialog.
  static Map<String, String> openAttr(bool open) => {if (open) 'open': ''};

  static void syncOpen(String id, bool shouldBeOpen) {
    final dialog = dialogById(id);
    if (dialog == null) return;
    _installLightDismissFallback(dialog);
    if (shouldBeOpen) {
      if (dialog.open && !dialog.matches(':modal')) {
        // Jaspr rendered `open` (see [openAttr]) before this ran: promote the
        // non-modal dialog to a modal one in the top layer.
        dialog.removeAttribute('open');
      }
      if (!dialog.open) {
        dialog.returnValue = '';
        dialog.showModal();
      }
    } else {
      if (dialog.open) {
        dialog.close();
      } else if (dialog.matches(':modal')) {
        // Recover if an external DOM patch stripped `open` while `:modal` remained in top layer.
        dialog.showModal();
        dialog.close();
      }
    }
  }

  static void resetReturnValue(String id) {
    final dialog = dialogById(id);
    if (dialog != null) dialog.returnValue = '';
  }

  static void closeDetailsById(String id) {
    final element = web.document.getElementById(id);
    if (element != null && element.tagName.toLowerCase() == 'details') {
      (element as web.HTMLDetailsElement).open = false;
    }
  }

  static void _installLightDismissFallback(web.HTMLDialogElement dialog) {
    if (_boundFallbacks[dialog] == true) return;
    _boundFallbacks[dialog] = true;

    var pressedOutside = false;
    bool isOutside(web.PointerEvent event) {
      final rect = dialog.getBoundingClientRect();
      final x = pointerClientX(event);
      final y = pointerClientY(event);
      return x < rect.left || x > rect.right || y < rect.top || y > rect.bottom;
    }

    dialog.addEventListener(
      'keydown',
      ((web.Event raw) {
        final keyboard = raw as web.KeyboardEvent;
        if (keyboard.key == 'Escape' && dialog.open) {
          keyboard.preventDefault();
          dialog.close();
        }
      }).toJS,
    );
    dialog.addEventListener(
      'pointerdown',
      ((web.Event raw) {
        final pointer = raw as web.PointerEvent;
        pressedOutside = dialog.open && isOutside(pointer);
      }).toJS,
    );
    dialog.addEventListener(
      'pointerup',
      ((web.Event raw) {
        final pointer = raw as web.PointerEvent;
        if (pressedOutside && isOutside(pointer) && dialog.open) {
          dialog.close();
        }
        pressedOutside = false;
      }).toJS,
    );
  }
}
