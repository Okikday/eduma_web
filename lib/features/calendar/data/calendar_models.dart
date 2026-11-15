import '../../../core/data/json_envelope.dart';

/// How often a scheduled study event repeats.
enum CalendarRecurrenceFrequency { none, daily, weekly, monthly }

/// Recurrence rule matching `POST /events` in the Eduma API.
class CalendarEventRecurrence {
  const CalendarEventRecurrence({
    this.frequency = .none,
    this.daysOfWeek = const {},
    this.until,
    this.interval = 1,
  });

  final CalendarRecurrenceFrequency frequency;
  final Set<int> daysOfWeek;
  final DateTime? until;
  final int interval;

  bool get isRecurring => frequency != .none;

  String get label => switch (frequency) {
    .none => 'One-off',
    .daily => 'Daily',
    .weekly => 'Weekly',
    .monthly => 'Monthly',
  };

  Map<String, Object?> toMap() => {
    'frequency': frequency.name,
    'interval': interval,
    if (frequency == .weekly && daysOfWeek.isNotEmpty)
      'daysOfWeek': daysOfWeek.toList()..sort(),
    if (until != null) 'until': _dateOnly(until!),
  };

  static CalendarEventRecurrence? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final rawFreq = '${map['frequency'] ?? ''}'.trim();
    final frequency = CalendarRecurrenceFrequency.values.firstWhere(
      (item) => item.name == rawFreq,
      orElse: () => .none,
    );
    return CalendarEventRecurrence(
      frequency: frequency,
      daysOfWeek: {
        for (final value in (map['daysOfWeek'] as List? ?? const []))
          if (int.tryParse('$value') case final int day) day,
      },
      until: DateTime.tryParse('${map['until'] ?? ''}'),
      interval: int.tryParse('${map['interval'] ?? ''}') ?? 1,
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Scheduled event returned by `/events`.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.ownerId,
    required this.subject,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.updatedAt,
    this.recurrence,
    this.resourceId,
    this.resourceType,
    this.spaceId,
  });

  final String id;
  final String ownerId;
  final String subject;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CalendarEventRecurrence? recurrence;
  final String? resourceId;
  final String? resourceType;
  final String? spaceId;

  int get durationMinutes {
    final minutes = endTime.difference(startTime).inMinutes;
    return minutes <= 0 ? 30 : minutes;
  }

  String get dayKey => calendarDayKey(startTime);

  factory CalendarEvent.fromMap(Map<String, dynamic> map) => CalendarEvent(
    id: '${map['_id'] ?? map['id'] ?? ''}',
    ownerId: '${map['ownerId'] ?? ''}',
    subject: '${map['subject'] ?? ''}'.trim(),
    title: '${map['title'] ?? ''}'.trim(),
    description: _nonEmpty(map['description']),
    startTime: _localDateTime(map['startTime']),
    endTime: _localDateTime(map['endTime']),
    createdAt: _localDateTime(map['createdAt']),
    updatedAt: _localDateTime(map['updatedAt']),
    recurrence: CalendarEventRecurrence.fromMap(map['recurrence']),
    resourceId: _nonEmpty(map['resourceId']),
    resourceType: _nonEmpty(map['resourceType']),
    spaceId: _nonEmpty(map['spaceId']),
  );

  static String? _nonEmpty(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime _localDateTime(Object? raw) =>
      DateTime.tryParse('${raw ?? ''}')?.toLocal() ?? DateTime.now();
}

/// Request payload for `POST /events`.
class CreateCalendarEventInput {
  const CreateCalendarEventInput({
    required this.title,
    this.subject,
    this.description,
    required this.startTime,
    required this.endTime,
    this.recurrence,
    this.spaceId,
  });

  static const legacyCategory = 'literature';

  final String title;
  final String? subject;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final CalendarEventRecurrence? recurrence;
  final String? spaceId;

  Map<String, Object?> toMap() => {
    if (subject != null && subject!.trim().isNotEmpty) 'subject': subject!.trim(),
    'title': title.trim(),
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    'startTime': startTime.toUtc().toIso8601String(),
    'endTime': endTime.toUtc().toIso8601String(),
    'category': legacyCategory,
    if (recurrence != null && recurrence!.isRecurring)
      'recurrence': recurrence!.toMap(),
    if (spaceId != null && spaceId!.trim().isNotEmpty) 'spaceId': spaceId!.trim(),
  };
}

