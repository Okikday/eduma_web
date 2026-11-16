import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../logic/library_actions.dart';

/// Modal to create a book group (`/library/groups`).
class LibraryNewGroupModal extends StatefulComponent {
  const LibraryNewGroupModal({
    required this.open,
    required this.onClose,
    required this.onCreated,
    super.key,
  });

  final bool open;
  final VoidCallback onClose;
  final ValueChanged<LibraryGroup> onCreated;

  @override
  State<LibraryNewGroupModal> createState() => _LibraryNewGroupModalState();
}

class _LibraryNewGroupModalState extends State<LibraryNewGroupModal> {
  String _name = '';
  LibraryGroupTint _tint = .brand;
  bool _saving = false;
  String? _error;

  @override
  void didUpdateComponent(covariant LibraryNewGroupModal oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!oldComponent.open && component.open) {
      setState(() {
        _name = '';
        _tint = .brand;
        _saving = false;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final clean = _name.trim();
    if (clean.isEmpty) {
      setState(() => _error = 'Enter a group name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = 'grp_${DateTime.now().millisecondsSinceEpoch}';
      final created = await LibraryActions.saveGroup(id: id, name: clean, tint: _tint);
      if (!mounted) return;
      component.onCreated(created ?? LibraryGroup(id: id, name: clean, tint: _tint));
      component.onClose();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save group on server. Keep using Library and retry later.';
        _saving = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    if (!component.open) return div([]);
    return div(classes: 'eduma-modal-backdrop', [
      button(
        classes: 'eduma-modal-backdrop__scrim',
        type: ButtonType.button,
        attributes: {'aria-label': 'Close new group dialog'},
        onClick: component.onClose,
        [],
      ),
      section(
        classes: 'eduma-modal-sheet eduma-library-modal',
        attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': 'New book group'},
        [
          div(classes: 'eduma-library-modal__head', [
            h2([.text('New group')]),
            button(
              classes: 'eduma-modal-close',
              type: ButtonType.button,
              attributes: {'aria-label': 'Close'},
              onClick: component.onClose,
              [edumaIcon(EdumaIcons.closePlain, size: 18)],
            ),
          ]),
          label(classes: 'eduma-library-modal__field', [
            span([.text('Group name')]),
            input<String>(
              type: InputType.text,
              value: _name,
              attributes: {'placeholder': 'e.g. Anatomy Semester 1', 'maxlength': '60'},
              onInput: (val) => setState(() => _name = val),
            ),
          ]),
          div(classes: 'eduma-library-modal__group', [
            span(classes: 'eduma-library-modal__section-label', [.text('CARD COLOR')]),
            div(classes: 'eduma-library-modal__swatches', [
              for (final swatch in LibraryGroupTint.values)
                button(
                  classes: swatch == _tint ? 'eduma-swatch is-active' : 'eduma-swatch',
                  type: ButtonType.button,
                  attributes: {
                    'aria-label': swatch.label,
                    'title': swatch.label,
                    'style': '--swatch: ${swatch.startHex};',
                  },
                  onClick: () => setState(() => _tint = swatch),
                  [if (swatch == _tint) edumaIcon(EdumaIcons.check, size: 14)],
                ),
            ]),
          ]),
          if (_error case final msg?) p(classes: 'eduma-library-modal__error', [.text(msg)]),
          div(classes: 'eduma-library-modal__footer', [
            button(
              classes: 'eduma-desktop-pill eduma-desktop-pill--outlined',
              type: ButtonType.button,
              disabled: _saving,
              onClick: component.onClose,
              [.text('Cancel')],
            ),
            button(
              classes: 'eduma-desktop-pill eduma-desktop-pill--primary',
              type: ButtonType.button,
              disabled: _saving || _name.trim().isEmpty,
              onClick: () => unawaited(_submit()),
              [.text(_saving ? 'Creating…' : 'Create group')],
            ),
          ]),
        ],
      ),
    ]);
  }
}
