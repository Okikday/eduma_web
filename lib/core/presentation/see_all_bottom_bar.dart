import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'eduma_icons.dart';

/// Floating search + optional circular Filter popup docked at the bottom of
/// `adaptivePageScaffold` See-All screens, matching `SeeAllBottomBar` in `../eduma`.
Component seeAllBottomBar({
  required String query,
  required String hintText,
  required ValueChanged<String> onQueryChanged,
  bool filterFirst = false,
  bool filterActive = false,
  bool filterMenuOpen = false,
  VoidCallback? onToggleFilterMenu,
  VoidCallback? onCloseFilterMenu,
  List<Component> filterMenuChildren = const [],
  String? sortLabel,
  VoidCallback? onCycleSort,
}) {
  final hasFilter = onToggleFilterMenu != null && filterMenuChildren.isNotEmpty;
  final searchPill = div(classes: 'eduma-see-all-bar__pill', [
    span(classes: 'eduma-see-all-bar__icon', [
      edumaIcon(EdumaIcons.search, size: 18),
    ]),
    input(
      classes: 'eduma-see-all-bar__input',
      type: InputType.search,
      value: query,
      attributes: {'placeholder': hintText, 'aria-label': hintText},
      onInput: (dynamic val) => onQueryChanged('${val ?? ''}'),
    ),
    if (query.trim().isNotEmpty)
      button(
        classes: 'eduma-see-all-bar__clear',
        type: ButtonType.button,
        attributes: {'aria-label': 'Clear search'},
        onClick: () => onQueryChanged(''),
        [edumaIcon(EdumaIcons.closePlain, size: 16)],
      ),
  ]);

  final filterControl = hasFilter
      ? div(classes: 'eduma-see-all-bar__filter-wrap', [
          button(
            classes: [
              'eduma-see-all-bar__filter-btn',
              if (filterActive || filterMenuOpen) 'is-active',
            ].join(' '),
            type: ButtonType.button,
            attributes: {
              'aria-label': 'Filter & sort',
              'aria-haspopup': 'menu',
              'aria-expanded': '$filterMenuOpen',
              'title': 'Filter & sort',
            },
            onClick: onToggleFilterMenu,
            [edumaIcon(EdumaIcons.filter, size: 19)],
          ),
          if (filterMenuOpen) ...[
            div(
              classes: 'eduma-see-all-bar__backdrop',
              attributes: {'aria-hidden': 'true'},
              events: {'click': (_) => (onCloseFilterMenu ?? onToggleFilterMenu)()},
              const [],
            ),
            div(
              classes: filterFirst
                  ? 'eduma-see-all-bar__menu eduma-see-all-bar__menu--left'
                  : 'eduma-see-all-bar__menu',
              attributes: {'role': 'menu', 'aria-label': 'Filter and sort'},
              filterMenuChildren,
            ),
          ],
        ])
      : null;

  final legacySortButton = !hasFilter && sortLabel != null && onCycleSort != null
      ? button(
          classes: 'eduma-see-all-bar__sort',
          type: ButtonType.button,
          attributes: {'aria-label': 'Sort: $sortLabel', 'title': 'Sort: $sortLabel'},
          onClick: onCycleSort,
          [
            edumaIcon(EdumaIcons.sort, size: 16),
            span([.text(sortLabel)]),
          ],
        )
      : null;

  return div(
    classes: 'eduma-see-all-bar',
    [
      div(classes: 'eduma-see-all-bar__inner', [
        if (filterFirst && filterControl != null) filterControl,
        searchPill,
        if (!filterFirst && filterControl != null) filterControl,
        if (legacySortButton != null) legacySortButton,
      ]),
    ],
  );
}

/// Titled option group for [seeAllBottomBar]'s anchored popup menu.
Component seeAllFilterGroup(String title, List<Component> children) => div(
  classes: 'eduma-see-all-bar__menu-group',
  [
    span(classes: 'eduma-see-all-bar__menu-title', [.text(title)]),
    ...children,
  ],
);

/// Selectable row inside [seeAllBottomBar]'s popup menu.
Component seeAllFilterOption({
  required Object icon,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) => button(
  classes: 'eduma-see-all-bar__menu-item',
  type: ButtonType.button,
  attributes: {
    'role': 'menuitemradio',
    'aria-checked': '$selected',
    'aria-pressed': '$selected',
  },
  onClick: onTap,
  [
    span(classes: 'eduma-see-all-bar__menu-icon', [edumaIcon(icon, size: 16)]),
    span(classes: 'eduma-see-all-bar__menu-label', [.text(label)]),
    if (selected)
      span(classes: 'eduma-see-all-bar__menu-check', [
        edumaIcon(EdumaIcons.check, size: 15),
      ]),
  ],
);
