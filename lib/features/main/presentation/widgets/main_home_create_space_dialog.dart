import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/data/auth_api.dart';
import '../../data/main_space.dart';
import '../../logic/main_actions.dart';
import 'main_home_icons.dart';
import 'web_dialog_helper.dart';

/// Native `<dialog>` modal matching `../eduma`'s Create Space manual setup flow.
class MainHomeCreateSpaceDialog extends StatefulComponent {
  const MainHomeCreateSpaceDialog({
    required this.open,
    required this.currentUserId,
    required this.onClose,
    required this.onCreated,
    super.key,
  });

  final bool open;
  final String currentUserId;
  final VoidCallback onClose;
  final ValueChanged<MainSpace?> onCreated;

  @override
  State<MainHomeCreateSpaceDialog> createState() => _MainHomeCreateSpaceDialogState();
}

class _MainHomeCreateSpaceDialogState extends State<MainHomeCreateSpaceDialog> {
  static const _dialogId = 'main-home-create-space-dialog';

  String _title = '';
  String _description = '';
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncDialog);
  }

  @override
  void didUpdateComponent(covariant MainHomeCreateSpaceDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.open && !oldComponent.open) {
      _title = '';
      _description = '';
      _error = null;
      _submitting = false;
    }
    if (component.open != oldComponent.open) {
      Future<void>.microtask(_syncDialog);
    }
  }

  void _syncDialog() {
    if (mounted) WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  void _handleNativeClose() {
    WebDialogHelper.resetReturnValue(_dialogId);
    if (component.open) component.onClose();
  }

  Future<void> _submit() async {
    final title = _title.trim();
    if (title.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await MainActions.createSpace(
        title: title,
        description: _description,
        currentUserId: component.currentUserId,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      component.onCreated(created);
      component.onClose();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    }
  }

  @override
  Component build(BuildContext context) => dialog(
    id: _dialogId,
    classes: 'eduma-modal',
    attributes: {
      ...WebDialogHelper.openAttr(component.open),
      'aria-labelledby': 'create-space-title',
      'closedby': 'any',
    },
    events: {'close': (_) => _handleNativeClose()},
    [
      div(classes: 'eduma-modal__header', [
        div(classes: 'eduma-modal__heading', [
          h2(id: 'create-space-title', [.text('Create Space')]),
          p([.text('Start a collaborative hub for your peers & projects')]),
        ]),
        button(
          classes: 'eduma-modal__close',
          type: ButtonType.button,
          attributes: {'aria-label': 'Close Create Space dialog'},
          onClick: component.onClose,
          [mainHomeIcon(.close, size: 18)],
        ),
      ]),
      form(
        events: {
          'submit': (event) {
            event.preventDefault();
            unawaited(_submit());
          },
        },
        [
          div(classes: 'eduma-modal__body', [
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'create-space-title-input', [.text('Space name')]),
              input<String>(
                id: 'create-space-title-input',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _title,
                disabled: _submitting,
                attributes: {
                  'required': 'true',
                  'maxlength': '80',
                  'placeholder': 'e.g. Organic Chemistry',
                  'autofocus': 'true',
                },
                onInput: (value) => setState(() {
                  _title = value;
                  _error = null;
                }),
              ),
            ]),
            div(classes: 'eduma-modal__field', [
              label(
                htmlFor: 'create-space-desc-input',
                [.text('Description (optional)')],
              ),
              textarea(
                id: 'create-space-desc-input',
                classes: 'eduma-modal__textarea',
                disabled: _submitting,
                attributes: {
                  'maxlength': '240',
                  'placeholder': 'What is this space for?',
                },
                onInput: (value) => setState(() => _description = value),
                [.text(_description)],
              ),
            ]),
            p(classes: 'eduma-modal__hint', [
              .text('Invite people from the space once it’s ready.'),
            ]),
            if (_error case final message?)
              p(
                classes: 'eduma-modal__error',
                attributes: {'role': 'alert'},
                [.text(message)],
              ),
          ]),
          div(classes: 'eduma-modal__footer', [
            button(
              classes: 'eduma-modal__btn eduma-modal__btn--primary',
              type: ButtonType.submit,
              disabled: _title.trim().isEmpty || _submitting,
              [.text(_submitting ? 'Creating…' : 'Create Space')],
            ),
          ]),
        ],
      ),
    ],
  );
}
