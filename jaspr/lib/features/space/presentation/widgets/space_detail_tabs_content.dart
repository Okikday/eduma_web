import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../data/space_detail_models.dart';
import 'space_detail_members_tab.dart';
import 'space_detail_pages_tab.dart';

/// Shared `Pages | Assets | Events` segmented toolbar (desktop & mobile) matching
/// `SpaceDesktopToolbar`, `SpaceTabBar`, and `SpaceSelectionBar` in `../eduma`.
Component spaceDetailTabToolbar({
  required int activeTabIndex,
  required String query,
  required SpacePageFilter pageFilter,
  required bool filterMenuOpen,
  required bool mobileSearchOpen,
  required bool selectingPages,
  required int visiblePagesCount,
  required int selectedPagesCount,
  required bool allVisibleSelected,
  required bool canManagePages,
  required bool canAddPages,
  required bool canAddEvents,
  required ValueChanged<int> onSelectTab,
  required ValueChanged<String> onSearch,
  required ValueChanged<bool> onToggleFilterMenu,
  required ValueChanged<SpacePageFilter> onSelectPageFilter,
  required VoidCallback onToggleMobileSearch,
  required VoidCallback onEnterSelection,
  required VoidCallback onExitSelection,
  required VoidCallback onToggleSelectAll,
  required VoidCallback onArchiveSelected,
  required VoidCallback onDeleteSelected,
  required VoidCallback onOpenCreatePage,
  required VoidCallback onOpenCreateEvent,
}) {
  if (selectingPages && activeTabIndex == 0) {
    final hasSelection = selectedPagesCount > 0;
    return div(classes: 'space-detail__pane-toolbar', [
      div(classes: 'space-detail__selection-bar', [
        button(
          classes: 'space-detail__tool-btn',
          type: ButtonType.button,
          attributes: {'aria-label': 'Cancel selection', 'title': 'Cancel'},
          onClick: onExitSelection,
          [edumaIcon(EdumaIcons.closePlain, size: 17)],
        ),
        span(
          classes: hasSelection
              ? 'space-detail__selection-title'
              : 'space-detail__selection-title is-muted',
          [
            .text(
              selectedPagesCount == 0
                  ? 'Tap pages to select'
                  : '$selectedPagesCount of $visiblePagesCount selected',
            ),
          ],
        ),
        button(
          classes: 'space-detail__selection-all-btn',
          type: ButtonType.button,
          disabled: visiblePagesCount == 0,
          onClick: onToggleSelectAll,
          [.text(allVisibleSelected ? 'Deselect all' : 'Select all')],
        ),
        if (canManagePages) ...[
          button(
            classes: 'space-detail__tool-btn',
            type: ButtonType.button,
            disabled: !hasSelection,
            attributes: {'aria-label': 'Archive selected', 'title': 'Archive selected'},
            onClick: onArchiveSelected,
            [edumaIcon(EdumaIcons.archive, size: 17)],
          ),
          button(
            classes: 'space-detail__tool-btn space-detail__tool-btn--danger',
            type: ButtonType.button,
            disabled: !hasSelection,
            attributes: {'aria-label': 'Delete selected', 'title': 'Delete selected'},
            onClick: onDeleteSelected,
            [edumaIcon(EdumaIcons.delete, size: 17)],
          ),
        ],
      ]),
    ]);
  }

  const labels = ['Pages', 'Assets', 'Events'];
  final searchPlaceholder = switch (activeTabIndex) {
    0 => 'Search pages, checklists, images, links…',
    1 => 'Search assets',
    _ => 'Search events',
  };
  final filterActive = pageFilter != .all;

  return div(classes: 'space-detail__pane-toolbar', [
    div(classes: 'space-detail__toolbar-row', [
      div(
        classes: 'space-detail__seg',
        attributes: {'role': 'tablist', 'aria-label': 'Space sections'},
        [
          for (var i = 0; i < labels.length; i++)
            button(
              classes: [
                'space-detail__seg-btn',
                if (activeTabIndex == i) 'is-active',
              ].join(' '),
              type: ButtonType.button,
              attributes: {'role': 'tab', 'aria-selected': '${activeTabIndex == i}'},
              onClick: () => onSelectTab(i),
              [.text(labels[i])],
            ),
        ],
      ),
      div(classes: 'space-detail__toolbar-spacer', []),
      div(classes: 'space-detail__toolbar-search space-detail__toolbar-search--desktop', [
        edumaIcon(EdumaIcons.search, size: 16),
        input<String>(
          type: InputType.search,
          value: query,
          attributes: {
            'placeholder': searchPlaceholder,
            'aria-label': searchPlaceholder,
          },
          onInput: onSearch,
        ),
        if (query.isNotEmpty)
          button(
            classes: 'space-detail__search-clear',
            type: ButtonType.button,
            attributes: {'aria-label': 'Clear search'},
            onClick: () => onSearch(''),
            [edumaIcon(EdumaIcons.closePlain, size: 15)],
          ),
      ]),
      if (activeTabIndex == 0)
        div(classes: 'space-detail__filter-wrap', [
          button(
            classes: [
              'space-detail__tool-btn',
              if (filterActive || filterMenuOpen) 'is-active',
            ].join(' '),
            type: ButtonType.button,
            attributes: {
              'aria-label': 'Filter pages',
              'aria-haspopup': 'menu',
              'aria-expanded': '$filterMenuOpen',
              'title': 'Filter pages',
            },
            onClick: () => onToggleFilterMenu(!filterMenuOpen),
            [edumaIcon(EdumaIcons.filter, size: 17)],
          ),
          if (filterMenuOpen) ...[
            div(
              classes: 'space-detail__filter-backdrop',
              attributes: {'aria-hidden': 'true'},
              events: {'click': (_) => onToggleFilterMenu(false)},
              const [],
            ),
            div(
              classes: 'space-detail__filter-menu',
              attributes: {'role': 'menu', 'aria-label': 'Filter pages'},
              [
                div(classes: 'space-detail__filter-section-label', [.text('SHOW PAGES')]),
                for (final option in SpacePageFilter.values)
                  if (option != .archived)
                    button(
                      classes: 'space-detail__filter-option',
                      type: ButtonType.button,
                      attributes: {
                        'role': 'menuitemradio',
                        'aria-checked': '${pageFilter == option}',
                        'aria-pressed': '${pageFilter == option}',
                      },
                      onClick: () {
                        onSelectPageFilter(option);
                        onToggleFilterMenu(false);
                      },
                      [
                        span(classes: 'space-detail__filter-option-icon', [
                          edumaIcon(switch (option) {
                            .all => EdumaIcons.layer,
                            .canvas => EdumaIcons.canvas,
                            .notes => EdumaIcons.note,
                            .archived => EdumaIcons.archive,
                          }, size: 16),
                        ]),
                        span(classes: 'space-detail__filter-option-label', [.text(option.label)]),
                        if (pageFilter == option)
                          span(classes: 'space-detail__filter-option-check', [
                            edumaIcon(EdumaIcons.check, size: 15),
                          ]),
                      ],
                    ),
                if (pageFilter != .all)
                  div(classes: 'space-detail__filter-reset-wrap', [
                    button(
                      classes: 'space-detail__filter-reset',
                      type: ButtonType.button,
                      onClick: () {
                        onSelectPageFilter(.all);
                        onToggleFilterMenu(false);
                      },
                      [
                        edumaIcon(EdumaIcons.refresh, size: 15),
                        span([.text('Reset filter')]),
                      ],
                    ),
                  ]),
              ],
            ),
          ],
        ]),
      if (activeTabIndex == 0 && visiblePagesCount > 0 && canManagePages)
        button(
          classes: 'space-detail__tool-btn space-detail__tool-btn--select',
          type: ButtonType.button,
          attributes: {'aria-label': 'Select pages', 'title': 'Select pages'},
          onClick: onEnterSelection,
          [edumaIcon(EdumaIcons.tickSquare, size: 17)],
        ),
      button(
        classes: [
          'space-detail__tool-btn',
          'space-detail__mobile-search-toggle',
          if (mobileSearchOpen || query.isNotEmpty) 'is-active',
        ].join(' '),
        type: ButtonType.button,
        attributes: {
          'aria-label': 'Toggle search',
          'aria-expanded': '${mobileSearchOpen || query.isNotEmpty}',
        },
        onClick: onToggleMobileSearch,
        [edumaIcon(EdumaIcons.search, size: 17)],
      ),
      if (activeTabIndex == 0 && canAddPages)
        desktopPillButton(
          icon: EdumaIcons.noteAdd,
          label: 'New page',
          variant: .primary,
          classes: 'space-detail__toolbar-add',
          onPressed: onOpenCreatePage,
        )
      else if (activeTabIndex == 2 && canAddEvents)
        desktopPillButton(
          icon: EdumaIcons.calendarAdd,
          label: 'New event',
          variant: .primary,
          classes: 'space-detail__toolbar-add',
          onPressed: onOpenCreateEvent,
        ),
    ]),
    if (mobileSearchOpen || query.isNotEmpty)
      div(classes: 'space-detail__toolbar-search space-detail__toolbar-search--mobile', [
        edumaIcon(EdumaIcons.search, size: 16),
        input<String>(
          type: InputType.search,
          value: query,
          attributes: {
            'placeholder': searchPlaceholder,
            'aria-label': searchPlaceholder,
          },
          onInput: onSearch,
        ),
        if (query.isNotEmpty)
          button(
            classes: 'space-detail__search-clear',
            type: ButtonType.button,
            attributes: {'aria-label': 'Clear search'},
            onClick: () => onSearch(''),
            [edumaIcon(EdumaIcons.closePlain, size: 15)],
          ),
      ]),
  ]);
}

