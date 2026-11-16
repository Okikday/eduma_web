import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../data/calendar_models.dart';

const _weekdayFull = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Selected day header (`DayHeading` in `../eduma`): session summary line,
/// large `"EEEE d"` date title, and circular prev/next day arrows.
Component calendarDayHeading({
  required DateTime selectedDate,
  required int sessionCount,
  required bool hasError,
  required VoidCallback onPrevDay,
  required VoidCallback onNextDay,
}) {
  final summary = hasError
      ? "Couldn't load this day"
      : sessionCount == 0
      ? 'Nothing scheduled'
      : '$sessionCount ${sessionCount == 1 ? 'session' : 'sessions'}';
  final weekdayName = _weekdayFull[(selectedDate.weekday - 1).clamp(0, 6)];
  final dayLabel = '$weekdayName ${selectedDate.day}';

  return div(classes: 'eduma-cal-day-head', [
    span(classes: 'eduma-cal-day-head__summary', [.text(summary)]),
    div(classes: 'eduma-cal-day-head__row', [
      h2(classes: 'eduma-cal-day-head__title', [.text(dayLabel)]),
      div(classes: 'eduma-cal-day-head__nav', [
        button(
          classes: 'eduma-cal-day-nav-btn',
          type: ButtonType.button,
          attributes: {'aria-label': 'Previous day'},
          onClick: onPrevDay,
          [edumaIcon(EdumaIcons.back, size: 16)],
        ),
        button(
          classes: 'eduma-cal-day-nav-btn',
          type: ButtonType.button,
          attributes: {'aria-label': 'Next day'},
          onClick: onNextDay,
          [edumaIcon(EdumaIcons.chevronRight, size: 16)],
        ),
      ]),
    ]),
  ]);
}

/// Interactive 2D day timeline matching `CalendarDayPanel` / `CalendarTimelineSchedule`
/// and `EmptyEventsView` in `../eduma`.
Component calendarTimelineSchedule({
  required DateTime selectedDate,
  required List<CalendarEvent> dayEvents,
  required bool loading,
  required bool hasError,
  required VoidCallback onRetry,
  required VoidCallback onOpenCreateNow,
  required ValueChanged<DateTime> onOpenCreateAt,
  required ValueChanged<CalendarEvent> onOpenEvent,
  bool isCompact = false,
}) {
  if (loading && dayEvents.isEmpty) {
    return div(classes: 'eduma-cal-skeleton', [
      for (var i = 0; i < 4; i++)
        div(classes: 'eduma-cal-skeleton__row', [
          span(classes: 'eduma-cal-skeleton__time', []),
          span(classes: 'eduma-cal-skeleton__card', []),
        ]),
    ]);
  }

  if (hasError && dayEvents.isEmpty) {
    return div(classes: 'eduma-cal-empty-card', [
      span(classes: 'eduma-cal-empty-card__icon', [edumaIcon(EdumaIcons.calendar, size: 28)]),
      h3([.text("Couldn't load your events")]),
      p([.text('Please check your connection and try syncing again.')]),
      button(
        classes: 'eduma-desktop-pill eduma-desktop-pill--primary',
        type: ButtonType.button,
        onClick: onRetry,
        [.text('Retry')],
      ),
    ]);
  }

  if (dayEvents.isEmpty) {
    return div(classes: 'eduma-cal-empty-card', [
      span(classes: 'eduma-cal-empty-card__icon', [edumaIcon(EdumaIcons.calendar, size: 28)]),
      h3([.text('No events scheduled for this day')]),
      p([
        .text(
          'You have no scheduled classes, tasks, or study sessions on this date. Take some time to relax or plan a new session!',
        ),
      ]),
      button(
        classes: 'eduma-desktop-pill eduma-desktop-pill--primary',
        type: ButtonType.button,
        onClick: onOpenCreateNow,
        [edumaIcon(EdumaIcons.add, size: 16), .text('Schedule Event')],
      ),
    ]);
  }

  final sorted = [...dayEvents]..sort((first, second) => first.startTime.compareTo(second.startTime));
  final (startHour, endHour) = CalendarTimelineGeometry.resolveHourBounds(sorted);
  final placements = CalendarTimelineGeometry.computePlacements(
    sorted: sorted,
    startHour: startHour,
    isCompact: isCompact,
  );
  final emptySlots = CalendarTimelineGeometry.computeEmptySlots(sorted, startHour, endHour);

  final hourCount = endHour - startHour + 1;
  var totalHeightPx = hourCount * CalendarTimelineGeometry.hourHeightPx + 24.0;
  for (final placement in placements) {
    if (placement.bottomPx > totalHeightPx) totalHeightPx = placement.bottomPx;
  }
  final timeColPx = isCompact ? 46 : 54;

  return div(
    classes: isCompact ? 'eduma-cal-timeline is-compact' : 'eduma-cal-timeline',
    attributes: {
      'style': 'height: ${totalHeightPx.toStringAsFixed(0)}px; --cal-time-col: ${timeColPx}px;',
    },
    [
      // Left hour column labels + horizontal divider lines
      for (var i = 0; i < hourCount; i++)
        div(
          classes: 'eduma-cal-timeline__hour-row',
          attributes: {'style': 'top: ${(i * CalendarTimelineGeometry.hourHeightPx).toStringAsFixed(0)}px;'},
          [
            span(classes: 'eduma-cal-timeline__hour-label', [
              .text(CalendarTimelineGeometry.formatHourLabel(startHour + i)),
            ]),
            span(classes: 'eduma-cal-timeline__hour-line', attributes: {'aria-hidden': 'true'}, []),
          ],
        ),

      // 4 vertical grid columns across the schedule track
      div(classes: 'eduma-cal-timeline__track', [
        div(
          classes: 'eduma-cal-timeline__cols',
          attributes: {'aria-hidden': 'true'},
          [
            for (var c = 0; c < 4; c++) span(classes: 'eduma-cal-timeline__col-line', []),
          ],
        ),

        // Interactive dashed '+' placeholders in open windows
        for (final slot in emptySlots)
          button(
            classes: 'eduma-cal-empty-slot',
            type: ButtonType.button,
            attributes: {
              'aria-label': 'Schedule at ${CalendarTimelineGeometry.formatHourLabel(slot.startHour)}',
              'style':
                  'left: ${(slot.leftPct * 100).toStringAsFixed(2)}%; '
                  'width: ${(slot.widthPct * 100).toStringAsFixed(2)}%; '
                  'top: ${((slot.startHour - startHour) * CalendarTimelineGeometry.hourHeightPx + 6).toStringAsFixed(0)}px; '
                  'height: ${(CalendarTimelineGeometry.hourHeightPx * 1.48).toStringAsFixed(0)}px;',
            },
            onClick: () => onOpenCreateAt(
              DateTime(selectedDate.year, selectedDate.month, selectedDate.day, slot.startHour),
            ),
            [
              span(classes: 'eduma-cal-empty-slot__pill', [edumaIcon(EdumaIcons.add, size: 17)]),
            ],
          ),

        // Staggered pastel ScheduleEventCards
        for (final placement in placements)
          _timelineEventCard(
            placement: placement,
            onOpen: () => onOpenEvent(placement.event),
          ),
      ]),
    ],
  );
}

