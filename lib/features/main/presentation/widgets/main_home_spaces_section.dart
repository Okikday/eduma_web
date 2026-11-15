import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_cover_fallback.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../data/main_space.dart';
import 'main_home_helpers.dart';
import 'main_home_icons.dart';
import 'main_home_notices.dart';

/// All Spaces / Search Results section, supporting List tiles and Flutter-parity Fanned Grid cards.
Component mainHomeSpacesSection({
  required List<MainSpace> spaces,
  required String query,
  required MainSpaceFilter filter,
  required bool loading,
  required String? error,
  required bool gridView,
  required VoidCallback onRetry,
  required VoidCallback onClearSearch,
  required VoidCallback onClearFilters,
  required VoidCallback onOpenCreateSpace,
  required VoidCallback onOpenJoinSpace,
  ValueChanged<MainSpace>? onOpenMenu,
}) {
  final searching = query.trim().isNotEmpty;
  return section(
    classes: 'main-home__spaces',
    attributes: {'aria-label': searching ? 'Search results' : 'All spaces'},
    [
      div(classes: 'main-home__section-heading', [
        h2([.text(searching ? 'Results' : 'All spaces')]),
        if (!searching && spaces.isNotEmpty)
          edumaLink(
            to: '/recentSpacesSeeAll',
            classes: 'main-home__see-all main-home__mobile-see-all',
            children: [.text('See all'), mainHomeIcon(.arrow, size: 11)],
          ),
      ]),
      if (loading && spaces.isEmpty)
        _spaceSkeletons()
      else if (error != null && spaces.isEmpty)
        mainHomeEmptyState(
          "Couldn't load your spaces",
          error,
          onRetry: onRetry,
        )
      else if (spaces.isEmpty)
        _spacesEmptyState(
          query: query,
          filter: filter,
          onClearSearch: onClearSearch,
          onClearFilters: onClearFilters,
          onOpenCreateSpace: onOpenCreateSpace,
          onOpenJoinSpace: onOpenJoinSpace,
        )
      else
        div(
          classes: [
            'main-home__space-list',
            if (gridView) 'main-home__space-list--grid',
          ].join(' '),
          [
            for (final space in spaces)
              gridView
                  ? _spaceGridCard(space, onOpenMenu: onOpenMenu)
                  : mainHomeSpaceListCard(space, onOpenMenu: onOpenMenu),
          ],
        ),
    ],
  );
}

Component mainHomeRoleBadge(MainSpaceRole role) {
  if (role case MainSpaceRole.owner || MainSpaceRole.admin) {
    final isOwner = role == .owner;
    return span(
      classes: [
        'main-home__role-badge',
        isOwner ? 'is-owner' : 'is-admin',
      ].join(' '),
      attributes: {
        'aria-label': isOwner ? 'Space owner' : 'Space administrator',
      },
      [mainHomeIcon(isOwner ? .owner : .admin, size: 10)],
    );
  }
  return .fragment([]);
}

Component mainHomeSpaceAvatar(MainSpace space, {bool pinned = false}) {
  final checklist = space.checklist;
  final hasRing = checklist != null && checklist.hasItems;
  final size = pinned ? 58 : 48;
  final radius = pinned ? 17.0 : 13.0;
  return span(
    classes: [
      'main-home__space-avatar',
      if (pinned) 'main-home__space-avatar--pinned',
      if (hasRing) 'has-checklist',
    ].join(' '),
    attributes: {
      if (hasRing) 'aria-label': checklist.label,
    },
    [
      if (hasRing) _checklistRingSvg(checklist.fraction, size: size, radius: radius),
      span(classes: 'main-home__space-cover-box', [
        if (space.coverUrl case final cover?)
          img(src: cover, alt: '')
        else
          edumaCoverFallback(),
      ]),
      if (pinned) mainHomeRoleBadge(space.role),
    ],
  );
}

