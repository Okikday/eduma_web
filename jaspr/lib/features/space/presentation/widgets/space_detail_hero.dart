import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../main/presentation/widgets/main_home_helpers.dart';
import '../../data/space_detail_models.dart';

/// Left 50/50 split hero pane on desktop (`SpaceDesktopHero` in `../eduma`).
Component spaceDetailDesktopHero({
  required SpaceDetailData space,
  required SpacePermissionsLogic permissions,
  required int activePageCount,
  required int archivedCount,
  required int assetCount,
  required int eventCount,
  required bool refreshing,
  required bool pinning,
  required VoidCallback onRefresh,
  required VoidCallback onTogglePin,
  required VoidCallback onOpenEdit,
  required VoidCallback onOpenInvite,
  required VoidCallback onOpenMembers,
  required VoidCallback onOpenArchived,
  required ValueChanged<int> onSelectTab,
}) {
  final trio = spaceGridAccentTrio(space.id);
  final roleIcon = switch (permissions.role) {
    .owner => EdumaIcons.crown,
    .admin => EdumaIcons.shieldTick,
    .member => EdumaIcons.user,
  };

  return div(
    classes: 'space-detail__desktop-hero-wrap',
    attributes: {'style': '--space-accent: ${trio.main};'},
    [
      desktopHeroPane(
        classes: 'space-detail__hero-pane',
        backdrop: _heroBackdrop(space.coverUrl),
        leading: desktopHeroBackButton(fallbackHref: '/main'),
        trailing: div(classes: 'space-detail__hero-top-actions', [
          desktopHeroButton(
            icon: EdumaIcons.refresh,
            label: 'Refresh space',
            disabled: refreshing,
            onPressed: onRefresh,
          ),
          desktopHeroButton(
            icon: space.isPinned ? EdumaIcons.pinSolid : EdumaIcons.pin,
            label: space.isPinned ? 'Unpin space' : 'Pin space',
            active: space.isPinned,
            disabled: pinning,
            onPressed: onTogglePin,
          ),
          if (permissions.canEditSpaceDetails)
            desktopHeroButton(
              icon: EdumaIcons.moreHorizontal,
              label: 'Edit space details',
              onPressed: onOpenEdit,
            ),
        ]),
        bottomContent: [
          div(classes: 'space-detail__hero-headline', [
            span(classes: 'space-detail__glass-role', [
              edumaIcon(roleIcon, size: 13),
              span([.text(permissions.role.label)]),
            ]),
            h1(classes: 'space-detail__hero-title', [
              span([.text(space.title)]),
              if (space.isVerified)
                span(classes: 'space-detail__hero-verified', [
                  edumaIcon(EdumaIcons.verify, size: 22),
                ]),
            ]),
            if (space.description case final desc?)
              p(classes: 'space-detail__hero-desc', [.text(desc)]),
          ]),
          div(classes: 'space-detail__hero-facts', [
            if (space.isPersonal)
              span(classes: 'space-detail__fact-static', [
                edumaIcon(EdumaIcons.lock, size: 14),
                span([.text('Personal space')]),
              ])
            else
              button(
                classes: 'space-detail__fact-btn',
                type: ButtonType.button,
                onClick: onOpenMembers,
                [
                  _heroAvatarStack(space),
                  span([
                    .text(
                      space.memberCount <= 1
                          ? 'Just you'
                          : mainHomeMemberLabel(space.memberCount),
                    ),
                  ]),
                ],
              ),
            button(
              classes: 'space-detail__fact-btn',
              type: ButtonType.button,
              onClick: () => onSelectTab(0),
              [
                edumaIcon(EdumaIcons.note, size: 14),
                span([.text('$activePageCount ${activePageCount == 1 ? 'page' : 'pages'}')]),
              ],
            ),
            if (archivedCount > 0)
              button(
                classes: 'space-detail__fact-btn',
                type: ButtonType.button,
                onClick: onOpenArchived,
                [
                  edumaIcon(EdumaIcons.archive, size: 14),
                  span([.text('$archivedCount archived')]),
                ],
              ),
            button(
              classes: 'space-detail__fact-btn',
              type: ButtonType.button,
              onClick: () => onSelectTab(1),
              [
                edumaIcon(EdumaIcons.layer, size: 14),
                span([.text('$assetCount ${assetCount == 1 ? 'asset' : 'assets'}')]),
              ],
            ),
            button(
              classes: 'space-detail__fact-btn',
              type: ButtonType.button,
              onClick: () => onSelectTab(2),
              [
                edumaIcon(EdumaIcons.calendar, size: 14),
                span([.text('$eventCount ${eventCount == 1 ? 'event' : 'events'}')]),
              ],
            ),
          ]),
          if (permissions.canInvite || permissions.canEditSpaceDetails)
            div(classes: 'space-detail__hero-cta-row', [
              if (permissions.canInvite)
                desktopPillButton(
                  icon: EdumaIcons.userAdd,
                  label: 'Invite',
                  variant: .primary,
                  onPressed: onOpenInvite,
                ),
              if (permissions.canEditSpaceDetails)
                desktopPillButton(
                  icon: EdumaIcons.edit,
                  label: 'Edit space',
                  variant: .glass,
                  onPressed: onOpenEdit,
                ),
            ]),
        ],
      ),
    ],
  );
}

