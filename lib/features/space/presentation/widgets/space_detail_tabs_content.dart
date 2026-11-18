import '../../../../core/presentation/eduma_sheet_dialog.dart';
import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

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
  required bool gridView,
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
  required VoidCallback onToggleView,
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
          classes: hasSelection ? 'space-detail__selection-title' : 'space-detail__selection-title is-muted',
          [
            .text(
              selectedPagesCount == 0 ? 'Tap pages to select' : '$selectedPagesCount of $visiblePagesCount selected',
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
    0 => 'Search pages…',
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
            attributes: {'aria-label': 'Clear search', 'title': 'Clear search'},
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
          'title': mobileSearchOpen ? 'Close search' : 'Search',
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
            attributes: {'aria-label': 'Clear search', 'title': 'Clear search'},
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
  required ValueChanged<SpacePage> onCopyPageLink,
  required ValueChanged<SpacePage> onSelectPage,
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
            attributes: {'aria-label': 'Close options', 'title': 'Close'},
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
          button(
            classes: 'space-detail__option-row',
            type: ButtonType.button,
            onClick: () {
              onClose();
              onCopyPageLink(page);
            },
            [
              edumaIcon(EdumaIcons.copyLink, size: 18),
              span([.text('Copy page link')]),
            ],
          ),
          button(
            classes: 'space-detail__option-row',
            type: ButtonType.button,
            onClick: () {
              onClose();
              onSelectPage(page);
            },
            [
              edumaIcon(EdumaIcons.check, size: 18),
              span([.text('Select page')]),
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
  required bool gridView,
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
        edumaIcon(term.isEmpty ? EdumaIcons.folderOpen : EdumaIcons.searchStatus, size: 26),
      ]),
      h3([.text(term.isEmpty ? 'No Assets In Space' : 'No Matching Assets')]),
      p([
        .text(
          term.isEmpty
              ? 'Documents, diagrams, code snippets, and resources uploaded to pages will appear here for quick access.'
              : 'Try adjusting your search query or filter criteria to find the asset.',
        ),
      ]),
    ]);
  }

  return div(
    classes: [
      'space-detail__cards-list',
      if (gridView) 'space-detail__cards-list--grid',
      if (gridView) 'space-detail__cards-list--assets-grid',
    ].join(' '),
    [for (final asset in visible) _assetCard(asset, gridView: gridView)],
  );
}

Component _assetCard(SpaceAsset asset, {required bool gridView}) {
  final ext = asset.extension.toUpperCase();
  final date = _formatMonthDay(asset.createdAt);
  final head = [
    if (ext.isNotEmpty) ext,
    if (asset.size.trim().isNotEmpty) asset.size.trim(),
  ].join(' · ');
  final location = (asset.pageTitle ?? '').trim().isNotEmpty ? asset.pageTitle! : 'Space files';
  final meta = [if (head.isNotEmpty) head, date, location].join(' • ');
  final uri = Uri.tryParse(asset.url.trim());
  final safeUrl = uri != null && uri.hasAuthority && (uri.scheme == 'http' || uri.scheme == 'https');
  final isLink = asset.assetType.toLowerCase() == 'link';
  final previewUrl = _assetPreviewUrl(asset, uri, safeUrl);

  final inner = [
    span(classes: 'space-detail__asset-leading', [
      edumaIcon(_assetIcon(asset), size: 20),
      if (previewUrl != null)
        img(
          src: previewUrl,
          alt: '',
          attributes: {'aria-hidden': 'true', 'draggable': 'false', 'loading': 'lazy'},
          events: {
            'error': (event) {
              final target = event.currentTarget;
              if (target != null && target.isA<web.HTMLElement>()) {
                (target as web.HTMLElement).style.display = 'none';
              }
            },
          },
        ),
    ]),
    div(classes: 'space-detail__card-body', [
      strong(classes: 'space-detail__card-title', [.text(asset.displayName)]),
      span(classes: 'space-detail__card-meta', [.text(meta)]),
    ]),
    if (!gridView)
      span(classes: 'space-detail__card-chevron', [
        edumaIcon(EdumaIcons.chevronRight, size: 14),
      ]),
  ];

  final classes = [
    'space-detail__item-card',
    'space-detail__asset-card',
    if (gridView) 'space-detail__asset-card--grid',
  ].join(' ');
  if (!safeUrl) return div(classes: classes, inner);
  if (isLink) {
    return a(
      href: uri.toString(),
      target: Target.blank,
      attributes: {
        'rel': 'noopener noreferrer',
        'title': 'Open ${asset.displayName}',
      },
      classes: classes,
      inner,
    );
  }

  final previewRoute = Uri(
    path: '/filePreview',
    queryParameters: {'spaceId': asset.spaceId, 'assetId': asset.id},
  ).toString();
  return edumaLink(
    to: previewRoute,
    classes: classes,
    attributes: {'aria-label': 'Preview ${asset.displayName}'},
    children: inner,
  );
}

