import '../../features/calendar/data/calendar_models.dart';
import '../../features/library/data/library_models.dart';
import '../../features/main/data/main_canvas.dart';
import '../../features/main/data/main_space.dart';
import '../../features/notifications/data/notifications_models.dart';
import '../../features/profile/data/profile_models.dart';
import '../../features/space/data/space_detail_api.dart';
import '../../features/streak/data/streak_models.dart';

/// In-memory session-scoped cache for tab and detail screens so switching tabs
/// or revisiting a space renders cached data immediately instead of flashing
/// empty loading states, while refreshing silently in the background.
final class EdumaMemoryCache {
  EdumaMemoryCache._();

  static final EdumaMemoryCache instance = EdumaMemoryCache._();

  String _userId = '';

  HomeCacheData? home;
  LibraryCacheData? library;
  ProfileStats? profileStats;
  NotificationsCacheData? notifications;
  StreakSummaryData? streakSummary;
  final Map<LeaderboardScope, LeaderboardResponseData> streakBoards = {};
  final Map<String, List<CalendarEvent>> calendarMonths = {};
  final Map<String, SpaceDetailBundle> spaces = {};
  int? unreadNotifications;

  /// Ensures cached entries belong to [userId]; clears stale data on account switch.
  void ensureUser(String userId) {
    if (_userId == userId) return;
    clear();
    _userId = userId;
  }

  /// Clears all cached data (e.g. on sign out).
  void clear() {
    _userId = '';
    home = null;
    library = null;
    profileStats = null;
    notifications = null;
    streakSummary = null;
    streakBoards.clear();
    calendarMonths.clear();
    spaces.clear();
    unreadNotifications = null;
  }

  static String monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
}

final class HomeCacheData {
  const HomeCacheData({
    required this.spaces,
    required this.pinnedSpaces,
    required this.recentCanvases,
    required this.hasMore,
    this.streakCount = 0,
    this.streakTodayMinutes = 0,
    this.streakGoalMinutes = 5,
  });

  final List<MainSpace> spaces;
  final List<MainSpace> pinnedSpaces;
  final List<MainCanvas> recentCanvases;
  final bool hasMore;
  final int streakCount;
  final int streakTodayMinutes;
  final int streakGoalMinutes;

  HomeCacheData copyWith({
    List<MainSpace>? spaces,
    List<MainSpace>? pinnedSpaces,
    List<MainCanvas>? recentCanvases,
    bool? hasMore,
    int? streakCount,
    int? streakTodayMinutes,
    int? streakGoalMinutes,
  }) => HomeCacheData(
    spaces: spaces ?? this.spaces,
    pinnedSpaces: pinnedSpaces ?? this.pinnedSpaces,
    recentCanvases: recentCanvases ?? this.recentCanvases,
    hasMore: hasMore ?? this.hasMore,
    streakCount: streakCount ?? this.streakCount,
    streakTodayMinutes: streakTodayMinutes ?? this.streakTodayMinutes,
    streakGoalMinutes: streakGoalMinutes ?? this.streakGoalMinutes,
  );
}

final class LibraryCacheData {
  const LibraryCacheData({
    required this.documents,
    required this.categories,
    required this.hasMore,
    required this.recents,
    required this.groups,
    required this.collections,
  });

  final List<LibraryDocument> documents;
  final List<String> categories;
  final bool hasMore;
  final List<LibraryDocument> recents;
  final List<LibraryGroup> groups;
  final List<LibraryCollection> collections;
}

final class NotificationsCacheData {
  const NotificationsCacheData({
    required this.items,
    required this.unreadCount,
    required this.hasMore,
  });

  final List<EdumaNotification> items;
  final int unreadCount;
  final bool hasMore;
}