/// Modal dialog showing options for a page (`Open`, `Archive/Restore`, `Delete`).
Component spacePageOptionsModal({
  required SpacePage? page,
  required bool canManagePages,
  required bool busy,
  required VoidCallback onClose,
  required ValueChanged<SpacePage> onToggleArchive,
  required ValueChanged<SpacePage> onDeletePage,
}) {
  if (page == null) return .empty();
  final route = spacePageRoutePath(page);
  return div(
    classes: 'space-detail__modal-backdrop',
    attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': 'Page options'},
    events: {
      'click': (event) {
        if (event.target == event.currentTarget) onClose();
      },
    },
    [
      div(classes: 'space-detail__modal-card space-detail__modal-card--compact', [
        div(classes: 'space-detail__modal-head', [
          div([
            h2([.text(page.title)]),
            p([.text('${page.pageType.label}${page.isArchived ? ' · Archived' : ''}')]),
          ]),
          button(
            classes: 'space-detail__modal-close',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close options'},
            onClick: onClose,
            [edumaIcon(EdumaIcons.closePlain, size: 18)],
          ),
        ]),
        div(classes: 'space-detail__options-list', [
          edumaLink(
            to: route,
            classes: 'space-detail__option-row',
            children: [
              edumaIcon(page.pageType.isDynamic ? EdumaIcons.canvas : EdumaIcons.note, size: 18),
              span([.text('Open ${page.pageType.label.toLowerCase()}')]),
              edumaIcon(EdumaIcons.chevronRight, size: 14),
            ],
          ),
          if (canManagePages) ...[
            button(
              classes: 'space-detail__option-row',
              type: ButtonType.button,
              disabled: busy,
              onClick: () {
                onClose();
                onToggleArchive(page);
              },
              [
                edumaIcon(page.isArchived ? EdumaIcons.refresh : EdumaIcons.archive, size: 18),
                span([.text(page.isArchived ? 'Restore to space' : 'Archive page')]),
              ],
            ),
            button(
              classes: 'space-detail__option-row space-detail__option-row--danger',
              type: ButtonType.button,
              disabled: busy,
              onClick: () {
                onClose();
                onDeletePage(page);
              },
              [
                edumaIcon(EdumaIcons.delete, size: 18),
                span([.text('Delete page')]),
              ],
            ),
          ],
        ]),
      ]),
    ],
  );
}

