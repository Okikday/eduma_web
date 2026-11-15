import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_cover_fallback.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../data/main_space.dart';
import 'main_home_helpers.dart';
import 'main_home_icons.dart';
import 'main_home_spaces_section.dart';
import 'web_dialog_helper.dart';

/// Right-click / long-press glass menu matching `SpaceTileContextMenuSheet` in `../eduma`.
class MainHomeSpaceContextMenuDialog extends StatefulComponent {
  const MainHomeSpaceContextMenuDialog({
    required this.space,
    required this.pinning,
    required this.onClose,
    required this.onTogglePin,
    super.key,
  });

  final MainSpace? space;
  final bool pinning;
  final VoidCallback onClose;
  final ValueChanged<MainSpace> onTogglePin;

  @override
  State<MainHomeSpaceContextMenuDialog> createState() => _MainHomeSpaceContextMenuDialogState();
}

class _MainHomeSpaceContextMenuDialogState extends State<MainHomeSpaceContextMenuDialog> {
  static const _dialogId = 'main-home-space-context-dialog';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncDialog);
  }

  @override
  void didUpdateComponent(covariant MainHomeSpaceContextMenuDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.space != component.space) {
      Future<void>.microtask(_syncDialog);
    }
  }

  void _syncDialog() {
    if (!mounted) return;
    WebDialogHelper.syncOpen(_dialogId, component.space != null);
  }

  @override
  Component build(BuildContext context) {
    final space = component.space;
    final roleLabel = switch (space?.role) {
      .owner => 'Owner',
      .admin => 'Admin',
      .member => 'Member',
      null => '',
    };
    final meta = space == null
        ? ''
        : space.isPersonal
        ? 'Personal · Only you'
        : '${mainHomeMemberLabel(space.memberCount)} · $roleLabel';

    return dialog(
      id: _dialogId,
      classes: 'main-home__dialog main-home__context-menu',
      attributes: {
        'closedby': 'any',
        'aria-labelledby': 'main-space-ctx-title',
      },
      events: {'close': (_) => component.onClose()},
      [
        if (space != null)
          div(classes: 'main-home__context-menu-card', [
            div(classes: 'main-home__context-menu-header', [
              span(classes: 'main-home__context-menu-cover', [
                span(classes: 'main-home__space-cover-box', [
                  if (space.coverUrl case final cover?) img(src: cover, alt: '') else edumaCoverFallback(),
                ]),
                mainHomeRoleBadge(space.role),
              ]),
              div(classes: 'main-home__context-menu-title-wrap', [
                h2(id: 'main-space-ctx-title', [.text(space.title)]),
                p([.text(meta)]),
              ]),
            ]),
            div(classes: 'main-home__context-menu-divider', []),
            edumaLink(
              to: '/spaceDetail?id=${Uri.encodeComponent(space.id)}',
              classes: 'main-home__context-menu-row',
              onClick: () => WebDialogHelper.syncOpen(_dialogId, false),
              children: [
                mainHomeIcon(.settings02, size: 18),
                span([.text('Space options')]),
              ],
            ),
            button(
              type: ButtonType.button,
              classes: 'main-home__context-menu-row',
              disabled: component.pinning,
              onClick: () {
                component.onTogglePin(space);
                component.onClose();
              },
              [
                mainHomeIcon(space.isPinned ? .pinOff : .pinOutline, size: 18),
                span([
                  .text(space.isPinned ? 'Unpin space' : 'Pin space to top'),
                ]),
              ],
            ),
          ]),
      ],
    );
  }
}
