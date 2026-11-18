import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../features/main/presentation/widgets/web_dialog_helper.dart';
import 'eduma_icons.dart';

/// Web port of a source bottom sheet shown as a desktop sheet dialog
/// (`AppBottomSheet` → `DesktopSheetDialog`): grip, title / subtitle,
/// optional header actions, a scrolling body and an optional footer.
///
/// A native modal `<dialog>`: Escape, a click on the backdrop and the close
/// button all close it through [onClose].
class EdumaSheetDialog extends StatefulComponent {
  const EdumaSheetDialog({
    required this.id,
    required this.open,
    required this.title,
    required this.onClose,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.footer = const [],
    this.showClose = true,
    super.key,
  });

  final String id;
  final bool open;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  /// Header buttons beside the title (e.g. Invite).
  final List<Component> actions;
  final List<Component> body;

  /// Footer buttons (`eduma-modal__btn`), full width like `AppSheetFooter`.
  final List<Component> footer;

  /// The source shows a close button on list sheets that scroll.
  final bool showClose;

  @override
  State<EdumaSheetDialog> createState() => _EdumaSheetDialogState();
}

class _EdumaSheetDialogState extends State<EdumaSheetDialog> {
  String get _titleId => '${component.id}-title';

  @override
  void initState() {
    super.initState();
    WebDialogHelper.syncOpen(component.id, component.open);
  }

  @override
  void didUpdateComponent(covariant EdumaSheetDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    WebDialogHelper.syncOpen(component.id, component.open);
  }

  void _dismiss() {
    WebDialogHelper.resetReturnValue(component.id);
    component.onClose();
  }

  @override
  Component build(BuildContext context) => dialog(
    id: component.id,
    classes: 'eduma-modal eduma-modal--list',
    attributes: {
      ...WebDialogHelper.openAttr(component.open),
      'closedby': 'any',
      'aria-labelledby': _titleId,
    },
    events: {
      'close': (_) {
        if (component.open) _dismiss();
      },
    },
    [
      div(classes: 'eduma-modal__header', [
        div(classes: 'eduma-modal__title', [
          h2(id: _titleId, [.text(component.title)]),
          if (component.subtitle case final subtitle?) p([.text(subtitle)]),
        ]),
        if (component.actions.isNotEmpty || component.showClose)
          div(classes: 'eduma-modal__header-actions', [
            ...component.actions,
            if (component.showClose)
              button(
                classes: 'eduma-modal__close-btn',
                type: ButtonType.button,
                attributes: {'aria-label': 'Close', 'title': 'Close'},
                onClick: _dismiss,
                [edumaIcon(EdumaIcons.closePlain, size: 16)],
              ),
          ]),
      ]),
      // Only built while open, so lists don't render behind a closed dialog.
      div(classes: 'eduma-modal__body eduma-modal__body--list', component.open ? component.body : const []),
      if (component.footer.isNotEmpty) div(classes: 'eduma-modal__footer', component.footer),
    ],
  );
}
