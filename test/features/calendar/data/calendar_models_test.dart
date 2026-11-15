import 'package:eduma_web/features/calendar/data/calendar_models.dart';
import 'package:test/test.dart';

void main() {
  group('CalendarScheduleLogic', () {
    test('monthGridDays returns 42 Sunday-first days starting on Sunday', () {
      final days = CalendarScheduleLogic.monthGridDays(DateTime(2026, 11, 1));
      expect(days.length, 42);
      expect(days.first.weekday, DateTime.sunday);
      expect(days.last.weekday, DateTime.saturday);
    });

    test('parseList decodes events and sorts chronologically', () {
      final events = CalendarScheduleLogic.parseList({
        'events': [
          {
            '_id': 'ev-2',
            'title': 'Later block',
            'subject': 'Physics',
            'startTime': '2026-11-15T14:00:00.000Z',
            'endTime': '2026-11-15T15:00:00.000Z',
          },
          {
            '_id': 'ev-1',
            'title': 'Morning block',
            'subject': 'Math',
            'startTime': '2026-11-15T09:00:00.000Z',
            'endTime': '2026-11-15T10:30:00.000Z',
            'recurrence': {
              'frequency': 'weekly',
              'daysOfWeek': [1, 3],
            },
          },
        ],
      });

      expect(events.map((e) => e.id).toList(), ['ev-1', 'ev-2']);
      expect(events.first.durationMinutes, 90);
      expect(events.first.recurrence?.frequency, CalendarRecurrenceFrequency.weekly);
    });

    test('CreateCalendarEventInput serializes UTC timestamps and legacy category', () {
      final input = CreateCalendarEventInput(
        title: 'Organic Chem',
        subject: 'Chemistry',
        startTime: DateTime(2026, 11, 15, 9, 0),
        endTime: DateTime(2026, 11, 15, 10, 0),
      );
      final map = input.toMap();
      expect(map['title'], 'Organic Chem');
      expect(map['category'], CreateCalendarEventInput.legacyCategory);
      expect('${map['startTime']}'.endsWith('Z'), isTrue);
    });

    test('groupByDay buckets events by dayKey and pastelStyleFor cycles 5 schemes', () {
      final first = CalendarEvent.fromMap({
        '_id': 'ev-a',
        'title': 'Calculus',
        'subject': 'Math',
        'startTime': '2026-11-15T09:00:00.000Z',
        'endTime': '2026-11-15T10:00:00.000Z',
      });
      final second = CalendarEvent.fromMap({
        '_id': 'ev-b',
        'title': 'Physics',
        'subject': 'Physics',
        'startTime': '2026-11-16T09:00:00.000Z',
        'endTime': '2026-11-16T10:00:00.000Z',
      });

      final grouped = CalendarScheduleLogic.groupByDay([first, second]);
      expect(grouped.length, 2);
      expect(grouped[first.dayKey]?.single.id, 'ev-a');

      final style0 = CalendarScheduleLogic.pastelStyleFor(first, indexOverride: 0);
      final style5 = CalendarScheduleLogic.pastelStyleFor(second, indexOverride: 5);
      expect(style0, equals(style5));
      expect(style0.fill, '#b6dcfe');
    });
  });
}
