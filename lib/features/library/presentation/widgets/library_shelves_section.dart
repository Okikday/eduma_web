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
      classes: cardStyle == .wide ? 'eduma-library__recents-strip is-wide' : 'eduma-library__recents-strip',
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
  final shownGroups = term.isEmpty ? groups : groups.where((g) => g.name.toLowerCase().contains(term)).toList();

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
                  groups.isEmpty && collections.isEmpty ? 'Keep books together, like a folder' : 'Another set of books',
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
/// + a sort/view menu anchored to its trigger, like the Home filter popup.
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
  required ValueChanged<LibrarySort> onSelectSort,
  required ValueChanged<LibraryCardStyle> onSelectCardStyle,
}) => _LibraryFilterRow(
  categories: categories,
  showFilter: showFilter,
  selectedCategory: selectedCategory,
  hasCollections: hasCollections,
  hasGroups: hasGroups,
  sort: sort,
  cardStyle: cardStyle,
  onSelectShow: onSelectShow,
  onSelectCategory: onSelectCategory,
  onSelectSort: onSelectSort,
  onSelectCardStyle: onSelectCardStyle,
);

class _LibraryFilterRow extends StatefulComponent {
  const _LibraryFilterRow({
    required this.categories,
    required this.showFilter,
    required this.selectedCategory,
    required this.hasCollections,
    required this.hasGroups,
    required this.sort,
    required this.cardStyle,
    required this.onSelectShow,
    required this.onSelectCategory,
    required this.onSelectSort,
    required this.onSelectCardStyle,
  });

  final List<String> categories;
  final LibraryShowFilter showFilter;
  final String selectedCategory;
  final bool hasCollections;
  final bool hasGroups;
  final LibrarySort sort;
  final LibraryCardStyle cardStyle;
  final ValueChanged<LibraryShowFilter> onSelectShow;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<LibrarySort> onSelectSort;
  final ValueChanged<LibraryCardStyle> onSelectCardStyle;

  @override
  State<_LibraryFilterRow> createState() => _LibraryFilterRowState();
}

class _LibraryFilterRowState extends State<_LibraryFilterRow> {
  bool _menuOpen = false;
  JSFunction? _keydownListener;

  @override
  void initState() {
    super.initState();
    _keydownListener = ((web.KeyboardEvent event) {
      if (_menuOpen && event.key == 'Escape') _setMenuOpen(false);
    }).toJS;
    web.window.addEventListener('keydown', _keydownListener);
  }

  @override
  void dispose() {
    if (_keydownListener case final listener?) {
      web.window.removeEventListener('keydown', listener);
    }
    super.dispose();
  }

  void _setMenuOpen(bool open) {
    if (!mounted || _menuOpen == open) return;
    setState(() => _menuOpen = open);
  }

  @override
  Component build(BuildContext context) {
    final component = this.component;
    return div(classes: 'eduma-library__filter-row', [
      div(classes: 'eduma-library__filter-chips', [
        button(
          classes: component.showFilter == .everything && component.selectedCategory.isEmpty
              ? 'eduma-pill-button is-active'
              : 'eduma-pill-button',
          type: ButtonType.button,
          onClick: () => component.onSelectCategory(''),
          [.text('All')],
        ),
        if (component.hasCollections || component.showFilter == .collections)
          button(
            classes: component.showFilter == .collections ? 'eduma-pill-button is-active' : 'eduma-pill-button',
            type: ButtonType.button,
            onClick: () => component.onSelectShow(.collections),
            [edumaIcon(EdumaIcons.archive, size: 14), .text('Collections')],
          ),
        if (component.hasGroups || component.showFilter == .grouped)
          button(
            classes: component.showFilter == .grouped ? 'eduma-pill-button is-active' : 'eduma-pill-button',
            type: ButtonType.button,
            onClick: () => component.onSelectShow(.grouped),
            [edumaIcon(EdumaIcons.folderOpen, size: 14), .text('In my groups')],
          ),
        for (final category in component.categories)
          button(
            classes: component.showFilter == .everything && component.selectedCategory == category
                ? 'eduma-pill-button is-active'
                : 'eduma-pill-button',
            type: ButtonType.button,
            onClick: () => component.onSelectCategory(category),
            [.text(category)],
          ),
      ]),
      div(
        classes: 'main-home__filter-disclosure${_menuOpen ? ' is-open' : ''}',
        [
          button(
            classes: 'main-home__filter-trigger eduma-library__sort-trigger',
            type: ButtonType.button,
            attributes: {
              'aria-label': 'Sort and card view: ${component.sort.label}, ${component.cardStyle.label}',
              'aria-haspopup': 'menu',
              'aria-expanded': '$_menuOpen',
              'title': 'Sort & view: ${component.sort.label}, ${component.cardStyle.label.toLowerCase()} cards',
            },
            onClick: () => _setMenuOpen(!_menuOpen),
            [edumaIcon(EdumaIcons.sort, size: 18)],
          ),
          if (_menuOpen) ...[
            div(
              classes: 'main-home__filter-backdrop',
              attributes: {'aria-hidden': 'true'},
              events: {'click': (_) => _setMenuOpen(false)},
              const [],
            ),
            div(
              classes: 'main-home__filter-menu',
              attributes: {'role': 'menu', 'aria-label': 'Sort and card view'},
              [
                _libraryMenuSection('SORT BY', [
                  for (final sort in LibrarySort.values)
                    _libraryMenuOption(
                      icon: switch (sort) {
                        .popular => EdumaIcons.flash,
                        .recent => EdumaIcons.clock,
                        .title => EdumaIcons.sortAz,
                      },
                      label: sort.label,
                      selected: component.sort == sort,
                      onClick: () {
                        component.onSelectSort(sort);
                        _setMenuOpen(false);
                      },
                    ),
                ]),
                _libraryMenuSection('CARD VIEW', [
                  for (final style in LibraryCardStyle.values)
                    _libraryMenuOption(
                      icon: switch (style) {
                        .tall => EdumaIcons.grid,
                        .wide => EdumaIcons.list,
                        .normal => EdumaIcons.element3,
                      },
                      label: style.label,
                      selected: component.cardStyle == style,
                      onClick: () {
                        component.onSelectCardStyle(style);
                        _setMenuOpen(false);
                      },
                    ),
                ]),
              ],
            ),
          ],
        ],
      ),
    ]);
  }
}

Component _libraryMenuSection(String title, List<Component> items) => div(
  classes: 'main-home__filter-group',
  [
    strong([.text(title)]),
    ...items,
  ],
);

Component _libraryMenuOption({
  required EdumaIconData icon,
  required String label,
  required bool selected,
  required VoidCallback onClick,
}) => button(
  classes: 'main-home__filter-option',
  type: ButtonType.button,
  attributes: {
    'role': 'menuitemradio',
    'aria-checked': '$selected',
    'aria-pressed': '$selected',
  },
  onClick: onClick,
  [
    span(classes: 'main-home__filter-option-icon', [edumaIcon(icon, size: 16)]),
    span(classes: 'main-home__filter-label', [.text(label)]),
    if (selected) span(classes: 'main-home__filter-option-check', [edumaIcon(EdumaIcons.check, size: 16)]),
  ],
);
