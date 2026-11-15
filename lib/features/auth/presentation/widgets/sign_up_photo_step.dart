import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import 'auth_frame.dart';

/// Step 3 (optional) of sign-up: profile photo preview + picker matching `PhotoStep`.
Component signUpPhotoStep({
  required String name,
  required String? photoDataUrl,
  required bool busy,
  required String? error,
  required ValueChanged<String> onPhotoSelected,
  required VoidCallback onRemovePhoto,
}) {
  const inputId = 'auth-sign-up-photo-input';
  void openPicker() {
    final el = web.document.getElementById(inputId);
    if (el != null && el.isA<web.HTMLInputElement>()) {
      (el as web.HTMLInputElement).click();
    }
  }

  final hasPhoto = photoDataUrl != null && photoDataUrl.isNotEmpty;
  final initials = _initialsFor(name);

  return div(classes: 'auth-step-content auth-photo-step', [
    if (error != null) div(classes: 'auth-step-error', [authError(error)]),
    input<String>(
      id: inputId,
      classes: 'auth-hidden-input',
      type: InputType.file,
      value: '',
      attributes: {'accept': 'image/*'},
      events: {
        'change': (event) {
          final target = event.target;
          if (target == null || !target.isA<web.HTMLInputElement>()) return;
          final inputEl = target as web.HTMLInputElement;
          final files = inputEl.files;
          if (files == null || files.length == 0) return;
          final file = files.item(0);
          if (file == null) return;
          final reader = web.FileReader();
          reader.onload = ((web.Event _) {
            final result = reader.result;
            if (result != null && result.isA<JSString>()) {
              onPhotoSelected((result as JSString).toDart);
            }
            inputEl.value = '';
          }).toJS;
          reader.readAsDataURL(file);
        },
      },
    ),
    button(
      type: ButtonType.button,
      classes: 'auth-photo-preview',
      disabled: busy,
      attributes: {'aria-label': hasPhoto ? 'Choose another photo' : 'Choose a photo'},
      onClick: openPicker,
      [
        span(classes: 'auth-photo-circle', [
          if (hasPhoto)
            img(src: photoDataUrl, alt: 'Selected profile photo')
          else
            span(classes: 'auth-photo-initials', [.text(initials)]),
          if (busy) span(classes: 'auth-photo-busy', [span(classes: 'auth-spinner', [])]),
        ]),
        span(classes: 'auth-photo-camera-badge', attributes: {'aria-hidden': 'true'}, [
          authIcon('camera', size: 18),
        ]),
      ],
    ),
    div(classes: 'auth-photo-actions', [
      button(
        type: ButtonType.button,
        classes: 'auth-secondary-button',
        disabled: busy,
        onClick: openPicker,
        [
          authIcon('gallery-add', size: 18),
          .text(hasPhoto ? 'Choose another photo' : 'Choose a photo'),
        ],
      ),
      if (hasPhoto)
        button(
          type: ButtonType.button,
          classes: 'auth-photo-remove',
          disabled: busy,
          onClick: onRemovePhoto,
          [.text('Remove photo')],
        ),
    ]),
    p(classes: 'auth-photo-note', [
      .text("It's added to your profile after you confirm your email."),
    ]),
  ]);
}

String _initialsFor(String rawName) {
  final parts = rawName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}
