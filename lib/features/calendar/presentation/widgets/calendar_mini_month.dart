import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../data/calendar_models.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _mobileWeekdayInitials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// "November 2026" month switcher with prev/next arrows and a Today button,
/// wrapped in the optional near-event dot (`AppNotificationBadge`).
Component calendarMonthSwitcher({
  required DateTime visibleMonth,
  required bool hasNearEvent,
  required ValueChanged<int> onShiftMonth,
  required VoidCallback onToday,
}) {
  final monthLabel = '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}';
  return div(classes: 'eduma-cal-switcher-wrap', [
    div(classes: 'eduma-cal-switcher', [
      h1(classes: 'eduma-cal-switcher__title', [.text(monthLabel)]),
      if (hasNearEvent)
        span(classes: 'eduma-cal-near-dot', attributes: {'aria-label': 'Upcoming event within 1 hour'}, []),
      div(classes: 'eduma-cal-switcher__arrows', [
        button(
          classes: 'eduma-cal-switcher__icon-btn',
          type: ButtonType.button,
          attributes: {'aria-label': 'Previous month'},
          onClick: () => onShiftMonth(-1),
          [edumaIcon(EdumaIcons.back, size: 18)],
        ),
        button(
          classes: 'eduma-cal-switcher__icon-btn',
          type: ButtonType.button,
          attributes: {'aria-label': 'Next month'},
          onClick: () => onShiftMonth(1),
          [edumaIcon(EdumaIcons.chevronRight, size: 18)],
        ),
        button(
          classes: 'eduma-cal-switcher__today',
          type: ButtonType.button,
          onClick: onToday,
          [.text('Today')],
        ),
      ]),
    ]),
  ]);
}

/// Frosted pill showing the next/active study session (`UpcomingEventSummaryChip`).
Component calendarUpcomingSummaryChip({
  required String summary,
  required VoidCallback onTap,
}) => button(
  classes: 'eduma-cal-upcoming-chip',
  type: ButtonType.button,
  onClick: onTap,
  [
    edumaIcon(EdumaIcons.clock, size: 14),
    span([.text(summary)]),
  ],
);

/// Desktop Sunday-first full month grid matching `MonthGrid`, `FullDayCell`,
/// and `DaySessionPreviews` in `../eduma`.
Component calendarDesktopMonthGrid({
  required DateTime visibleMonth,
  required DateTime selectedDate,
  required Map<String, List<CalendarEvent>> eventsByDay,
  required ValueChanged<DateTime> onSelectDate,
  required ValueChanged<DateTime> onCreateOnDay,
  required ValueChanged<CalendarEvent> onOpenEvent,
}) {
  final todayKey = calendarDayKey(DateTime.now());
  final selectedKey = calendarDayKey(selectedDate);
  final days = CalendarScheduleLogic.monthGridDays(visibleMonth);
  final spannedWeeks = CalendarScheduleLogic.monthSpannedWeeks(visibleMonth);
  final cellCount = spannedWeeks * 7;

  return section(
    classes: 'eduma-cal-month-grid',
    attributes: {'aria-label': 'Monthly calendar grid', 'data-weeks': '$spannedWeeks'},
    [
      div(classes: 'eduma-cal-month-grid__weekdays', [
        for (final label in _weekdayLabels) span([.text(label)]),
      ]),
      div(classes: 'eduma-cal-month-grid__rows', [
        for (var w = 0; w < spannedWeeks; w++)
          div(classes: 'eduma-cal-month-grid__week', [
            for (var d = 0; d < 7; d++)
              if (w * 7 + d < cellCount)
                _fullDayCell(
                  day: days[w * 7 + d],
                  inMonth:
                      days[w * 7 + d].month == visibleMonth.month &&
                      days[w * 7 + d].year == visibleMonth.year,
                  isToday: calendarDayKey(days[w * 7 + d]) == todayKey,
                  isSelected: calendarDayKey(days[w * 7 + d]) == selectedKey,
                  sessions:
                      days[w * 7 + d].month == visibleMonth.month &&
                              days[w * 7 + d].year == visibleMonth.year
                          ? (eventsByDay[calendarDayKey(days[w * 7 + d])] ?? const [])
                          : const [],
                  onSelect: () => onSelectDate(days[w * 7 + d]),
                  onCreate: () => onCreateOnDay(days[w * 7 + d]),
                  onOpenEvent: onOpenEvent,
                ),
          ]),
      ]),
    ],
  );
}