Component _timelineEventCard({
  required CalendarTimelinePlacement placement,
  required VoidCallback onOpen,
}) {
  final event = placement.event;
  final pastel = CalendarScheduleLogic.pastelStyleFor(event, indexOverride: placement.index);
  final kind = CalendarScheduleLogic.kindOf(event);
  final kindIcon = switch (kind) {
    .notebook => EdumaIcons.playSolid,
    .page => EdumaIcons.note,
    .space => EdumaIcons.people,
    .other => EdumaIcons.calendar,
  };
  final timeRange = '${formatShortClock(event.startTime)} - ${formatShortClock(event.endTime)}';
  final recurring = event.recurrence?.isRecurring ?? false;

  return div(
    classes: 'eduma-cal-timeline__item',
    attributes: {
      'style':
          'left: ${(placement.leftPct * 100).toStringAsFixed(2)}%; '
          'width: ${(placement.widthPct * 100).toStringAsFixed(2)}%; '
          'top: ${placement.topPx.toStringAsFixed(0)}px;',
    },
    [
      button(
        classes: 'eduma-cal-event-card',
        type: ButtonType.button,
        attributes: {
          'style':
              'min-height: ${placement.heightPx.toStringAsFixed(0)}px; '
              '--cal-fill: ${pastel.fill}; --cal-bar: ${pastel.accentBar}; --cal-text: ${pastel.text};',
        },
        onClick: onOpen,
        [
          span(classes: 'eduma-cal-event-card__bar', attributes: {'aria-hidden': 'true'}, []),
          div(classes: 'eduma-cal-event-card__inner', [
            div(classes: 'eduma-cal-event-card__head', [
              span(classes: 'eduma-cal-event-card__title', [.text(event.title)]),
              if (recurring)
                span(
                  classes: 'eduma-cal-event-card__repeat',
                  attributes: {'title': 'Repeating event'},
                  [edumaIcon(EdumaIcons.refresh, size: 12)],
                ),
            ]),
            div(classes: 'eduma-cal-event-card__time', [
              edumaIcon(kindIcon, size: 13),
              span([.text(timeRange)]),
            ]),
          ]),
        ],
      ),
    ],
  );
}