/// Assets tab matching `SpaceAssetsList` + `SpaceAssetCard` in `../eduma`.
Component spaceDetailAssetsTab({
  required List<SpaceAsset> assets,
  required String query,
}) {
  final term = query.trim().toLowerCase();
  final visible = term.isEmpty
      ? assets
      : assets
            .where(
              (asset) =>
                  asset.displayName.toLowerCase().contains(term) ||
                  (asset.pageTitle?.toLowerCase().contains(term) ?? false),
            )
            .toList();

  if (visible.isEmpty) {
    return div(classes: 'space-detail__empty-pane', [
      span(classes: 'space-detail__empty-icon', [
        edumaIcon(term.isEmpty ? EdumaIcons.folderOpen : EdumaIcons.search, size: 26),
      ]),
      h3([.text(term.isEmpty ? 'No assets yet' : 'No matching assets')]),
      p([
        .text(
          term.isEmpty
              ? 'Files and links added to pages in this space will appear here.'
              : 'Try another file name or clear your search.',
        ),
      ]),
    ]);
  }

  return div(classes: 'space-detail__cards-list', [
    for (final asset in visible) _assetCard(asset),
  ]);
}

Component _assetCard(SpaceAsset asset) {
  final ext = asset.extension.toUpperCase();
  final date = _formatMonthDay(asset.createdAt);
  final head = [
    if (ext.isNotEmpty) ext,
    if (asset.size.trim().isNotEmpty) asset.size.trim(),
  ].join(' · ');
  final location = (asset.pageTitle ?? '').trim().isNotEmpty
      ? asset.pageTitle!
      : 'Space files';
  final meta = [if (head.isNotEmpty) head, date, location].join(' • ');
  final href = asset.url.trim();

  final inner = [
    span(classes: 'space-detail__asset-leading', [
      edumaIcon(_assetIcon(asset), size: 20),
    ]),
    div(classes: 'space-detail__card-body', [
      strong(classes: 'space-detail__card-title', [.text(asset.displayName)]),
      span(classes: 'space-detail__card-meta', [.text(meta)]),
    ]),
    span(classes: 'space-detail__card-chevron', [
      edumaIcon(EdumaIcons.chevronRight, size: 14),
    ]),
  ];

  return href.isNotEmpty
      ? a(
          href: href,
          target: Target.blank,
          attributes: {'rel': 'noopener noreferrer'},
          classes: 'space-detail__item-card',
          inner,
        )
      : div(classes: 'space-detail__item-card', inner);
}

