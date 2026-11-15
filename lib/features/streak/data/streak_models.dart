/// One day of the streak calendar (`GET /streaks/me`).
class StreakDayEntry {
  const StreakDayEntry({
    required this.date,
    this.minutes = 0,
    this.state = 'none',
  });

  final String date;
  final int minutes;
  final String state;

  bool get studied => state == 'studied';

  String get weekdayLetter {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.isEmpty ? '' : date[0];
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return letters[(parsed.weekday - 1) % 7];
  }

  String get weekdayShort {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[parsed.weekday - 1];
  }

  static StreakDayEntry? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final date = '${raw['date'] ?? raw['day'] ?? ''}'.trim();
    if (date.length < 10) return null;
    final rawMin = raw['minutes'];
    final minutes = rawMin is num ? rawMin.toInt() : int.tryParse('$rawMin') ?? 0;
    final state = '${raw['state'] ?? (raw['studied'] == true ? 'studied' : 'none')}';
    return StreakDayEntry(date: date.substring(0, 10), minutes: minutes, state: state);
  }
}

/// Signed-in study streak summary (`GET /streaks/me` or analytics fallback).
class StreakSummaryData {
  const StreakSummaryData({
    this.today = '',
    this.current = 0,
    this.best = 0,
    this.todayMinutes = 0,
    this.goalMinutes = 5,
    this.todayDone = false,
    this.restAvailable = true,
    this.days = const [],
    this.week = const [],
  });

  static const _milestones = [3, 7, 14, 30, 50, 100, 200, 365];

  final String today;
  final int current;
  final int best;
  final int todayMinutes;
  final int goalMinutes;
  final bool todayDone;
  final bool restAvailable;
  final List<StreakDayEntry> days;
  final List<StreakDayEntry> week;

  double get progressRatio {
    if (todayDone) return 1.0;
    if (goalMinutes <= 0) return 0.0;
    return (todayMinutes / goalMinutes).clamp(0.0, 1.0).toDouble();
  }

  List<StreakDayEntry> get effectiveWeek {
    if (week.length == 7) return week;
    return buildWeekStrip(
      todayKey: today.isNotEmpty ? today : _formatDay(DateTime.now()),
      todayDone: todayDone,
      todayMinutes: todayMinutes,
      days: days,
    );
  }

  int get weekDays => effectiveWeek.where((d) => d.studied).length;

  int get weekMinutes => effectiveWeek.fold(0, (sum, d) => sum + d.minutes);

  String get headline => current == 0 ? 'Start a streak' : '$current-day streak';

  String get subline {
    if (todayDone) {
      return current > 1 ? 'Done for today. See you tomorrow.' : 'Day one done. See you tomorrow.';
    }
    final safeGoal = goalMinutes <= 0 ? 5 : goalMinutes;
    final left = (safeGoal - todayMinutes).clamp(1, safeGoal);
    if (current == 0) {
      return todayMinutes > 0
          ? '$left more min today to begin'
          : 'Study $safeGoal min today to begin';
    }
    return todayMinutes > 0
        ? '$left more min to keep it going'
        : 'Study $safeGoal min today to keep it going';
  }

  String get restLine =>
      restAvailable ? 'Rest day available this week' : 'Rest day used this week';

  String? get nextMilestoneLine {
    for (final m in _milestones) {
      if (m > current) {
        final left = m - current;
        return '$left ${left == 1 ? 'day' : 'days'} to $m';
      }
    }
    return null;
  }

  static String formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  static List<StreakDayEntry> buildWeekStrip({
    required String todayKey,
    required bool todayDone,
    required int todayMinutes,
    required List<StreakDayEntry> days,
  }) {
    final anchor = DateTime.tryParse(todayKey) ?? DateTime.now();
    final todayLocal = DateTime(anchor.year, anchor.month, anchor.day);
    final monday = todayLocal.subtract(Duration(days: todayLocal.weekday - 1));
    final byDate = {for (final d in days) d.date: d};

    return [
      for (var i = 0; i < 7; i++)
        () {
          final day = DateTime(monday.year, monday.month, monday.day + i);
          final key = _formatDay(day);
          final existing = byDate[key];
          if (existing != null) {
            if (key == todayKey && !existing.studied && existing.state == 'none') {
              return StreakDayEntry(
                date: key,
                minutes: todayMinutes > 0 ? todayMinutes : existing.minutes,
                state: todayDone ? 'studied' : 'open',
              );
            }
            return existing;
          }
          if (key == todayKey) {
            return StreakDayEntry(
              date: key,
              minutes: todayMinutes,
              state: todayDone ? 'studied' : 'open',
            );
          }
          if (day.isAfter(todayLocal)) {
            return StreakDayEntry(date: key, state: 'upcoming');
          }
          return StreakDayEntry(date: key, state: 'none');
        }(),
    ];
  }