String calendarDayKey(DateTime dt) {
  final local = dt.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}

/// Pure date, month-grid, and search helpers for the Calendar tab.
abstract final class CalendarScheduleLogic {
  static (DateTime from, DateTime to) monthFetchRange(DateTime month) {
    final start = DateTime(month.year, month.month, 1).subtract(const Duration(days: 7));
    final end = DateTime(month.year, month.month + 1, 1).add(const Duration(days: 7));
    return (start, end);
  }

  /// Returns 42 calendar cells (6 Sunday-first weeks) covering [month].
  static List<DateTime> monthGridDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leading = firstOfMonth.weekday % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: leading));
    return [for (var i = 0; i < 42; i++) gridStart.add(Duration(days: i))];
  }

  static Map<String, List<CalendarEvent>> groupByDay(List<CalendarEvent> events) {
    final map = <String, List<CalendarEvent>>{};
    for (final item in events) {
      map.putIfAbsent(item.dayKey, () => []).add(item);
    }
    return map;
  }

  /// Deterministic pastel scheme matching Flutter's `ScheduleEventVisuals`.
  static ({String fill, String accentBar, String text}) pastelStyleFor(
    CalendarEvent event, {
    int? indexOverride,
  }) {
    const palette = [
      (fill: '#b6dcfe', accentBar: '#2b6cb0', text: '#0e2f56'),
      (fill: '#eccb82', accentBar: '#8a6518', text: '#422c04'),
      (fill: '#eea7d3', accentBar: '#8b1e5b', text: '#460b2b'),
      (fill: '#beb6f6', accentBar: '#3730a3', text: '#17143a'),
      (fill: '#fa986b', accentBar: '#9a3412', text: '#3e1606'),
    ];
    final seed = indexOverride ??
        (event.id.isNotEmpty
                ? event.id
                : '${event.title}|${event.startTime.toIso8601String()}')
            .runes
            .fold<int>(0, (value, rune) => (value * 31 + rune) & 0x7fffffff);
    return palette[seed.abs() % palette.length];
  }

  static List<CalendarEvent> parseList(Map<String, dynamic> payload) {
    final rawList = extractResponseList(payload, const ['events', 'items', 'data']);
    final events = [
      for (final item in rawList) CalendarEvent.fromMap(item),
    ]..sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  static List<CalendarEvent> filter(List<CalendarEvent> events, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return events;
    return [
      for (final item in events)
        if (item.title.toLowerCase().contains(normalized) ||
            item.subject.toLowerCase().contains(normalized) ||
            (item.description?.toLowerCase().contains(normalized) ?? false))
          item,
    ];
  }

  static List<CalendarEvent> eventsOnDay(List<CalendarEvent> events, DateTime day) {
    final key = calendarDayKey(day);
    return [for (final item in events) if (item.dayKey == key) item];
  }

  static Set<String> activeDayKeys(List<CalendarEvent> events) => {
    for (final item in events) item.dayKey,
  };

  /// Number of Sunday-first calendar rows spanned by [month] (4, 5, or 6).
  static int monthSpannedWeeks(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 0);
    return ((first.weekday % 7 + next.day) / 7).ceil();
  }

  /// Seven days of the Sunday-first week containing [selectedDate].
  static List<DateTime> weekStripDays(DateTime selectedDate) {
    final normalized = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final weekStart = normalized.subtract(Duration(days: normalized.weekday % 7));
    return [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];
  }

  /// Target kind classification matching `EventResourceLogic` in `../eduma`.
  static CalendarEventKind kindOf(CalendarEvent event) {
    final rType = (event.resourceType ?? '').trim().toLowerCase();
    final hasId = (event.resourceId ?? '').trim().isNotEmpty;
    if (hasId && (rType == 'notebook' || rType == 'video')) return .notebook;
    if (hasId && rType == 'page') return .page;
    if ((event.spaceId ?? '').trim().isNotEmpty) return .space;
    return .other;
  }

  /// Summarizes active or imminent upcoming events matching `UpcomingEventSummaryLogic`.
  static ({String summary, DateTime date, bool hasNearEvent})? summarizeUpcoming(
    List<CalendarEvent> events, {
    required DateTime now,
  }) {
    final active = <(DateTime end, DateTime start)>[];
    final upcoming = <DateTime>[];
    final horizon = now.add(const Duration(days: 7));

    for (final event in events) {
      if (!event.endTime.isAfter(event.startTime)) continue;
      if (!event.startTime.isAfter(now) && event.endTime.isAfter(now)) {
        active.add((event.endTime, event.startTime));
      } else if (event.startTime.isAfter(now) && event.startTime.isBefore(horizon)) {
        upcoming.add(event.startTime);
      }
    }

    if (active.length > 1) {
      return (summary: '${active.length} in progress', date: now, hasNearEvent: true);
    }
    if (active.length == 1) {
      final remaining = active.first.$1.difference(now);
      final String text;
      if (remaining <= const Duration(minutes: 1)) {
        text = 'Ending now';
      } else {
        final minutes = (remaining.inSeconds + 59) ~/ 60;
        text = minutes < 60 ? 'Ends in $minutes min' : 'Ends in ${(minutes + 59) ~/ 60} h';
      }
      return (summary: text, date: now, hasNearEvent: true);
    }

    if (upcoming.isEmpty) return null;
    upcoming.sort();
    const nearWindow = Duration(hours: 1);
    final nearCount = upcoming.where((start) => start.difference(now) <= nearWindow).length;
    if (nearCount > 1) {
      return (summary: '$nearCount events in 1h', date: upcoming.first, hasNearEvent: true);
    }

    final untilNext = upcoming.first.difference(now);
    final minutes = (untilNext.inSeconds + 59) ~/ 60;
    final String label;
    if (untilNext.inSeconds <= 0) {
      label = 'Next event now';
    } else if (minutes < 60) {
      label = 'An event in $minutes min';
    } else if (minutes < 24 * 60) {
      label = 'An event in ${(minutes + 59) ~/ 60} h';
    } else {
      label = 'An event in ${(minutes + 24 * 60 - 1) ~/ (24 * 60)} d';
    }
    return (
      summary: label,
      date: upcoming.first,
      hasNearEvent: nearCount > 0,
    );
  }
}