Object _assetIcon(SpaceAsset asset) => switch (asset.assetType.toLowerCase()) {
  'link' => EdumaIcons.link,
  'document' => EdumaIcons.document,
  _ => EdumaIcons.folderOpen,
};

/// Events tab matching `SpaceEventsList` + `SpaceEventCard` in `../eduma`.
Component spaceDetailEventsTab({
  required List<SpaceEvent> events,
  required String query,
  required bool canAddEvents,
  required VoidCallback onOpenCreateEvent,
}) {
  final term = query.trim().toLowerCase();
  final visible = term.isEmpty
      ? events
      : events
            .where(
              (e) =>
                  e.title.toLowerCase().contains(term) ||
                  (e.description?.toLowerCase().contains(term) ?? false),
            )
            .toList();

  if (visible.isEmpty) {
    return div(classes: 'space-detail__empty-pane space-detail__empty-pane--card', [
      span(classes: 'space-detail__empty-icon', [
        edumaIcon(EdumaIcons.calendar, size: 26),
      ]),
      h3([.text(term.isEmpty ? 'No events scheduled' : 'No matching events')]),
      p([
        .text(
          canAddEvents
              ? 'Schedule group syncs, study halls, or deadlines to collaborate effectively.'
              : 'Sessions scheduled by the space admins will show up here.',
        ),
      ]),
      if (canAddEvents && term.isEmpty)
        desktopPillButton(
          icon: EdumaIcons.calendarAdd,
          label: 'Add Event',
          variant: .primary,
          onPressed: onOpenCreateEvent,
        ),
    ]);
  }

  return div(classes: 'space-detail__cards-list', [
    for (final event in visible) _eventCard(event),
  ]);
}

Component _eventCard(SpaceEvent event) {
  final month = _shortMonths[event.startTime.month - 1].toUpperCase();
  final day = '${event.startTime.day}';
  final timeRange = '${_formatClock(event.startTime)} - ${_formatClock(event.endTime)}';

  return div(classes: 'space-detail__item-card', [
    div(classes: 'space-detail__event-date', [
      span(classes: 'space-detail__event-month', [.text(month)]),
      span(classes: 'space-detail__event-day', [.text(day)]),
    ]),
    div(classes: 'space-detail__card-body', [
      strong(classes: 'space-detail__card-title', [.text(event.title)]),
      span(classes: 'space-detail__card-meta', [
        .text(
          event.location == null || event.location!.isEmpty
              ? timeRange
              : '$timeRange • ${event.location}',
        ),
      ]),
    ]),
    span(classes: 'space-detail__card-chevron', [
      edumaIcon(EdumaIcons.chevronRight, size: 14),
    ]),
  ]);
}

