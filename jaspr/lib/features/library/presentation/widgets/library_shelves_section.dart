import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../../../core/presentation/eduma_icons.dart';
import '../../../auth/data/auth_api.dart';
import '../../data/library_models.dart';
import 'library_document_card.dart';

/// "Recents" strip matching `LibraryRecentsStrip` in `../eduma`: section header
/// with `'See all'`, horizontal row of cards matching the active `LibraryCardStyle`.
Component libraryRecentsStrip({
  required List<LibraryDocument> recents,
  required LibraryCardStyle cardStyle,
  required bool searching,
  required ValueChanged<LibraryDocument> onOpenDoc,
  required VoidCallback onSeeAll,
}) {
  if (recents.isEmpty) return div([]);
  return section(classes: 'eduma-library__section', [
    div(classes: 'eduma-library__section-head', [
      h2([.text(searching ? 'In your recents' : 'Recents')]),
      button(
        classes: 'main-home__see-all-btn',
        type: ButtonType.button,
        onClick: onSeeAll,
        [.text('See all'), edumaIcon(EdumaIcons.chevronRight, size: 11)],
      ),
    ]),
    div(
      classes: cardStyle == .wide
          ? 'eduma-library__recents-strip is-wide'
          : 'eduma-library__recents-strip',
      [
        for (final doc in recents.take(12))
          libraryDocumentCard(
            doc,
            style: cardStyle,
            onOpen: () => onOpenDoc(doc),
          ),
      ],
    ),
  ]);
}

/// "Your groups" rounded `PinnedBand` matching `LibraryShelvesSection` + `LibraryShelfCard`
/// + `_NewGroupCard` in `../eduma`.
Component libraryShelvesSection({
  required List<LibraryGroup> groups,
  required List<LibraryCollection> collections,
  required String query,
  required VoidCallback onNewGroup,
  required ValueChanged<LibraryGroup> onSelectGroup,
  required ValueChanged<LibraryCollection> onSelectCollection,
}) {
  final term = query.trim().toLowerCase();
  final shownGroups = term.isEmpty
      ? groups
      : groups.where((g) => g.name.toLowerCase().contains(term)).toList();

  if (shownGroups.isEmpty && term.isNotEmpty) {
    return div([]);
  }

  return section(classes: 'eduma-library__shelves-band', [
    div(classes: 'eduma-library__section-head', [
      h2([.text(term.isNotEmpty ? 'Matching groups' : 'Your groups')]),
      if (term.isEmpty)
        button(
          classes: 'main-home__see-all-btn',
          type: ButtonType.button,
          onClick: onNewGroup,
          [.text('See all'), edumaIcon(EdumaIcons.chevronRight, size: 11)],
        ),
    ]),
    div(classes: 'eduma-library__shelves-row', [
      for (final group in shownGroups)
        _shelfCard(
          title: group.name,
          subtitle: group.documentIds.isEmpty
              ? 'Nothing here'
              : '${group.documentIds.length} ${group.documentIds.length == 1 ? 'book' : 'books'}',
          isCollection: false,
          tint: group.tint,
          previewIds: group.documentIds.take(3).toList(),
          coverUrl: null,
          onTap: () => onSelectGroup(group),
        ),
      if (term.isEmpty)
        button(
          classes: 'eduma-library__new-group-card',
          type: ButtonType.button,
          onClick: onNewGroup,
          [
            span(classes: 'eduma-library__new-group-icon', [
              edumaIcon(EdumaIcons.folderOpen, size: 21),
            ]),
            div(classes: 'eduma-library__new-group-copy', [
              strong([.text('New group')]),
              span([
                .text(
                  groups.isEmpty && collections.isEmpty
                      ? 'Keep books together, like a folder'
                      : 'Another set of books',
                ),
              ]),
            ]),
          ],
        ),
    ]),
  ]);
}

