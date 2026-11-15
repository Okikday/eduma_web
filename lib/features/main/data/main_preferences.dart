import '../../auth/data/auth_api.dart';
import 'main_preference_codec.dart';
import 'main_space.dart';

class MainUserPreferences {
  const MainUserPreferences({
    this.spaceGridView = false,
    this.spaceSort = MainSpaceSort.recent,
  });

  final bool spaceGridView;
  final MainSpaceSort spaceSort;
}

/// Persists Home view/sort preferences in the shared `kickin_box` Hive store
/// using the exact keys read by Flutter's `AppPrefs`.
class MainPreferences {
  MainPreferences._();

  static final instance = MainPreferences._();

  Future<MainUserPreferences> load() async {
    try {
      final box = await EdumaAuthApi.instance.openSharedBox();
      final cardStyle = await box.get(MainPreferenceCodec.spaceCardStyleKey);
      final sort = await box.get(MainPreferenceCodec.spaceSortKey);
      return MainUserPreferences(
        spaceGridView: MainPreferenceCodec.parseSpaceGridView(cardStyle),
        spaceSort: MainPreferenceCodec.parseSpaceSort(sort),
      );
    } catch (_) {
      return const MainUserPreferences();
    }
  }

  Future<void> saveSpaceGridView(bool grid) async {
    try {
      final box = await EdumaAuthApi.instance.openSharedBox();
      await box.put(
        MainPreferenceCodec.spaceCardStyleKey,
        MainPreferenceCodec.serializeSpaceGridView(grid),
      );
    } catch (_) {
      // Preference persistence is best-effort if IndexedDB is unavailable.
    }
  }

  Future<void> saveSpaceSort(MainSpaceSort sort) async {
    try {
      final box = await EdumaAuthApi.instance.openSharedBox();
      await box.put(
        MainPreferenceCodec.spaceSortKey,
        MainPreferenceCodec.serializeSpaceSort(sort),
      );
    } catch (_) {
      // Preference persistence is best-effort if IndexedDB is unavailable.
    }
  }
}