/// Modal roster matching `SpaceMembersBottomSheet` in `../eduma`.
Component spaceMembersModal({
  required bool open,
  required List<SpaceMember> members,
  required String currentUserId,
  required bool canManageMembers,
  required bool isOwner,
  required bool canInvite,
  required Set<String> mutatingMemberIds,
  required VoidCallback onClose,
  required VoidCallback onOpenInvite,
  required void Function(SpaceMember member, bool promote) onToggleAdmin,
  required ValueChanged<SpaceMember> onRemoveMember,
}) {
  if (!open) return .fragment([]);
  return div(
    classes: 'space-detail__modal-backdrop',
    attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': 'Space members'},
    [
      div(classes: 'space-detail__modal-card', [
        div(classes: 'space-detail__modal-head', [
          div([
            h2([.text('Members (${members.length})')]),
            p([.text('People with access to this space')]),
          ]),
          div(classes: 'space-detail__modal-head-actions', [
            if (canInvite)
              desktopPillButton(
                icon: EdumaIcons.userAdd,
                label: 'Invite',
                variant: .tonal,
                onPressed: () {
                  onClose();
                  onOpenInvite();
                },
              ),
            button(
              classes: 'space-detail__modal-close',
              type: ButtonType.button,
              attributes: {'aria-label': 'Close members'},
              onClick: onClose,
              [edumaIcon(EdumaIcons.closePlain, size: 18)],
            ),
          ]),
        ]),
        div(classes: 'space-detail__modal-body', [
          spaceDetailMembersTab(
            members: members,
            currentUserId: currentUserId,
            canManageMembers: canManageMembers,
            isOwner: isOwner,
            mutatingMemberIds: mutatingMemberIds,
            onToggleAdmin: onToggleAdmin,
            onRemoveMember: onRemoveMember,
          ),
        ]),
      ]),
    ],
  );
}

/// Modal list matching `ArchivedPagesSheet` in `../eduma`.
Component spaceArchivedPagesModal({
  required bool open,
  required List<SpacePage> archivedPages,
  required bool canManagePages,
  required Set<String> mutatingPageIds,
  required VoidCallback onClose,
  required ValueChanged<SpacePage> onRestorePage,
  required ValueChanged<SpacePage> onDeletePage,
}) {
  if (!open) return .fragment([]);
  return div(
    classes: 'space-detail__modal-backdrop',
    attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': 'Archived pages'},
    [
      div(classes: 'space-detail__modal-card', [
        div(classes: 'space-detail__modal-head', [
          div([
            h2([.text('Archived pages')]),
            p([
              .text(
                archivedPages.isEmpty
                    ? 'Hidden from the Pages tab'
                    : '${archivedPages.length} hidden from the Pages tab',
              ),
            ]),
          ]),
          button(
            classes: 'space-detail__modal-close',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close archived pages'},
            onClick: onClose,
            [edumaIcon(EdumaIcons.closePlain, size: 18)],
          ),
        ]),
        div(classes: 'space-detail__modal-body', [
          if (archivedPages.isEmpty)
            div(classes: 'space-detail__empty-pane', [
              span(classes: 'space-detail__empty-icon', [
                edumaIcon(EdumaIcons.archive, size: 24),
              ]),
              h3([.text('Nothing archived')]),
              p([.text('Archive a page from its options to tuck it away without deleting it.')]),
            ])
          else
            div(classes: 'space-detail__cards-list', [
              for (final page in archivedPages)
                div(classes: 'space-detail__item-card', [
                  div(classes: 'space-detail__card-body', [
                    strong(classes: 'space-detail__card-title', [.text(page.title)]),
                    span(classes: 'space-detail__card-meta', [
                      .text(
                        page.updatedAt == null
                            ? page.pageType.label
                            : '${page.pageType.label} • ${_formatMonthDay(page.updatedAt!)}',
                      ),
                    ]),
                  ]),
                  if (canManagePages) ...[
                    button(
                      classes: 'space-detail__icon-btn',
                      type: ButtonType.button,
                      disabled: mutatingPageIds.contains(page.id),
                      attributes: {'title': 'Restore', 'aria-label': 'Restore ${page.title}'},
                      onClick: () => onRestorePage(page),
                      [edumaIcon(EdumaIcons.refresh, size: 16)],
                    ),
                    button(
                      classes: 'space-detail__icon-btn space-detail__icon-btn--danger',
                      type: ButtonType.button,
                      disabled: mutatingPageIds.contains(page.id),
                      attributes: {'title': 'Delete', 'aria-label': 'Delete ${page.title}'},
                      onClick: () => onDeletePage(page),
                      [edumaIcon(EdumaIcons.delete, size: 16)],
                    ),
                  ],
                ]),
            ]),
        ]),
      ]),
    ],
  );
}

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatMonthDay(DateTime date) => '${_shortMonths[date.month - 1]} ${date.day}';

String _formatClock(DateTime date) {
  final h24 = date.hour;
  final period = h24 >= 12 ? 'PM' : 'AM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final m = date.minute.toString().padLeft(2, '0');
  return '$h12:$m $period';
}
