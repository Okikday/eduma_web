import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../features/main/presentation/widgets/web_dialog_helper.dart';

/// Web port of `AppDialog.confirm` in `../eduma`: a title over a muted
/// message, then a tonal Cancel and a filled (red when [destructive]) confirm
/// button side by side.
///
/// [onConfirm] runs while the dialog shows a busy confirm button; the dialog
/// closes once it completes. When it throws, the error's message is shown and
/// the dialog stays open for a retry, like the source.
class EdumaConfirmDialog extends StatefulComponent {
  const EdumaConfirmDialog({
    required this.id,
    required this.open,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onClose,
    this.onConfirm,
    this.onConfirmWithOption,
    this.optionLabel,
    this.optionSubtitle,
    this.optionDefault = false,
    this.onConfirmed,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    super.key,
  });

  final String id;
  final bool open;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  /// The confirmed action. The dialog stays open (busy) until it completes.
  final Future<void> Function()? onConfirm;

  /// Like [onConfirm], receiving the option tile's value (see [optionLabel]).
  final Future<void> Function(bool option)? onConfirmWithOption;

  /// Optional checkbox tile under the message (`AppDialogOption` in the source).
  final String? optionLabel;
  final String? optionSubtitle;
  final bool optionDefault;

  /// Called after [onConfirm] succeeds and the dialog has closed.
  final VoidCallback? onConfirmed;

  /// Called whenever the dialog closes (cancel, Escape, barrier, success).
  final VoidCallback onClose;

  @override
  State<EdumaConfirmDialog> createState() => _EdumaConfirmDialogState();
}

class _EdumaConfirmDialogState extends State<EdumaConfirmDialog> {
  bool _busy = false;
  bool _option = false;
  String? _error;

  String get _titleId => '${component.id}-title';

  @override
  void initState() {
    super.initState();
    _option = component.optionDefault;
    WebDialogHelper.syncOpen(component.id, component.open);
  }

  @override
  void didUpdateComponent(covariant EdumaConfirmDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!oldComponent.open && component.open) {
      _busy = false;
      _error = null;
      _option = component.optionDefault;
    }
    WebDialogHelper.syncOpen(component.id, component.open);
  }

  void _dismiss() {
    if (_busy) return;
    WebDialogHelper.resetReturnValue(component.id);
    component.onClose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final withOption = component.onConfirmWithOption;
    final Future<void> Function()? action = withOption != null ? () => withOption(_option) : component.onConfirm;
    if (action != null) {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        await action();
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = _messageOf(error);
        });
        return;
      }
      if (!mounted) return;
      setState(() => _busy = false);
    }
    WebDialogHelper.resetReturnValue(component.id);
    component.onClose();
    component.onConfirmed?.call();
  }

  static String _messageOf(Object error) {
    try {
      final message = (error as dynamic).message;
      if (message is String && message.trim().isNotEmpty) return message;
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }

  @override
  Component build(BuildContext context) => dialog(
    id: component.id,
    classes: 'eduma-modal eduma-modal--confirm',
    attributes: {
      ...WebDialogHelper.openAttr(component.open),
      'closedby': _busy ? 'none' : 'any',
      'role': 'alertdialog',
      'aria-labelledby': _titleId,
    },
    events: {
      'close': (_) {
        if (component.open) _dismiss();
      },
    },
    [
      div(classes: 'eduma-modal__confirm', [
        h2(id: _titleId, [.text(component.title)]),
        p([.text(component.message)]),
        if (component.optionLabel case final optionLabel?)
          label(classes: 'eduma-modal__option', [
            input<bool>(
              type: InputType.checkbox,
              checked: _option,
              disabled: _busy,
              onChange: (value) => setState(() => _option = value),
            ),
            span(classes: 'eduma-modal__option-text', [
              strong([.text(optionLabel)]),
              if (component.optionSubtitle case final sub?) span([.text(sub)]),
            ]),
          ]),
        if (_error case final message?)
          p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(message)]),
        div(classes: 'eduma-modal__confirm-actions', [
          button(
            classes: 'eduma-modal__btn eduma-modal__btn--tonal',
            type: ButtonType.button,
            disabled: _busy,
            onClick: _dismiss,
            [.text(component.cancelLabel)],
          ),
          button(
            classes: component.destructive
                ? 'eduma-modal__btn eduma-modal__btn--danger'
                : 'eduma-modal__btn eduma-modal__btn--primary',
            type: ButtonType.button,
            disabled: _busy,
            attributes: {if (_busy) 'aria-busy': 'true'},
            onClick: () => unawaited(_confirm()),
            [.text(_busy ? '${component.confirmLabel}…' : component.confirmLabel)],
          ),
        ]),
      ]),
    ],
  );
}