Object _assetIcon(SpaceAsset asset) => switch (asset.assetType.toLowerCase()) {
  'link' => EdumaIcons.link,
  'image' || 'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'avif' || 'bmp' => EdumaIcons.image,
  'document' => EdumaIcons.document,
  _ => EdumaIcons.folderOpen,
};

String? _assetPreviewUrl(SpaceAsset asset, Uri? uri, bool safeUrl) {
  if (!safeUrl || uri == null) return null;
  final extension = asset.extension.toLowerCase();
  final isImage =
      {'image', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'avif', 'bmp'}.contains(asset.assetType.toLowerCase()) ||
      switch (extension) {
        'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'avif' || 'bmp' => true,
        _ => false,
      };
  if (isImage) return uri.toString();

  const driveHosts = {'drive.google.com', 'drive.usercontent.google.com', 'docs.google.com'};
  if (!driveHosts.contains(uri.host.toLowerCase())) return null;
  final queryId = uri.queryParameters['id'];
  final driveId = queryId?.isNotEmpty == true
      ? queryId
      : uri.pathSegments.length >= 3 &&
            {'file', 'document', 'spreadsheets', 'presentation'}.contains(uri.pathSegments[0]) &&
            uri.pathSegments[1] == 'd'
      ? uri.pathSegments[2]
      : null;
  return driveId == null ? null : Uri.https('drive.google.com', '/thumbnail', {'id': driveId, 'sz': 'w480'}).toString();
}

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
              (e) => e.title.toLowerCase().contains(term) || (e.description?.toLowerCase().contains(term) ?? false),
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
          event.location == null || event.location!.isEmpty ? timeRange : '$timeRange • ${event.location}',
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
}) => EdumaSheetDialog(
  id: 'space-members-dialog',
  open: open,
  title: 'Members (${members.length})',
  subtitle: 'People with access to this space',
  onClose: onClose,
  actions: [
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
  ],
  body: [
    spaceDetailMembersTab(
      members: members,
      currentUserId: currentUserId,
      canManageMembers: canManageMembers,
      isOwner: isOwner,
      mutatingMemberIds: mutatingMemberIds,
      onToggleAdmin: onToggleAdmin,
      onRemoveMember: onRemoveMember,
    ),
  ],
);

/// Modal list matching `ArchivedPagesSheet` in `../eduma`.
Component spaceArchivedPagesModal({
  required bool open,
  required List<SpacePage> archivedPages,
  required bool canManagePages,
  required Set<String> mutatingPageIds,
  required VoidCallback onClose,
  required ValueChanged<SpacePage> onRestorePage,
  required ValueChanged<SpacePage> onDeletePage,
}) => EdumaSheetDialog(
  id: 'space-archived-dialog',
  open: open,
  title: 'Archived pages',
  subtitle: archivedPages.isEmpty ? 'Hidden from the Pages tab' : '${archivedPages.length} hidden from the Pages tab',
  onClose: onClose,
  body: [
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
  ],
);

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
