import '../../auth/data/auth_api.dart';
import 'streak_models.dart';

/// Combined overview payload for the streak screen.
class StreakOverviewResult {
  const StreakOverviewResult({
    required this.summary,
    required this.leaderboardVisible,
  });

  final StreakSummaryData summary;
  final bool leaderboardVisible;
}

/// Client for `/streaks/me` with quiet fallback to `/users/me/analytics`, plus leaderboards.
class StreakApi {
  StreakApi._();

  static final StreakApi instance = StreakApi._();

  final _auth = EdumaAuthApi.instance;

  Future<StreakOverviewResult> loadStreakOverview() async {
    try {
      final payload = await _auth.getAuthenticated(
        '/streaks/me',
        queryParameters: const {'days': '14'},
      );
      final streakNode = payload['streak'] is Map ? payload['streak'] as Map : payload;
      final settings = streakNode['settings'] is Map ? streakNode['settings'] as Map : const {};
      final rawVisible = settings['leaderboardVisible'] ?? streakNode['leaderboardVisible'];
      return StreakOverviewResult(
        summary: StreakSummaryData.fromPayload(payload),
        leaderboardVisible: rawVisible is bool ? rawVisible : true,
      );
    } catch (_) {
      final fallback = await loadMyStreak();
      return StreakOverviewResult(summary: fallback, leaderboardVisible: true);
    }
  }

  Future<LeaderboardResponseData?> loadLeaderboard(LeaderboardScope scope) async {
    try {
      final payload = await _auth.getAuthenticated(
        '/streaks/leaderboard',
        queryParameters: {'scope': scope.name, 'period': 'week', 'limit': '50'},
      );
      return LeaderboardResponseData.fromRaw(payload, scope: scope.name) ??
          LeaderboardResponseData(scope: scope.name);
    } on AuthApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405 || error.statusCode == 501) {
        throw const StreakLeaderboardUnavailableException();
      }
      rethrow;
    }
  }

  Future<bool> updateLeaderboardVisibility(bool visible) async {
    final payload = await _auth.patchAuthenticated(
      '/streaks/settings',
      body: {'leaderboardVisible': visible},
    );
    final settings = payload['settings'] is Map ? payload['settings'] as Map : payload;
    final raw = settings['leaderboardVisible'];
    return raw is bool ? raw : visible;
  }

  Future<StreakSummaryData> loadMyStreak() async {
    try {
      final payload = await _auth.getAuthenticated(
        '/streaks/me',
        queryParameters: const {'days': '14'},
      );
      return StreakSummaryData.fromPayload(payload);
    } on AuthApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 501) {
        return _fallbackAnalytics();
      }
      rethrow;
    } catch (_) {
      return _fallbackAnalytics();
    }
  }

  Future<StreakSummaryData> _fallbackAnalytics() async {
    try {
      final payload = await _auth.getAuthenticated('/users/me/analytics');
      return StreakSummaryData.fromPayload(payload);
    } catch (_) {
      return const StreakSummaryData();
    }
  }
}