Component _checklistRingSvg(
  double fraction, {
  required int size,
  required double radius,
}) {
  const strokeWidth = 2.5;
  const inset = strokeWidth / 2;
  final left = inset;
  final top = inset;
  final right = size - inset;
  final bottom = size - inset;
  final cx = size / 2;
  final maxR = (size - strokeWidth) / 2;
  final r = (radius - inset).clamp(0.0, maxR);
  final d =
      'M $cx $top '
      'L ${right - r} $top '
      'A $r $r 0 0 1 $right ${top + r} '
      'L $right ${bottom - r} '
      'A $r $r 0 0 1 ${right - r} $bottom '
      'L ${left + r} $bottom '
      'A $r $r 0 0 1 $left ${bottom - r} '
      'L $left ${top + r} '
      'A $r $r 0 0 1 ${left + r} $top '
      'Z';
  final pct = (fraction.clamp(0.0, 1.0) * 100).toStringAsFixed(2);
  return svg(
    classes: 'main-home__ring-svg',
    viewBox: '0 0 $size $size',
    width: .pixels(size.toDouble()),
    height: .pixels(size.toDouble()),
    attributes: {'aria-hidden': 'true'},
    [
      path(
        d: d,
        fill: Colors.transparent,
        strokeWidth: '$strokeWidth',
        classes: 'main-home__ring-track',
        const [],
      ),
      if (fraction > 0)
        path(
          d: d,
          fill: Colors.transparent,
          strokeWidth: '$strokeWidth',
          classes: 'main-home__ring-fill',
          attributes: {
            'stroke-linecap': 'round',
            'pathLength': '100',
            'stroke-dasharray': '$pct 100',
          },
          const [],
        ),
    ],
  );
}

Component mainHomeMemberRow(
  MainSpace space, {
  bool onGradient = false,
  bool compact = false,
}) {
  final activity = mainHomeActivityLabel(space.lastActivity, space.activityType);
  if (space.isPersonal) {
    return span(
      classes: [
        'main-home__member-row',
        if (onGradient) 'main-home__member-row--inverse',
      ].join(' '),
      [
        span(classes: 'main-home__personal-badge', [
          mainHomeIcon(.lock, size: 10),
          span([.text('Personal')]),
        ]),
        if (!compact && activity.isNotEmpty)
          span(classes: 'main-home__member-meta', [.text(activity)]),
      ],
    );
  }
  final total = space.memberCount > space.memberPreview.length
      ? space.memberCount
      : space.memberPreview.length;
  final hasOverflow = total > 3;
  final visibleCount = hasOverflow ? 2 : total;
  final visibleMembers = space.memberPreview.take(visibleCount).toList();
  final overflowCount = total - 2;

  return span(
    classes: [
      'main-home__member-row',
      if (onGradient) 'main-home__member-row--inverse',
    ].join(' '),
    [
      if (visibleMembers.isNotEmpty)
        span(classes: 'main-home__member-stack', [
          for (final member in visibleMembers)
            span(classes: 'main-home__member-avatar', [
              if (member.avatarUrl case final url?)
                img(src: url, alt: '')
              else
                .text(mainHomeInitials(member.name)),
            ]),
          if (hasOverflow)
            span(classes: 'main-home__member-avatar main-home__member-overflow', [
              .text(overflowCount > 99 ? '+99+' : '+$overflowCount'),
            ]),
        ]),
      if (!compact)
        span(classes: 'main-home__member-meta', [
          .text(mainHomeMemberLabel(space.memberCount)),
          if (activity.isNotEmpty) .text(' · $activity'),
        ]),
    ],
  );
}

Component mainHomeSpaceListCard(
  MainSpace space, {
  ValueChanged<MainSpace>? onOpenMenu,
}) => edumaLink(
  to: '/spaceDetail?id=${Uri.encodeComponent(space.id)}',
  classes: 'main-home__space-card',
  onContextMenu: onOpenMenu == null
      ? null
      : (event) {
          event.preventDefault();
          onOpenMenu(space);
        },
  children: [
    mainHomeSpaceAvatar(space),
    span(classes: 'main-home__space-copy', [
      span(classes: 'main-home__space-name', [
        strong([.text(space.title)]),
        if (space.isVerified)
          span(classes: 'main-home__verified', [mainHomeIcon(.verified, size: 14)]),
      ]),
      if (space.description case final description?)
        span(classes: 'main-home__space-description', [.text(description)]),
      mainHomeMemberRow(space),
    ]),
    span(classes: 'main-home__tile-chevron', [mainHomeIcon(.arrow, size: 14)]),
  ],
);

