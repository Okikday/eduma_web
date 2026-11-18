import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../../../core/presentation/eduma_icons.dart';
import '../../../main/presentation/widgets/web_dialog_helper.dart';
import '../../data/space_detail_models.dart';

/// Web port of `SpaceMoreBottomSheet` in `../eduma` (the hero's "More
/// options"): quick actions, collaboration, notifications, management and the
/// danger zone, as a floating sheet dialog.
///
/// Each row closes the sheet and hands off to the page, which owns the
/// follow-up dialogs (invite, members, edit, report, leave/delete confirm).
class SpaceOptionsDialog extends StatefulComponent {
  const SpaceOptionsDialog({
    required this.open,
    required this.space,
    required this.permissions,
    required this.onClose,
    required this.onInvite,
    required this.onMembers,
    required this.onEdit,
    required this.onReport,
    required this.onLeaveOrDelete,
    required this.onCopyLink,
    super.key,
  });

  final bool open;
  final SpaceDetailData space;
  final SpacePermissionsLogic permissions;
  final VoidCallback onClose;
  final VoidCallback onInvite;
  final VoidCallback onMembers;
  final VoidCallback onEdit;
  final VoidCallback onReport;
  final VoidCallback onLeaveOrDelete;
  final VoidCallback onCopyLink;

  /// localStorage key mirroring `CommentNotificationMutePod.cacheKey`.
  static const _muteKey = 'eduma.commentNotificationMuted.v1';

  static Set<String> _readMuted() {
    try {
      final raw = web.window.localStorage.getItem(_muteKey);
      if (raw == null || raw.isEmpty) return {};
      return raw.split('\n').where((item) => item.isNotEmpty).toSet();
    } catch (_) {
      return {};
    }
  }

  static void _writeMuted(Set<String> targets) {
    try {
      web.window.localStorage.setItem(_muteKey, targets.join('\n'));
    } catch (_) {}
  }

  @override
  State<SpaceOptionsDialog> createState() => _SpaceOptionsDialogState();
}

class _SpaceOptionsDialogState extends State<SpaceOptionsDialog> {
  static const _dialogId = 'space-options-dialog';

  bool _muted = false;

  String get _muteTarget => 'space:${component.space.id}';

