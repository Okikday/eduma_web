import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../data/main_space.dart';
import 'main_home_icons.dart';

/// Search input and anchored filter/sort/view popup menu for Spaces.
Component mainHomeSearchBar({
  required String query,
  required MainSpaceFilter filter,
  required MainSpaceSort sort,
  required bool gridView,
  required ValueChanged<String> onSearch,
  required ValueChanged<bool> onFocusChanged,
  required ValueChanged<MainSpaceFilter> onSelectFilter,
  required ValueChanged<MainSpaceSort> onSelectSort,
  required ValueChanged<bool> onSelectGridView,
  required VoidCallback onResetFilters,
}) => _MainHomeSearchBar(
  query: query,
  filter: filter,
  sort: sort,
  gridView: gridView,
  onSearch: onSearch,
  onFocusChanged: onFocusChanged,
  onSelectFilter: onSelectFilter,
  onSelectSort: onSelectSort,
  onSelectGridView: onSelectGridView,
  onResetFilters: onResetFilters,
);

class _MainHomeSearchBar extends StatefulComponent {
  const _MainHomeSearchBar({
    required this.query,
    required this.filter,
    required this.sort,
    required this.gridView,
    required this.onSearch,
    required this.onFocusChanged,
    required this.onSelectFilter,
    required this.onSelectSort,
    required this.onSelectGridView,
    required this.onResetFilters,
  });

  final String query;
  final MainSpaceFilter filter;
  final MainSpaceSort sort;
  final bool gridView;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool> onFocusChanged;
  final ValueChanged<MainSpaceFilter> onSelectFilter;
  final ValueChanged<MainSpaceSort> onSelectSort;
  final ValueChanged<bool> onSelectGridView;
  final VoidCallback onResetFilters;

  @override
  State<_MainHomeSearchBar> createState() => _MainHomeSearchBarState();
}

class _MainHomeSearchBarState extends State<_MainHomeSearchBar> {
  bool _menuOpen = false;
  JSFunction? _keydownListener;

  @override
  void initState() {
    super.initState();
    _keydownListener = ((web.KeyboardEvent event) {
      if (_menuOpen && event.key == 'Escape') {
        _setMenuOpen(false);
      }
    }).toJS;
    web.window.addEventListener('keydown', _keydownListener);
  }

  @override
  void dispose() {
    if (_keydownListener != null) {
      web.window.removeEventListener('keydown', _keydownListener);
    }
    super.dispose();
  }

  void _setMenuOpen(bool open) {
    if (!mounted || _menuOpen == open) return;
    setState(() => _menuOpen = open);
  }

  @override
  Component build(BuildContext context) {
    final hasActiveFilter = component.filter != .all || component.sort != .recent;

    return div(classes: 'main-home__search-row', [
      div(classes: 'main-home__search', [
        mainHomeIcon(.searchStatus, size: 18),
        input<String>(
          type: InputType.search,
          value: component.query,
          attributes: {
            'aria-label': 'Search spaces',
            'autocomplete': 'off',
            'autocorrect': 'off',
            'autocapitalize': 'none',
            'enterkeyhint': 'search',
            'placeholder': 'Try a space name',
            'spellcheck': 'false',
          },
          events: {
            'focus': (_) => component.onFocusChanged(true),
            'blur': (_) => component.onFocusChanged(false),
          },
          onInput: component.onSearch,
        ),
        if (component.query.isNotEmpty)
          button(
            classes: 'main-home__clear-search',
            type: ButtonType.button,
            attributes: {'aria-label': 'Clear search', 'title': 'Clear search'},
            events: {'mousedown': (e) => e.preventDefault()},
            onClick: () => component.onSearch(''),
            [mainHomeIcon(.closePlain, size: 18)],
          ),
      ]),
      div(
        classes: 'main-home__filter-disclosure${_menuOpen ? ' is-open' : ''}',
        [
          button(
            id: 'main-home-filter-trigger',
            classes: 'main-home__filter-trigger${hasActiveFilter ? ' is-active' : ''}',
            type: ButtonType.button,
            attributes: {
              'aria-label': 'Filter & sort',
              'aria-haspopup': 'menu',
              'aria-expanded': '$_menuOpen',
              'title': 'Filter and sort spaces',
            },
            onClick: () => _setMenuOpen(!_menuOpen),
            [mainHomeIcon(.filter, size: 18)],
          ),
          if (_menuOpen) ...[
            div(
              classes: 'main-home__filter-backdrop',
              attributes: {'aria-hidden': 'true'},
              events: {'click': (_) => _setMenuOpen(false)},
              const [],
            ),
            div(
              id: 'main-home-filter-menu',
              classes: 'main-home__filter-menu',
              attributes: {'role': 'menu', 'aria-label': 'Filter and sort'},
              [
                _filterMenuSection('SHOW', [
                  for (final item in MainSpaceFilter.values)
                    _filterMenuItem(
                      _filterIconFor(item),
                      item.label,
                      component.filter == item,
                      () {
                        component.onSelectFilter(item);
                        _setMenuOpen(false);
                      },
                    ),
                ]),
                _filterMenuSection('SORT BY', [
                  for (final item in MainSpaceSort.values)
                    _filterMenuItem(
                      _sortIconFor(item),
                      item.label,
                      component.sort == item,
                      () {
                        component.onSelectSort(item);
                        _setMenuOpen(false);
                      },
                    ),
                ]),
                _filterMenuSection('VIEW', [
                  _filterMenuItem(.list, 'List', !component.gridView, () {
                    component.onSelectGridView(false);
                    _setMenuOpen(false);
                  }),
                  _filterMenuItem(.grid, 'Grid', component.gridView, () {
                    component.onSelectGridView(true);
                    _setMenuOpen(false);
                  }),
                ]),
                if (hasActiveFilter)
                  div(classes: 'main-home__filter-group', [
                    button(
                      classes: 'main-home__reset-filters',
                      type: ButtonType.button,
                      onClick: () {
                        component.onResetFilters();
                        _setMenuOpen(false);
                      },
                      [
                        mainHomeIcon(.refresh, size: 16),
                        span(
                          classes: 'main-home__filter-label',
                          [.text('Reset filters')],
                        ),
                      ],
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

Component _filterMenuSection(String title, List<Component> options) => div(
  classes: 'main-home__filter-group',
  [
    strong([.text(title)]),
    ...options,
  ],
);

Component _filterMenuItem(
  MainHomeIcon icon,
  String title,
  bool selected,
  VoidCallback onClick,
) => button(
  classes: 'main-home__filter-option',
  type: ButtonType.button,
  attributes: {
    'role': 'menuitemradio',
    'aria-checked': '$selected',
    'aria-pressed': '$selected',
  },
  onClick: onClick,
  [
    span(
      classes: 'main-home__filter-option-icon',
      [mainHomeIcon(icon, size: 16)],
    ),
    span(classes: 'main-home__filter-label', [.text(title)]),
    if (selected)
      span(
        classes: 'main-home__filter-option-check',
        [mainHomeIcon(.check, size: 16)],
      ),
  ],
);

MainHomeIcon _filterIconFor(MainSpaceFilter filter) => switch (filter) {
  .all => .layer,
  .owned => .owner,
  .joined => .people,
  .pinned => .pin,
};

MainHomeIcon _sortIconFor(MainSpaceSort sort) => switch (sort) {
  .recent => .clock,
  .name => .sort,
  .date => .calendar,
  .accessed => .eye,
};
