import 'package:eduma_web/features/streak/data/streak_models.dart';
import 'package:test/test.dart';

void main() {
  group('StreakSummaryData', () {
    test('parses streak payload and computes clamped daily progress', () {
      final summary = StreakSummaryData.fromPayload({
        'streak': {
          'current': 5,
          'best': 12,
          'today': {'minutes': 15, 'goalMinutes': 20, 'done': false},
          'days': [
            {'date': '2026-11-15', 'minutes': 15, 'state': 'studied'},
          ],
        },
      });

      expect(summary.current, 5);
      expect(summary.best, 12);
      expect(summary.todayMinutes, 15);
      expect(summary.progressRatio, 0.75);
      expect(summary.days.single.studied, isTrue);
      expect(summary.effectiveWeek.length, 7);
      expect(StreakSummaryData.formatMinutes(75), '1 h 15 min');
    });
  });
}
