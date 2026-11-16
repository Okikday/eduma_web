import '../../../core/data/json_envelope.dart';
import '../../auth/data/auth_api.dart';
import 'calendar_models.dart';

/// Reads and mutates scheduled events via `/events`.
class CalendarApi {
  CalendarApi._();

  static final CalendarApi instance = CalendarApi._();

  final _auth = EdumaAuthApi.instance;

  Future<List<CalendarEvent>> loadMonthEvents({
    required DateTime month,
    String? spaceId,
  }) async {
    final (from, to) = CalendarScheduleLogic.monthFetchRange(month);
    final payload = await _auth.getAuthenticated(
      '/events',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'limit': '100',
        if (spaceId != null && spaceId.trim().isNotEmpty) 'spaceId': spaceId.trim(),
      },
    );
    return CalendarScheduleLogic.parseList(payload);
  }

  Future<CalendarEvent?> createEvent(CreateCalendarEventInput input) async {
    final payload = await _auth.postAuthenticated(
      '/events',
      body: input.toMap(),
    );
    final map = extractResponseMap(payload, const ['event', 'data']);
    if (map == null) return null;
    final parsed = CalendarEvent.fromMap(map);
    return parsed.id.isEmpty ? null : parsed;
  }

  Future<CalendarEvent?> updateEvent(String eventId, CreateCalendarEventInput input) async {
    final payload = await _auth.patchAuthenticated(
      '/events/${Uri.encodeComponent(eventId)}',
      body: input.toMap(),
    );
    final map = extractResponseMap(payload, const ['event', 'data']);
    if (map == null) return null;
    final parsed = CalendarEvent.fromMap(map);
    return parsed.id.isEmpty ? null : parsed;
  }

  Future<void> deleteEvent(String eventId) async {
    await _auth.deleteAuthenticated('/events/${Uri.encodeComponent(eventId)}');
  }
}
