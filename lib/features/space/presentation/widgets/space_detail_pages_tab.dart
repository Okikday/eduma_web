import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_cover_fallback.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../data/space_detail_models.dart';

/// Pages tab on Space Detail (`SpacePagesList` + `SpacePageCard` in `../eduma`):
/// 72px height cards, 48x48 cover thumbnail wrapped by CSS `ChecklistRing`,
/// type pill, optional selection checkboxes, and options menu trigger.
Component spaceDetailPagesTab({
  required List<SpacePage> filteredPages,
  required SpacePageFilter filter,
  required String query,
  required bool canManagePages,
  required bool canCreatePage,
  required bool selecting,
  required Set<String> selectedPageIds,
  required Set<String> mutatingPageIds,
  required ValueChanged<SpacePageFilter> onSelectFilter,
  required VoidCallback onOpenCreatePage,
  required ValueChanged<SpacePage> onToggleSelectPage,
  required ValueChanged<SpacePage> onOpenPageOptions,
}) {
  return div(classes: 'space-detail__pages-pane', [
    if (filter != .all && !selecting)
      div(classes: 'space-detail__active-filter-row', [
        span(classes: 'space-detail__chip is-active', [
          .text('Showing: ${filter.label}'),
          button(
            classes: 'space-detail__chip-clear',
            type: ButtonType.button,
            attributes: {'aria-label': 'Clear filter'},
            onClick: () => onSelectFilter(.all),
            [edumaIcon(EdumaIcons.closePlain, size: 12)],
          ),
        ]),
      ]),
    if (filteredPages.isEmpty)
      div(classes: 'space-detail__empty-pane', [
        span(classes: 'space-detail__empty-icon', [
          edumaIcon(query.trim().isNotEmpty ? EdumaIcons.search : EdumaIcons.note, size: 26),
        ]),
        h3([
          .text(
            query.trim().isNotEmpty
                ? 'No pages match “${query.trim()}”'
                : filter != .all
                ? 'No ${filter.label.toLowerCase()} pages'
                : 'No pages yet',
          ),
        ]),
        p([
          .text(
            query.trim().isNotEmpty
                ? 'Try another search term or switch filters.'
                : 'Create a free-form Canvas or structured Notes page for this space.',
          ),
        ]),
        if (canCreatePage && query.trim().isEmpty && filter == .all)
          desktopPillButton(
            icon: EdumaIcons.noteAdd,
            label: 'Create page',
            variant: .primary,
            onPressed: onOpenCreatePage,
          ),
      ])
    else
      div(classes: 'space-detail__cards-list', [
        for (final page in filteredPages)
          _spacePageCard(
            page: page,
            busy: mutatingPageIds.contains(page.id),
            selecting: selecting,
            selected: selectedPageIds.contains(page.id),
            onToggleSelect: () => onToggleSelectPage(page),
            onOpenOptions: () => onOpenPageOptions(page),
          ),
      ]),
  ]);
}

String spacePageRoutePath(SpacePage page) {
  final path = page.pageType == .dynamicCanvas ? '/spacePageCanvas' : '/spacePageStatic';
  final uri = Uri(
    path: path,
    queryParameters: {'id': page.id, 'spaceId': page.spaceId},
  );
  return uri.toString();
}

Component _spacePageCard({
  required SpacePage page,
  required bool busy,
  required bool selecting,
  required bool selected,
  required VoidCallback onToggleSelect,
  required VoidCallback onOpenOptions,
}) {
  final route = spacePageRoutePath(page);
  final hasChecklist = page.checklistTotal > 0;
  final pct = hasChecklist
      ? ((page.checklistDone / page.checklistTotal).clamp(0.0, 1.0) * 100)
            .toStringAsFixed(1)
      : '0';

  final thumb = span(
    classes: hasChecklist
        ? 'space-detail__page-thumb has-checklist'
        : 'space-detail__page-thumb',
    attributes: hasChecklist ? {'style': '--ring-pct: $pct%;'} : const {},
    [
      span(classes: 'space-detail__page-thumb-inner', [
        if (page.visualPreview case final imgUrl?)
          img(src: imgUrl, alt: '')
        else
          edumaCoverFallback(logoPercent: 42),
      ]),
    ],
  );

  final subtitlePieces = [
    if (hasChecklist) '${page.checklistDone}/${page.checklistTotal} done',
    if (page.description case final desc?) desc,
  ];

  final infoBody = div(classes: 'space-detail__card-body', [
    div(classes: 'space-detail__page-title-line', [
      strong(classes: 'space-detail__card-title', [.text(page.title)]),
    ]),
    div(classes: 'space-detail__card-meta-row', [
      span(
        classes: page.pageType.isDynamic
            ? 'space-detail__type-pill space-detail__type-pill--canvas'
            : 'space-detail__type-pill space-detail__type-pill--notes',
        [
          edumaIcon(page.pageType.isDynamic ? EdumaIcons.canvas : EdumaIcons.note, size: 11),
          span([.text(page.pageType.label)]),
        ],
      ),
      if (subtitlePieces.isNotEmpty)
        span(classes: 'space-detail__card-meta', [
          .text(subtitlePieces.join(' · ')),
        ]),
    ]),
  ]);

  if (selecting) {
    return button(
      classes:
          'space-detail__item-card space-detail__item-card--page${selected ? ' is-selected' : ''}',
      type: ButtonType.button,
      disabled: busy,
      attributes: {'aria-pressed': '$selected'},
      onClick: onToggleSelect,
      [
        thumb,
        div(classes: 'space-detail__card-link', [infoBody]),
        span(
          classes: 'space-detail__select-circle${selected ? ' is-checked' : ''}',
          [if (selected) edumaIcon(EdumaIcons.check, size: 13)],
        ),
      ],
    );
  }

  return div(
    classes: 'space-detail__item-card space-detail__item-card--page',
    events: {
      'contextmenu': (event) {
        event.preventDefault();
        onOpenOptions();
      },
    },
    [
      edumaLink(
        to: route,
        classes: 'space-detail__card-main-link',
        children: [thumb, infoBody],
      ),
      div(classes: 'space-detail__page-actions', [
        button(
          classes: 'space-detail__more-btn',
          type: ButtonType.button,
          disabled: busy,
          attributes: {'aria-label': 'Options for ${page.title}', 'title': 'Options'},
          onClick: onOpenOptions,
          [edumaIcon(EdumaIcons.moreHorizontal, size: 16)],
        ),
        edumaLink(
          to: route,
          classes: 'space-detail__card-chevron',
          attributes: {'aria-label': 'Open ${page.title}'},
          children: [edumaIcon(EdumaIcons.chevronRight, size: 14)],
        ),
      ]),
    ],
  );
}