Component _shelfCard({
  required String title,
  required String subtitle,
  required bool isCollection,
  required LibraryGroupTint tint,
  required List<String> previewIds,
  required String? coverUrl,
  required VoidCallback onTap,
}) {
  final thumbUrls = [
    if (coverUrl != null && coverUrl.isNotEmpty) coverUrl,
    for (final docId in previewIds)
      '$edumaApiBaseUrl/library/documents/${Uri.encodeComponent(docId)}/thumbnail?sz=w200&w=200',
  ];

  return button(
    classes: 'eduma-library__shelf-card',
    type: ButtonType.button,
    attributes: {'style': '--shelf-start: ${tint.startHex}; --shelf-end: ${tint.endHex};'},
    onClick: onTap,
    [
      div(classes: 'eduma-library__shelf-covers', [
        if (thumbUrls.isNotEmpty)
          img(
            src: thumbUrls.first,
            alt: '',
            attributes: {'loading': 'lazy', 'aria-hidden': 'true', 'style': 'opacity: 0;'},
            events: {
              'load': (event) {
                final target = event.currentTarget;
                if (target != null && target.isA<web.HTMLElement>()) {
                  (target as web.HTMLElement).style.opacity = '1';
                }
              },
              'error': (event) {
                final target = event.currentTarget;
                if (target != null && target.isA<web.HTMLElement>()) {
                  (target as web.HTMLElement).style.display = 'none';
                }
              },
            },
          )
        else
          span(classes: 'eduma-library__shelf-covers-empty', [
            edumaIcon(EdumaIcons.folderOpen, size: 18),
          ]),
      ]),
      div(classes: 'eduma-library__shelf-copy', [
        if (isCollection) span(classes: 'eduma-library__shelf-badge', [.text('COLLECTION')]),
        strong([.text(title)]),
        span(classes: 'eduma-library__shelf-sub', [.text(subtitle)]),
      ]),
    ],
  );
}

/// Filter chips (`All`, `Collections`, `In my groups`, dynamic categories)
/// + trailing 38px `_SortButton` matching `LibraryFilterRow` in `../eduma`.
Component libraryFilterRow({
  required List<String> categories,
  required LibraryShowFilter showFilter,
  required String selectedCategory,
  required bool hasCollections,
  required bool hasGroups,
  required LibrarySort sort,
  required LibraryCardStyle cardStyle,
  required ValueChanged<LibraryShowFilter> onSelectShow,
  required ValueChanged<String> onSelectCategory,
  required VoidCallback onOpenSortMenu,
}) => div(classes: 'eduma-library__filter-row', [
  div(classes: 'eduma-library__filter-chips', [
    button(
      classes: showFilter == .everything && selectedCategory.isEmpty
          ? 'eduma-pill-button is-active'
          : 'eduma-pill-button',
      type: ButtonType.button,
      onClick: () => onSelectCategory(''),
      [.text('All')],
    ),
    if (hasCollections || showFilter == .collections)
      button(
        classes: showFilter == .collections
            ? 'eduma-pill-button is-active'
            : 'eduma-pill-button',
        type: ButtonType.button,
        onClick: () => onSelectShow(.collections),
        [edumaIcon(EdumaIcons.archive, size: 14), .text('Collections')],
      ),
    if (hasGroups || showFilter == .grouped)
      button(
        classes: showFilter == .grouped
            ? 'eduma-pill-button is-active'
            : 'eduma-pill-button',
        type: ButtonType.button,
        onClick: () => onSelectShow(.grouped),
        [edumaIcon(EdumaIcons.folderOpen, size: 14), .text('In my groups')],
      ),
    for (final category in categories)
      button(
        classes: showFilter == .everything && selectedCategory == category
            ? 'eduma-pill-button is-active'
            : 'eduma-pill-button',
        type: ButtonType.button,
        onClick: () => onSelectCategory(category),
        [.text(category)],
      ),
  ]),
  button(
    classes: 'eduma-library__sort-btn',
    type: ButtonType.button,
    attributes: {
      'aria-label': 'Sort and card view (${sort.label}, ${cardStyle.label})',
      'title': 'Sort & view: ${sort.label}, ${cardStyle.label.toLowerCase()} cards',
    },
    onClick: onOpenSortMenu,
    [edumaIcon(EdumaIcons.sort, size: 18)],
  ),
]);
