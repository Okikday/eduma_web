import '../data/calendar_api.dart';
import '../data/calendar_models.dart';

export '../data/calendar_models.dart';

abstract final class CalendarActions {
  static final _api = CalendarApi.instance;

  static Future<List<CalendarEvent>> loadMonthEvents({
    required DateTime month,
    String? spaceId,
  }) => _api.loadMonthEvents(month: month, spaceId: spaceId);

  static Future<CalendarEvent?> createEvent(CreateCalendarEventInput input) => _api.createEvent(input);

  static Future<CalendarEvent?> updateEvent(String eventId, CreateCalendarEventInput input) =>
      _api.updateEvent(eventId, input);

  static Future<void> deleteEvent(String eventId) => _api.deleteEvent(eventId);
}