/// Mobile compact header + `SpaceMetaSection` below (`< 1024px`).
Component spaceDetailMobileHeader({
  required SpaceDetailData space,
  required SpacePermissionsLogic permissions,
  required int archivedCount,
  required bool refreshing,
  required bool pinning,
  required VoidCallback onRefresh,
  required VoidCallback onTogglePin,
  required VoidCallback onOpenEdit,
  required VoidCallback onOpenInvite,
  required VoidCallback onOpenMembers,
  required VoidCallback onOpenArchived,
}) {
  final trio = spaceGridAccentTrio(space.id);
  final memberCountLabel = space.memberCount <= 1
      ? 'Just you'
      : mainHomeMemberLabel(space.memberCount);

  return div(classes: 'space-detail__mobile-top', [
    header(
      classes: 'space-detail__mobile-hero',
      attributes: {'style': '--space-accent: ${trio.main};'},
      [
        div(classes: 'space-detail__mobile-hero-bg', [
          _heroBackdrop(space.coverUrl),
        ]),
        span(classes: 'space-detail__hero-scrim', attributes: {'aria-hidden': 'true'}, []),
        div(classes: 'space-detail__hero-top', [
          edumaLink(
            to: '/main',
            classes: 'eduma-hero-btn',
            attributes: {'aria-label': 'Back to Home'},
            children: [edumaIcon(EdumaIcons.back, size: 18)],
          ),
          div(classes: 'space-detail__hero-actions', [
            desktopHeroButton(
              icon: space.isPinned ? EdumaIcons.pinSolid : EdumaIcons.pin,
              label: space.isPinned ? 'Unpin space' : 'Pin space',
              active: space.isPinned,
              disabled: pinning,
              onPressed: onTogglePin,
            ),
            if (permissions.canEditSpaceDetails)
              desktopHeroButton(
                icon: EdumaIcons.moreHorizontal,
                label: 'Space options',
                onPressed: onOpenEdit,
              ),
          ]),
        ]),
        div(classes: 'space-detail__mobile-hero-bottom', [
          span(classes: 'space-detail__mobile-role-chip', [
            .text(permissions.role.label.toUpperCase()),
          ]),
          h1(classes: 'space-detail__mobile-hero-title', [
            span([.text(space.title)]),
            if (space.isVerified) edumaIcon(EdumaIcons.verify, size: 20),
          ]),
        ]),
      ],
    ),
    div(classes: 'space-detail__meta-section', [
      if (space.description case final desc?)
        p(classes: 'space-detail__meta-desc', [.text(desc)]),
      div(classes: 'space-detail__meta-bar', [
        if (space.isPersonal)
          div(classes: 'space-detail__meta-card space-detail__meta-card--grow space-detail__meta-card--personal', [
            span(classes: 'space-detail__personal-pill', [
              edumaIcon(EdumaIcons.lock, size: 12),
              span([.text('Personal')]),
            ]),
            span(
              classes: 'space-detail__meta-members-label',
              [.text('Only you can see this space')],
            ),
          ])
        else
          button(
            classes: 'space-detail__meta-card space-detail__meta-card--grow',
            type: ButtonType.button,
            onClick: onOpenMembers,
            [
              _heroAvatarStack(space),
              span(classes: 'space-detail__meta-members-label', [.text(memberCountLabel)]),
              edumaIcon(EdumaIcons.chevronRight, size: 12),
            ],
          ),
        if (permissions.canInvite)
          button(
            classes: 'space-detail__meta-card space-detail__meta-card--primary',
            type: ButtonType.button,
            onClick: onOpenInvite,
            [edumaIcon(EdumaIcons.userAdd, size: 15), span([.text('Invite')])],
          ),
        if (permissions.canEditSpaceDetails)
          button(
            classes: 'space-detail__meta-card space-detail__meta-card--icon',
            type: ButtonType.button,
            attributes: {'aria-label': 'Edit space'},
            onClick: onOpenEdit,
            [edumaIcon(EdumaIcons.edit, size: 16)],
          ),
        if (archivedCount > 0)
          button(
            classes: 'space-detail__meta-card space-detail__meta-card--icon',
            type: ButtonType.button,
            attributes: {'aria-label': 'Archived pages ($archivedCount)'},
            onClick: onOpenArchived,
            [
              edumaIcon(EdumaIcons.archive, size: 16),
              span(classes: 'space-detail__archived-count', [.text('$archivedCount')]),
            ],
          ),
      ]),
    ]),
  ]);
}

Component _heroBackdrop(String? coverUrl) => coverUrl != null
    ? img(src: coverUrl, alt: '')
    : div(classes: 'space-detail__hero-default-bg', [
        span(classes: 'space-detail__hero-watermark', attributes: {'aria-hidden': 'true'}, []),
      ]);

Component _heroAvatarStack(SpaceDetailData space) {
  final visible = space.memberPreview.take(3).toList();
  if (visible.isEmpty) {
    return span(classes: 'space-detail__meta-empty-icon', [
      edumaIcon(EdumaIcons.people, size: 16),
    ]);
  }
  return span(classes: 'space-detail__hero-avatars', [
    for (final member in visible)
      span(classes: 'space-detail__hero-avatar', [
        if (member.avatarUrl case final url?)
          img(src: url, alt: '')
        else
          .text(mainHomeInitials(member.name)),
      ]),
  ]);
}
