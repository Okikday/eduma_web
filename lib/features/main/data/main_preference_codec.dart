import 'main_space.dart';

/// Pure preference codec shared between browser Hive storage and unit tests,
/// keeping key names and values compatible with Flutter's `AppPrefs`.
abstract final class MainPreferenceCodec {
  static const spaceCardStyleKey = 'eduma_pref_space_card_style';
  static const spaceContentStyleKey = 'eduma_pref_space_content_style';
  static const spaceAssetStyleKey = 'eduma_pref_space_asset_style';
  static const spaceSortKey = 'eduma_pref_space_sort';

  static bool parseSpaceGridView(Object? raw) => '$raw'.trim() == 'grid';

  static String serializeSpaceGridView(bool grid) => grid ? 'grid' : 'list';

  static bool parseSpaceContentGridView(Object? raw) => '$raw'.trim() == 'grid';

  static String serializeSpaceContentGridView(bool grid) => grid ? 'grid' : 'list';

  static bool parseSpaceAssetGridView(Object? raw) => '$raw'.trim() == 'grid';

  static String serializeSpaceAssetGridView(bool grid) => grid ? 'grid' : 'list';

  static MainSpaceSort parseSpaceSort(Object? raw) => switch ('$raw'.trim()) {
    'name' => MainSpaceSort.name,
    'date' || 'created' => MainSpaceSort.date,
    'accessed' => MainSpaceSort.accessed,
    _ => MainSpaceSort.recent,
  };

  static String serializeSpaceSort(MainSpaceSort sort) => switch (sort) {
    MainSpaceSort.recent => 'recent',
    MainSpaceSort.name => 'name',
    MainSpaceSort.date => 'created',
    MainSpaceSort.accessed => 'accessed',
  };
}
