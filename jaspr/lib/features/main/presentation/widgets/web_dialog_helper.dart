import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

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

  static void syncOpen(String id, bool shouldBeOpen) {
    final dialog = dialogById(id);
    if (dialog == null) return;
    _installLightDismissFallback(dialog);
    if (shouldBeOpen) {
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

    final ctor = web.window.getProperty<JSObject?>('HTMLDialogElement'.toJS);
    final proto = ctor?.getProperty<JSObject?>('prototype'.toJS);
    if (proto != null && proto.hasProperty('closedBy'.toJS).toDart) return;

    var pressedOutside = false;
    bool isOutside(web.PointerEvent event) {
      final rect = dialog.getBoundingClientRect();
      final x = event.clientX;
      final y = event.clientY;
      return x < rect.left || x > rect.right || y < rect.top || y > rect.bottom;
    }

    dialog.addEventListener(
      'pointerdown',
      ((web.Event raw) {
        pressedOutside = isOutside(raw as web.PointerEvent);
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