  @override
  void initState() {
    super.initState();
    _muted = SpaceOptionsDialog._readMuted().contains(_muteTarget);
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  @override
  void didUpdateComponent(covariant SpaceOptionsDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.open && !oldComponent.open) {
      _muted = SpaceOptionsDialog._readMuted().contains(_muteTarget);
    }
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  void _dismiss() {
    WebDialogHelper.resetReturnValue(_dialogId);
    component.onClose();
  }

  /// Closes the sheet, then runs [action] (which usually opens another dialog).
  void _then(VoidCallback action) {
    _dismiss();
    action();
  }

  void _toggleMute(bool muted) {
    final targets = SpaceOptionsDialog._readMuted();
    muted ? targets.add(_muteTarget) : targets.remove(_muteTarget);
    SpaceOptionsDialog._writeMuted(targets);
    setState(() => _muted = muted);
  }

  @override
  Component build(BuildContext context) {
    final perms = component.permissions;
    final isPersonal = perms.isPersonal;
    final canSeeMembers = !isPersonal;
    final subtitle = isPersonal
        ? 'Your personal space · only you can see it'
        : perms.isManager
        ? 'Manage collaboration, permissions, and space settings'
        : 'Collaborate and manage your membership';

    return dialog(
      id: _dialogId,
      classes: 'eduma-modal',
      attributes: {
        ...WebDialogHelper.openAttr(component.open),
        'closedby': 'any',
        'aria-labelledby': 'space-options-title',
      },
      events: {
        'close': (_) {
          if (component.open) _dismiss();
        },
      },
      [
        div(classes: 'eduma-modal__header', [
          div(classes: 'eduma-modal__title', [
            h2(id: 'space-options-title', [.text('Space Options')]),
            p([.text(subtitle)]),
          ]),
          button(
            classes: 'eduma-modal__close-btn',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close', 'title': 'Close'},
            onClick: _dismiss,
            [edumaIcon(EdumaIcons.closePlain, size: 16)],
          ),
        ]),
        div(classes: 'eduma-modal__body eduma-sheet', [
          if (!isPersonal)
            div(classes: 'eduma-sheet__quick', [
              _quick(EdumaIcons.copyLink, 'Copy link', () => _then(component.onCopyLink)),
              if (!perms.isOwner) _quick(EdumaIcons.flag03, 'Report', () => _then(component.onReport)),
            ]),
          if (perms.canInvite || canSeeMembers)
            _section('Collaboration & Access', [
              if (perms.canInvite)
                _tile(
                  EdumaIcons.addTeam,
                  'Invite people',
                  'Share an invite link or code',
                  () => _then(component.onInvite),
                ),
              if (canSeeMembers)
                _tile(
                  EdumaIcons.userGroup,
                  'Members',
                  perms.canManageMembers ? 'Roles, invitations and join requests' : 'See who is in this space',
                  () => _then(component.onMembers),
                ),
            ]),
          _section('Notifications', [
            label(classes: 'eduma-sheet__setting', [
              span(classes: 'eduma-sheet__setting-icon', [edumaIcon(EdumaIcons.notifications, size: 18)]),
              span(classes: 'eduma-sheet__text', [
                strong([.text('Mute space notifications')]),
                span([.text('Turn off comment alerts for every page in this space')]),
              ]),
              input<bool>(
                classes: 'eduma-switch',
                type: InputType.checkbox,
                checked: _muted,
                attributes: {'role': 'switch'},
                onChange: _toggleMute,
              ),
            ]),
          ]),
          if (perms.canEditSpaceDetails)
            _section('Management', [
              _tile(
                EdumaIcons.edit02,
                'Edit details',
                'Title, cover, description and type',
                () => _then(component.onEdit),
              ),
            ]),
          if (perms.isOwner || !isPersonal)
            _section('Danger zone', danger: true, [
              if (perms.isOwner)
                _tile(
                  EdumaIcons.delete02,
                  'Delete Space',
                  'Permanently remove space and all materials',
                  () => _then(component.onLeaveOrDelete),
                  danger: true,
                )
              else
                _tile(
                  EdumaIcons.logoutStroke,
                  'Leave Space',
                  'You will lose access to its pages and files',
                  () => _then(component.onLeaveOrDelete),
                  danger: true,
                ),
            ]),
        ]),
      ],
    );
  }

  Component _section(String title, List<Component> children, {bool danger = false}) =>
      section(classes: danger ? 'eduma-sheet__section eduma-sheet__section--danger' : 'eduma-sheet__section', [
        h3(classes: 'eduma-sheet__section-title', [.text(title.toUpperCase())]),
        ...children,
      ]);

  Component _tile(Object icon, String title, String subtitle, VoidCallback onTap, {bool danger = false}) => button(
    classes: danger ? 'eduma-sheet__tile eduma-sheet__tile--danger' : 'eduma-sheet__tile',
    type: ButtonType.button,
    onClick: onTap,
    [
      span(classes: 'eduma-sheet__tile-icon', [edumaIcon(icon, size: 20)]),
      span(classes: 'eduma-sheet__text', [
        strong([.text(title)]),
        span([.text(subtitle)]),
      ]),
      edumaIcon(EdumaIcons.chevronRight, size: 14, classes: 'eduma-sheet__chevron'),
    ],
  );

  Component _quick(Object icon, String text, VoidCallback onTap) => button(
    classes: 'eduma-sheet__quick-action',
    type: ButtonType.button,
    onClick: onTap,
    [
      edumaIcon(icon, size: 18),
      span([.text(text)]),
    ],
  );
}