/// Kind classification for Browse All filter chips & badges.
enum CalendarEventKind { notebook, page, space, other }

/// Spatial placement for a [CalendarEvent] inside the 2D hour timeline grid.
class CalendarTimelinePlacement {
  const CalendarTimelinePlacement({
    required this.event,
    required this.index,
    required this.leftPct,
    required this.widthPct,
    required this.topPx,
    required this.heightPx,
    required this.isRightSide,
  });

  final CalendarEvent event;
  final int index;
  final double leftPct;
  final double widthPct;
  final double topPx;
  final double heightPx;
  final bool isRightSide;

  double get bottomPx => topPx + heightPx + ((event.spaceId?.trim().isNotEmpty ?? false) ? 28 : 8);
}

/// Spatial slot for a dashed `+` open-slot placeholder.
class CalendarTimelineEmptySlot {
  const CalendarTimelineEmptySlot({
    required this.startHour,
    required this.leftPct,
    required this.widthPct,
  });

  final int startHour;
  final double leftPct;
  final double widthPct;
}

/// Pure 2D day timeline geometry matching `CalendarTimelineLayout` in `../eduma`.
abstract final class CalendarTimelineGeometry {
  static const double hourHeightPx = 68.0;

  static (int startHour, int endHour) resolveHourBounds(List<CalendarEvent> sorted) {
    var minH = 10;
    var maxH = 21;
    for (final e in sorted) {
      if (e.startTime.hour < minH) minH = e.startTime.hour;
      final endCandidate = e.endTime.hour + 1;
      if (endCandidate > maxH) maxH = endCandidate > 23 ? 23 : endCandidate;
    }
    if (maxH - minH < 8) {
      maxH = minH + 9 > 23 ? 23 : minH + 9;
    }
    return (minH, maxH);
  }

  static String formatHourLabel(int hour) {
    final clamped = hour.clamp(0, 23);
    final suffix = clamped < 12 ? 'AM' : 'PM';
    final hour12 = clamped == 0 ? 12 : (clamped > 12 ? clamped - 12 : clamped);
    return '${hour12.toString().padLeft(2, '0')} $suffix';
  }