  static StreakSummaryData fromPayload(Map<String, dynamic> payload) {
    final map = payload['streak'] is Map ? Map<String, dynamic>.from(payload['streak'] as Map) : payload;
    final todayMap = map['today'] is Map ? map['today'] as Map : const {};
    final rawDays = map['days'] ?? map['calendar'];
    final rawWeek = map['week'];
    final current = _int(map['current'] ?? map['currentStreak'] ?? map['streakDays']) ?? 0;
    final parsedDays = [
      if (rawDays is List)
        for (final item in rawDays)
          if (StreakDayEntry.fromMap(item) case final entry?) entry,
    ];
    final parsedWeek = [
      if (rawWeek is List)
        for (final item in rawWeek)
          if (StreakDayEntry.fromMap(item) case final entry?) entry,
    ];
    final rawTodayDate = map['today'] is String ? map['today'] as String : '${todayMap['date'] ?? ''}';
    final todayDate = rawTodayDate.trim().length >= 10
        ? rawTodayDate.trim().substring(0, 10)
        : _formatDay(DateTime.now());
    return StreakSummaryData(
      today: todayDate,
      current: current,
      best: _int(map['best'] ?? map['bestStreak'] ?? map['longest']) ?? current,
      todayMinutes: _int(todayMap['minutes'] ?? map['todayMinutes']) ?? 0,
      goalMinutes: _int(todayMap['goalMinutes'] ?? map['goalMinutes']) ?? 5,
      todayDone: todayMap['done'] == true || todayMap['qualified'] == true || map['todayDone'] == true,
      restAvailable: map['restAvailable'] != false && map['freezeAvailable'] != false,
      days: parsedDays,
      week: parsedWeek,
    );
  }

  static String _formatDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int? _int(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse('${raw ?? ''}');
  }
}

/// Who a weekly leaderboard ranks.
enum LeaderboardScope {
  spaces('Your spaces'),
  global('Everyone');

  const LeaderboardScope(this.label);

  final String label;
}

/// Thrown when the leaderboard API endpoint is not yet enabled on the server.
class StreakLeaderboardUnavailableException implements Exception {
  const StreakLeaderboardUnavailableException();
}

/// Single ranked learner row inside a weekly leaderboard response.
class LeaderboardEntryData {
  const LeaderboardEntryData({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.days = 0,
    this.minutes = 0,
    this.isMe = false,
  });

  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int days;
  final int minutes;
  final bool isMe;

  static int? _parseInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');

  static LeaderboardEntryData? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final rank = _parseInt(raw['rank']);
    if (rank == null) return null;
    final avatarRaw = '${raw['avatarUrl'] ?? raw['avatar'] ?? ''}'.trim();
    return LeaderboardEntryData(
      rank: rank,
      userId: '${raw['userId'] ?? raw['user'] ?? raw['_id'] ?? raw['id'] ?? ''}',
      name: '${raw['name'] ?? raw['fullName'] ?? raw['username'] ?? 'Student'}',
      avatarUrl: avatarRaw.isEmpty ? null : avatarRaw,
      days: _parseInt(raw['days'] ?? raw['studiedDays']) ?? 0,
      minutes: _parseInt(raw['minutes'] ?? raw['totalMinutes']) ?? 0,
      isMe: raw['isMe'] == true,
    );
  }
}

/// Server leaderboard payload for a given [scope].
class LeaderboardResponseData {
  const LeaderboardResponseData({
    required this.scope,
    this.entries = const [],
    this.me,
  });

  final String scope;
  final List<LeaderboardEntryData> entries;
  final LeaderboardEntryData? me;

  bool get hasRows => entries.isNotEmpty || me != null;

  static LeaderboardResponseData? fromRaw(Object? raw, {required String scope}) {
    if (raw is! Map) return null;
    final root = raw['leaderboard'] is Map ? raw['leaderboard'] as Map : raw;
    final rawEntries = root['entries'] ?? root['items'] ?? root['rows'];
    final entries = <LeaderboardEntryData>[
      if (rawEntries is List)
        for (final entry in rawEntries) ?LeaderboardEntryData.fromMap(entry),
    ];
    final me = LeaderboardEntryData.fromMap(root['me']);
    if (entries.isEmpty && me == null && rawEntries is! List) return null;
    return LeaderboardResponseData(
      scope: '${root['scope'] ?? scope}',
      entries: entries,
      me: me,
    );
  }
}
