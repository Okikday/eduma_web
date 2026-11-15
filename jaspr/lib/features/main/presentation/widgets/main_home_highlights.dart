import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_link.dart';
import '../../data/main_canvas.dart';
import '../../data/main_space.dart';
import 'main_home_helpers.dart';
import 'main_home_icons.dart';
import 'main_home_spaces_section.dart';

/// Horizontal carousel of recently opened canvases & structured notes (up to 3).
Component mainHomeRecentCanvasSection(List<MainCanvas> canvases) {
  final visible = canvases.take(3).toList();
  return section(
    classes: 'main-home__recent',
    attributes: {'aria-labelledby': 'main-recent-title'},
    [
      div(classes: 'main-home__section-heading', [
        h2(id: 'main-recent-title', [.text('Most Recent')]),
        if (canvases.length > 1)
          edumaLink(
            to: '/recentCanvasesSeeAll',
            classes: 'main-home__see-all',
            children: [.text('See all'), mainHomeIcon(.arrow, size: 11)],
          ),
      ]),
      div(classes: 'main-home__recent-list', [
        for (final canvas in visible) mainHomeRecentCanvasCard(canvas),
      ]),
    ],
  );
}

/// Pinned spaces carousel (mobile) or sidebar card (desktop).
Component mainHomePinnedSection(
  List<MainSpace> spaces, {
  ValueChanged<MainSpace>? onOpenMenu,
}) => section(
  classes: 'main-home__pinned',
  attributes: {'aria-labelledby': 'main-pinned-title'},
  [
    div(classes: 'main-home__section-heading', [
      h2(id: 'main-pinned-title', [.text('Pinned')]),
      edumaLink(
        to: '/pinnedSpacesSeeAll',
        classes: 'main-home__see-all',
        children: [.text('See all'), mainHomeIcon(.arrow, size: 11)],
      ),
    ]),
    div(classes: 'main-home__pinned-list', [
      for (final space in spaces) _pinnedSpaceCard(space, onOpenMenu: onOpenMenu),
    ]),
  ],
);

Component mainHomeRecentCanvasCard(MainCanvas canvas) {
  final path = canvas.type == .dynamicCanvas ? '/spacePageCanvas' : '/spacePageStatic';
  final title = canvas.title.isEmpty
      ? canvas.type == .dynamicCanvas
            ? 'Untitled canvas'
            : 'Untitled note'
      : canvas.title;
  final route = Uri(
    path: path,
    queryParameters: {'id': canvas.id, 'spaceId': canvas.spaceId},
  ).toString();
  return edumaLink(
    to: route,
    classes: 'main-home__recent-card',
    children: [
      if (canvas.previewUrl case final bgUrl?)
        img(
          src: bgUrl,
          alt: '',
          classes: 'main-home__recent-bg',
          attributes: {'aria-hidden': 'true'},
        ),
      span(
        classes: canvas.previewUrl != null
            ? 'main-home__recent-cover'
            : 'main-home__recent-cover main-home__recent-cover--placeholder',
        [
          if (canvas.previewUrl case final cover?)
            img(src: cover, alt: '')
          else
            mainHomeIcon(
              canvas.type == .dynamicCanvas ? .canvas : .note,
              size: 27,
            ),
        ],
      ),
      span(classes: 'main-home__recent-copy', [
        span(classes: 'main-home__recent-space', [
          mainHomeIcon(.layerSolid, size: 11),
          span([.text(canvas.spaceTitle ?? 'Space')]),
        ]),
        strong([.text(title)]),
        span(classes: 'main-home__recent-footer', [
          span(classes: 'main-home__recent-meta', [
            mainHomeIcon(.clockOutline, size: 12),
            span([.text(mainHomeCanvasActivityLabel(canvas))]),
          ]),
          span(classes: 'main-home__resume', [
            mainHomeIcon(.playSolid, size: 12),
            .text('Resume'),
          ]),
        ]),
      ]),
      span(classes: 'main-home__canvas-type', [
        mainHomeIcon(
          canvas.type == .dynamicCanvas ? .canvas : .note,
          size: 12,
        ),
        .text(canvas.type == .dynamicCanvas ? 'Canvas' : 'Notes'),
      ]),
    ],
  );
}

Component _pinnedSpaceCard(
  MainSpace space, {
  ValueChanged<MainSpace>? onOpenMenu,
}) => edumaLink(
  to: '/spaceDetail?id=${Uri.encodeComponent(space.id)}',
  classes: 'main-home__pinned-card',
  onContextMenu: onOpenMenu == null
      ? null
      : (event) {
          event.preventDefault();
          onOpenMenu(space);
        },
  children: [
    if (space.coverUrl case final cover?)
      img(
        src: cover,
        alt: '',
        classes: 'main-home__pinned-cover',
        attributes: {'aria-hidden': 'true'},
      ),
    mainHomeSpaceAvatar(space, pinned: true),
    span(classes: 'main-home__pinned-copy', [
      span(classes: 'main-home__space-name', [
        strong([.text(space.title)]),
        if (space.isVerified)
          span(classes: 'main-home__verified', [mainHomeIcon(.verified, size: 14)]),
      ]),
      if (space.description case final description?) span([.text(description)]),
      mainHomeMemberRow(space, onGradient: true, compact: true),
    ]),
    span(classes: 'main-home__pinned-chevron', [
      mainHomeIcon(.arrow, size: 14),
    ]),
  ],
);
