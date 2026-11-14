import '../data/main_space.dart';

abstract final class MainSpaceQuery {
  static List<MainSpace> apply(
    List<MainSpace> spaces, {
    MainSpaceFilter filter = .all,
    MainSpaceSort sort = .recent,
  }) {
    final filtered = [
      for (final space in spaces)
        if (_matches(space, filter)) space,
    ];
    final indexed = filtered.indexed.toList();
    indexed.sort((a, b) {
      final aSpace = a.$2;
      final bSpace = b.$2;
      if (aSpace.isPersonal != bSpace.isPersonal) {
        return aSpace.isPersonal ? -1 : 1;
      }

      final order = switch (sort) {
        .recent => _compareDates(aSpace.updatedAt, bSpace.updatedAt),
        .date => _compareDates(aSpace.createdAt, bSpace.createdAt),
        .accessed => _compareDates(
          aSpace.lastAccessedAt ?? aSpace.updatedAt,
          bSpace.lastAccessedAt ?? bSpace.updatedAt,
        ),
        .name => aSpace.title.toLowerCase().compareTo(
          bSpace.title.toLowerCase(),
        ),
      };
      return order == 0 ? a.$1.compareTo(b.$1) : order;
    });
    return [for (final (_, space) in indexed) space];
  }

  static bool _matches(MainSpace space, MainSpaceFilter filter) => switch (filter) {
    .all => true,
    .owned => space.role == .owner,
    .joined => space.role != .owner,
    .pinned => space.isPinned,
  };

  static int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