Component _spaceGridCard(
  MainSpace space, {
  ValueChanged<MainSpace>? onOpenMenu,
}) {
  final activity = mainHomeActivityLabel(space.lastActivity, space.activityType);
  final members = space.isPersonal ? 'Only you' : mainHomeMemberLabel(space.memberCount);
  final meta = activity.isEmpty ? members : '$members · $activity';
  final trio = spaceGridAccentTrio(space.id);

  return edumaLink(
    to: '/spaceDetail?id=${Uri.encodeComponent(space.id)}',
    classes: 'main-home__space-grid-card',
    onContextMenu: onOpenMenu == null
        ? null
        : (event) {
            event.preventDefault();
            onOpenMenu(space);
          },
    attributes: {
      'style': '--grid-main: ${trio.main}; --grid-left: ${trio.left}; --grid-right: ${trio.right};',
    },
    children: [
      span(classes: 'main-home__space-grid-art', [
        span(classes: 'main-home__fan', [
          _fanSheet(space: space, modifier: 'left', tint: trio.left),
          _fanSheet(space: space, modifier: 'right', tint: trio.right),
          _fanSheet(
            space: space,
            modifier: 'front',
            tint: trio.main,
            showPinnedIndicator: space.isPinned,
          ),
        ]),
        if (!space.isPersonal && space.memberPreview.isNotEmpty)
          span(classes: 'main-home__grid-members', [
            mainHomeMemberRow(space, compact: true),
          ]),
      ]),
      span(classes: 'main-home__space-grid-copy', [
        span(classes: 'main-home__space-name', [
          strong([.text(space.title)]),
          if (space.isVerified)
            span(classes: 'main-home__verified', [mainHomeIcon(.verified, size: 14)]),
        ]),
        span(classes: 'main-home__space-grid-meta', [.text(meta)]),
      ]),
    ],
  );
}

Component _fanSheet({
  required MainSpace space,
  required String modifier,
  required String tint,
  bool showPinnedIndicator = false,
}) => span(
  classes: [
    'main-home__fan-sheet',
    'main-home__fan-sheet--$modifier',
    if (space.coverUrl != null) 'has-cover',
  ].join(' '),
  [
    if (space.coverUrl case final cover?)
      img(src: cover, alt: '')
    else
      edumaCoverFallback(tint: tint, logoPercent: 34),
    if (showPinnedIndicator)
      span(
        classes: 'main-home__grid-pin',
        attributes: {'aria-hidden': 'true'},
        [mainHomeIcon(.pinSolid, size: 12)],
      ),
  ],
);

Component _spacesEmptyState({
  required String query,
  required MainSpaceFilter filter,
  required VoidCallback onClearSearch,
  required VoidCallback onClearFilters,
  required VoidCallback onOpenCreateSpace,
  required VoidCallback onOpenJoinSpace,
}) {
  if (query.trim().isNotEmpty) {
    return mainHomeEmptyState(
      'No spaces match “${query.trim()}”',
      'Check the spelling or try a different word.',
      actions: [
        button(
          classes: 'main-home__empty-action',
          type: ButtonType.button,
          onClick: onClearSearch,
          [.text('Clear')],
        ),
      ],
    );
  }
  if (filter != .all) {
    return mainHomeEmptyState(
      'No spaces match these filters',
      'Try another type or show all your spaces.',
      actions: [
        button(
          classes: 'main-home__empty-action',
          type: ButtonType.button,
          onClick: onClearFilters,
          [.text('Clear')],
        ),
      ],
    );
  }
  return mainHomeEmptyState(
    'No spaces yet',
    'Create a collaborative space for your courses, study groups, and notes, or enter an invite code to join an existing space.',
    actions: [
      button(
        classes: 'main-home__empty-action main-home__empty-action--primary',
        type: ButtonType.button,
        onClick: onOpenCreateSpace,
        [mainHomeIcon(.add), .text('Create Space')],
      ),
      button(
        classes: 'main-home__empty-action',
        type: ButtonType.button,
        onClick: onOpenJoinSpace,
        [mainHomeIcon(.login), .text('Join Space')],
      ),
    ],
  );
}

Component _spaceSkeletons() => div(classes: 'main-home__space-list', [
  for (var i = 0; i < 4; i++)
    div(classes: 'main-home__space-skeleton', [
      span(classes: 'main-home__skeleton-avatar', []),
      div(classes: 'main-home__skeleton-lines', [
        span([]),
        span([]),
        span([]),
      ]),
    ]),
]);
