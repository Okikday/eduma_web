import 'package:eduma_web/core/utils/date_formatters.dart';
import 'package:test/test.dart';

void main() {
  group('date_formatters', () {
    test('formatShortClock renders 12-hour AM/PM labels', () {
      expect(formatShortClock(DateTime(2026, 11, 15, 0, 5)), '12:05 AM');
      expect(formatShortClock(DateTime(2026, 11, 15, 9, 30)), '9:30 AM');
      expect(formatShortClock(DateTime(2026, 11, 15, 12, 0)), '12:00 PM');
      expect(formatShortClock(DateTime(2026, 11, 15, 17, 45)), '5:45 PM');
    });

    test('formatShortDate omits year for current year and includes year otherwise', () {
      final now = DateTime(2026, 11, 15);
      expect(formatShortDate(DateTime(2026, 4, 8), now: now), 'Apr 8');
      expect(formatShortDate(DateTime(2025, 12, 24), now: now), 'Dec 24, 2025');
    });

    test('formatRelativeTimeLabel formats recency cleanly', () {
      final now = DateTime(2026, 11, 15, 12, 0);
      expect(formatRelativeTimeLabel(null, now: now), '');
      expect(formatRelativeTimeLabel(now.subtract(const Duration(seconds: 20)), now: now), 'Just now');
      expect(formatRelativeTimeLabel(now.subtract(const Duration(minutes: 14)), now: now), '14m ago');
      expect(formatRelativeTimeLabel(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(formatRelativeTimeLabel(now.subtract(const Duration(days: 4)), now: now), '4d ago');
      expect(formatRelativeTimeLabel(DateTime(2026, 10, 1, 9, 0), now: now), 'Oct 1');
    });
  });
}
