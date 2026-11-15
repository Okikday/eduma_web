import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../main/presentation/widgets/main_home_helpers.dart';
import '../../../main/presentation/widgets/main_home_icons.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../data/space_detail_models.dart';

/// Members tab on Space Detail: roster list with online dots, role badges, and
/// owner/admin role/removal controls.
Component spaceDetailMembersTab({
  required List<SpaceMember> members,
  required String currentUserId,
  required bool canManageMembers,
  required bool isOwner,
  required Set<String> mutatingMemberIds,
  required void Function(SpaceMember member, bool promote) onToggleAdmin,
  required ValueChanged<SpaceMember> onRemoveMember,
}) {
  if (members.isEmpty) {
    return mainHomeEmptyState(
      'No member roster available',
      'Members who join this space will appear here.',
    );
  }
  return div(classes: 'space-detail__members-list', [
    for (final member in members)
      _memberTile(
        member: member,
        isSelf: member.id == currentUserId,
        canManageMembers: canManageMembers,
        isOwner: isOwner,
        busy: mutatingMemberIds.contains(member.id),
        onToggleAdmin: (promote) => onToggleAdmin(member, promote),
        onRemove: () => onRemoveMember(member),
      ),
  ]);
}

Component _memberTile({
  required SpaceMember member,
  required bool isSelf,
  required bool canManageMembers,
  required bool isOwner,
  required bool busy,
  required ValueChanged<bool> onToggleAdmin,
  required VoidCallback onRemove,
}) {
  final initials = mainHomeInitials(member.name);
  final canPromoteOrDemote = isOwner && !isSelf && member.role != .owner;
  final canRemove = canManageMembers && !isSelf && member.role != .owner;

  return div(classes: 'space-detail__member-card', [
    div(classes: 'space-detail__member-avatar', [
      if (member.avatarUrl case final url?) img(src: url, alt: '') else .text(initials.isEmpty ? 'E' : initials),
      if (member.isOnline)
        span(
          classes: 'space-detail__online-dot',
          attributes: {'aria-label': 'Online'},
          [],
        ),
    ]),
    div(classes: 'space-detail__member-copy', [
      div(classes: 'space-detail__member-name', [
        span([.text(isSelf ? '${member.name} (you)' : member.name)]),
        if (member.isVerified) mainHomeIcon(.verified, size: 15),
      ]),
      if (member.username case final username?) span(classes: 'space-detail__member-handle', [.text('@$username')]),
    ]),
    span(
      classes: 'space-detail__role-chip space-detail__role-chip--${member.role.name}',
      [.text(member.role.label)],
    ),
    if (canPromoteOrDemote)
      button(
        classes: 'space-detail__icon-btn',
        type: ButtonType.button,
        disabled: busy,
        attributes: {
          'aria-label': member.role == .admin ? 'Remove admin role from ${member.name}' : 'Make ${member.name} admin',
          'title': member.role == .admin ? 'Demote admin' : 'Promote to admin',
        },
        onClick: () => onToggleAdmin(member.role != .admin),
        [mainHomeIcon(.admin, size: 16)],
      ),
    if (canRemove)
      button(
        classes: 'space-detail__icon-btn space-detail__icon-btn--danger',
        type: ButtonType.button,
        disabled: busy,
        attributes: {
          'aria-label': 'Remove ${member.name}',
          'title': 'Remove member',
        },
        onClick: onRemove,
        [mainHomeIcon(.delete, size: 16)],
      ),
  ]);
}