Component _fullDayCell({
  required DateTime day,
  required bool inMonth,
  required bool isToday,
  required bool isSelected,
  required List<CalendarEvent> sessions,
  required VoidCallback onSelect,
  required VoidCallback onCreate,
  required ValueChanged<CalendarEvent> onOpenEvent,
}) {
  final classes = [
    'eduma-cal-cell',
    if (!inMonth) 'is-outside',
    if (isToday) 'is-today',
    if (isSelected) 'is-selected',
  ].join(' ');
  const maxShown = 3;
  final overflow = sessions.length > maxShown;
  final visibleSessions = overflow ? sessions.take(maxShown - 1).toList() : sessions;

  return div(
    classes: classes,
    attributes: {
      'role': 'button',
      'tabindex': '0',
      'aria-label': '${day.day} ${_monthNames[day.month - 1]} ${day.year}',
      if (isSelected) 'aria-pressed': 'true',
    },
    events: {
      'click': (_) => onSelect(),
      'dblclick': (_) => onCreate(),
    },
    [
      div(classes: 'eduma-cal-cell__top', [
        span(classes: 'eduma-cal-cell__num', [.text('${day.day}')]),
        if (inMonth)
          button(
            classes: 'eduma-cal-cell__add',
            type: ButtonType.button,
            attributes: {'aria-label': 'Schedule on ${day.day}', 'title': 'Schedule on this day'},
            events: {
              'click': (event) {
                event.stopPropagation();
                onCreate();
              },
            },
            [edumaIcon(EdumaIcons.add, size: 15)],
          ),
      ]),
      if (sessions.isNotEmpty)
        div(classes: 'eduma-cal-cell__sessions', [
          for (var i = 0; i < visibleSessions.length; i++)
            _daySessionPreview(
              session: visibleSessions[i],
              paletteIndex: i,
              compact: visibleSessions.length >= 2 || overflow,
              onOpen: () => onOpenEvent(visibleSessions[i]),
            ),
          if (overflow)
            button(
              classes: 'eduma-cal-cell__more',
              type: ButtonType.button,
              events: {
                'click': (event) {
                  event.stopPropagation();
                  onSelect();
                },
              },
              [.text('+${sessions.length - visibleSessions.length} more')],
            ),
        ]),
    ],
  );
}

Component _daySessionPreview({
  required CalendarEvent session,
  required int paletteIndex,
  required bool compact,
  required VoidCallback onOpen,
}) {
  final style = CalendarScheduleLogic.pastelStyleFor(session, indexOverride: paletteIndex);
  final startClock = formatShortClock(session.startTime);
  final rangeClock = '$startClock – ${formatShortClock(session.endTime)}';
  final recurring = session.recurrence?.isRecurring ?? false;

  return button(
    classes: compact ? 'eduma-cal-preview is-compact' : 'eduma-cal-preview',
    type: ButtonType.button,
    attributes: {
      'style': '--cal-fill: ${style.fill}; --cal-bar: ${style.accentBar}; --cal-text: ${style.text};',
      'title': '$rangeClock · ${session.title}',
    },
    events: {
      'click': (event) {
        event.stopPropagation();
        onOpen();
      },
    },
    [
      span(classes: 'eduma-cal-preview__bar', attributes: {'aria-hidden': 'true'}, []),
      if (compact)
        div(classes: 'eduma-cal-preview__inline', [
          span(classes: 'eduma-cal-preview__title', [.text(session.title)]),
          span(classes: 'eduma-cal-preview__time-inline', [.text(startClock)]),
          if (recurring)
            span(classes: 'eduma-cal-preview__repeat', [edumaIcon(EdumaIcons.refresh, size: 10)]),
        ])
      else
        div(classes: 'eduma-cal-preview__stack', [
          div(classes: 'eduma-cal-preview__row', [
            span(classes: 'eduma-cal-preview__title', [.text(session.title)]),
            if (recurring)
              span(classes: 'eduma-cal-preview__repeat', [edumaIcon(EdumaIcons.refresh, size: 11)]),
          ]),
          span(classes: 'eduma-cal-preview__range', [.text(rangeClock)]),
        ]),
    ],
  );
}