  static (double leftPct, double widthPct, bool isRightSide) _horizontalPlacement({
    required int index,
    required CalendarEvent current,
    required List<CalendarEvent> all,
    required bool prevRightSide,
    required bool isCompact,
  }) {
    final baseWidth = isCompact ? 0.66 : 0.60;
    final wideWidth = isCompact ? 0.72 : 0.66;
    if (index > 0) {
      final prev = all[index - 1];
      final gapMinutes = current.startTime.difference(prev.endTime).inMinutes;
      if (gapMinutes < 45) {
        final goRight = !prevRightSide;
        return goRight ? (1.0 - baseWidth - 0.02, baseWidth, true) : (0.02, baseWidth, false);
      }
    }
    return switch (index % 5) {
      0 => (0.02, baseWidth, false),
      1 => (1.0 - baseWidth - 0.04, baseWidth, true),
      2 => (0.03, baseWidth, false),
      3 => (0.02, baseWidth, false),
      _ => (0.25, wideWidth < 0.73 ? wideWidth : 0.73, true),
    };
  }

  static List<CalendarTimelinePlacement> computePlacements({
    required List<CalendarEvent> sorted,
    required int startHour,
    bool isCompact = false,
  }) {
    final result = <CalendarTimelinePlacement>[];
    var prevRightSide = false;
    double? lastLeftBottom;
    double? lastRightBottom;

    for (var i = 0; i < sorted.length; i++) {
      final event = sorted[i];
      final startFrac = (event.startTime.hour - startHour) + (event.startTime.minute / 60.0);
      final durationMinutes = event.endTime.difference(event.startTime).inMinutes < 45
          ? 45
          : event.endTime.difference(event.startTime).inMinutes;
      final computedHeight = (durationMinutes / 60.0) * hourHeightPx * 1.05;
      final cardHeight = computedHeight < 78.0 ? 78.0 : computedHeight;

      final (leftPct, widthPct, isRightSide) = _horizontalPlacement(
        index: i,
        current: event,
        all: sorted,
        prevRightSide: prevRightSide,
        isCompact: isCompact,
      );
      prevRightSide = isRightSide;

      var topPx = startFrac * hourHeightPx + 2.0;
      if (topPx < 0) topPx = 0;
      final sameSideBottom = isRightSide ? lastRightBottom : lastLeftBottom;
      if (sameSideBottom != null && topPx < sameSideBottom + 8.0) {
        topPx = sameSideBottom + 8.0;
      }

      final hasSpace = (event.spaceId?.trim().isNotEmpty ?? false);
      final footprint = cardHeight + (hasSpace ? 26.0 : 0.0);
      if (isRightSide) {
        lastRightBottom = topPx + footprint;
      } else {
        lastLeftBottom = topPx + footprint;
      }

      result.add(
        CalendarTimelinePlacement(
          event: event,
          index: i,
          leftPct: leftPct,
          widthPct: widthPct,
          topPx: topPx,
          heightPx: cardHeight,
          isRightSide: isRightSide,
        ),
      );
    }
    return result;
  }

  static List<CalendarTimelineEmptySlot> computeEmptySlots(
    List<CalendarEvent> sorted,
    int startHour,
    int endHour,
  ) {
    final result = <CalendarTimelineEmptySlot>[];
    var toggle = 0;
    for (var h = startHour + 1; h <= endHour - 2; h++) {
      final slotStart = h * 60;
      final slotEnd = (h + 1) * 60 + 30;
      final overlapsAny = sorted.any((e) {
        final eStart = e.startTime.hour * 60 + e.startTime.minute - 35;
        final eEnd = e.endTime.hour * 60 + e.endTime.minute + 35;
        return slotStart < eEnd && slotEnd > eStart;
      });
      if (!overlapsAny) {
        final isRight = toggle.isOdd;
        result.add(
          CalendarTimelineEmptySlot(
            startHour: h,
            leftPct: isRight ? 0.34 : 0.05,
            widthPct: 0.45,
          ),
        );
        toggle++;
        h += 2;
        if (result.length >= 2) break;
      }
    }
    return result;
  }
}