/// Mobile sticky translucent 7-day calendar strip matching `MiniCalendarHeader`.
Component calendarMobileMiniHeader({
  required DateTime selectedDate,
  required Map<String, List<CalendarEvent>> eventsByDay,
  required bool hasNearEvent,
  required ({String summary, DateTime date, bool hasNearEvent})? upcoming,
  required ValueChanged<DateTime> onSelectDate,
  required VoidCallback onOpenBrowseAll,
}) {
  final now = DateTime.now();
  final todayKey = calendarDayKey(now);
  final selectedKey = calendarDayKey(selectedDate);
  final weekDays = CalendarScheduleLogic.weekStripDays(selectedDate);
  final monthLabel = '${_monthNames[selectedDate.month - 1]} ${selectedDate.year}';

  return header(classes: 'eduma-cal-mobile-head', [
    div(classes: 'eduma-cal-mobile-head__bar', [
      label(classes: 'eduma-cal-mobile-month-picker', [
        span(classes: 'eduma-cal-mobile-month-picker__text', [.text(monthLabel)]),
        if (hasNearEvent) span(classes: 'eduma-cal-near-dot', []),
        span(classes: 'eduma-cal-mobile-month-picker__chevron', [
          edumaIcon(EdumaIcons.chevronRight, size: 15),
        ]),
        input<String>(
          type: InputType.date,
          value: calendarDayKey(selectedDate),
          attributes: {'aria-label': 'Jump to date'},
          onInput: (value) {
            final parsed = DateTime.tryParse(value);
            if (parsed != null) onSelectDate(parsed);
          },
        ),
      ]),
      div(classes: 'eduma-cal-mobile-head__right', [
        if (upcoming case final item?)
          calendarUpcomingSummaryChip(
            summary: item.summary,
            onTap: () => onSelectDate(item.date),
          ),
        button(
          classes: 'eduma-cal-mobile-browse-btn',
          type: ButtonType.button,
          attributes: {'aria-label': 'Browse all events', 'title': 'All Scheduled Events'},
          onClick: onOpenBrowseAll,
          [edumaIcon(EdumaIcons.calendar, size: 20)],
        ),
      ]),
    ]),
    div(classes: 'eduma-cal-week-strip', [
      div(classes: 'eduma-cal-week-strip__labels', [
        for (final letter in _mobileWeekdayInitials) span([.text(letter)]),
      ]),
      div(classes: 'eduma-cal-week-strip__days', [
        for (final day in weekDays)
          _weekStripDayButton(
            day: day,
            isSelected: calendarDayKey(day) == selectedKey,
            isToday: calendarDayKey(day) == todayKey,
            hasTasks: (eventsByDay[calendarDayKey(day)] ?? const []).isNotEmpty,
            onTap: () => onSelectDate(day),
          ),
      ]),
    ]),
  ]);
}

Component _weekStripDayButton({
  required DateTime day,
  required bool isSelected,
  required bool isToday,
  required bool hasTasks,
  required VoidCallback onTap,
}) {
  final classes = [
    'eduma-cal-strip-day',
    if (isSelected) 'is-selected',
    if (isToday) 'is-today',
    if (hasTasks) 'has-tasks',
  ].join(' ');
  return button(
    classes: classes,
    type: ButtonType.button,
    attributes: {
      'aria-label': '${day.day} ${_monthNames[day.month - 1]}',
      if (isSelected) 'aria-pressed': 'true',
    },
    onClick: onTap,
    [
      span(classes: 'eduma-cal-strip-day__num', [.text('${day.day}')]),
      if (hasTasks && !isSelected)
        span(classes: 'eduma-cal-strip-day__dot', attributes: {'aria-hidden': 'true'}, []),
    ],
  );
}
