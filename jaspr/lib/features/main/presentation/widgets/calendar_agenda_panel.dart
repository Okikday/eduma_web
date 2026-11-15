import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../calendar/logic/calendar_actions.dart';
import '../../../calendar/presentation/widgets/calendar_create_dialog.dart';
import '../../../streak/data/streak_api.dart';
import '../../../streak/data/streak_models.dart';

/// Right-hand panel (`340px`, visible at `>= 1180px`) on Home & Library tabs,
/// matching `CalendarAgendaPanel` in `../eduma`: compact `MonthSwitcher`,
/// compact 6-row Sunday-first `MonthGrid`, divider, and selected day agenda.
class CalendarAgendaPanel extends StatefulComponent {
  const CalendarAgendaPanel({this.initialEvents, super.key});

  final List<CalendarEvent>? initialEvents;

  @override
  State<CalendarAgendaPanel> createState() => _CalendarAgendaPanelState();
}

class _CalendarAgendaPanelState extends State<CalendarAgendaPanel> {
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _weekHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  DateTime _visibleMonth = _monthOnly(DateTime.now());
  DateTime _selectedDate = _dayOnly(DateTime.now());
  List<CalendarEvent> _events = const [];
  Map<String, StreakDayEntry> _streakByDay = const {};
  bool _loading = true;
  bool _createOpen = false;
  int _generation = 0;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month, 1);

  @override
  void initState() {
    super.initState();
    if (component.initialEvents != null) {
      _events = component.initialEvents!;
      _loading = false;
    } else {
      final cachedEvents = EdumaMemoryCache.instance.calendarMonths[EdumaMemoryCache.monthKey(_visibleMonth)];
      if (cachedEvents != null) {
        _events = cachedEvents;
        _loading = false;
      }
      final cachedStreak = EdumaMemoryCache.instance.streakSummary;
      if (cachedStreak != null) {
        _streakByDay = _streakCalendarMap(cachedStreak.days);
      }
      Future<void>.microtask(_loadInitial);
    }
  }

  /// Matches `StreakRulesLogic.calendarHistory` in `../eduma`: omits days
  /// before the user's first studied day (returns empty if none exist yet).
  Map<String, StreakDayEntry> _streakCalendarMap(List<StreakDayEntry> days) {
    final studied = days.where((d) => d.state == 'studied').map((d) => d.date);
    if (studied.isEmpty) return const {};
    final firstStudied = studied.reduce(
      (first, second) => first.compareTo(second) <= 0 ? first : second,
    );
    return {
      for (final entry in days)
        if (entry.date.compareTo(firstStudied) >= 0) entry.date: entry,
    };
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadMonth(_visibleMonth),
      _loadStreakDays(),
    ]);
  }

  Future<void> _loadMonth(DateTime month) async {
    final gen = ++_generation;
    final key = EdumaMemoryCache.monthKey(month);
    final cached = EdumaMemoryCache.instance.calendarMonths[key];
    setState(() {
      if (cached != null) _events = cached;
      _loading = cached == null;
    });
    try {
      final loaded = await CalendarActions.loadMonthEvents(month: month);
      if (!mounted || gen != _generation) return;
      EdumaMemoryCache.instance.calendarMonths[key] = loaded;
      setState(() {
        _events = loaded;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadStreakDays() async {
    try {
      final summary = await StreakApi.instance.loadMyStreak();
      if (!mounted) return;
      setState(() {
        _streakByDay = _streakCalendarMap(summary.days);
      });
    } catch (_) {}
  }

  void _selectDate(DateTime date) {
    final day = _dayOnly(date);
    final monthChanged =
        day.year != _visibleMonth.year || day.month != _visibleMonth.month;
    setState(() {
      _selectedDate = day;
      _visibleMonth = _monthOnly(day);
    });
    if (monthChanged) {
      unawaited(_loadMonth(_visibleMonth));
    }
  }

  void _shiftMonth(int delta) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    final daysInTarget = DateTime(target.year, target.month + 1, 0).day;
    final clampedDay = _selectedDate.day.clamp(1, daysInTarget);
    _selectDate(DateTime(target.year, target.month, clampedDay));
  }

  void _shiftDay(int delta) =>
      _selectDate(_selectedDate.add(Duration(days: delta)));

  @override
  Component build(BuildContext context) {
    final todayKey = calendarDayKey(DateTime.now());
    final selectedKey = calendarDayKey(_selectedDate);
    final eventsByDay = CalendarScheduleLogic.groupByDay(_events);
    final dayEvents = eventsByDay[selectedKey] ?? const [];
    final gridDays = CalendarScheduleLogic.monthGridDays(_visibleMonth);

    return aside(
      classes: 'eduma-agenda-panel',
      attributes: {'aria-label': 'Calendar agenda'},
      [
        div(classes: 'eduma-agenda-panel__month-bar', [
          span(classes: 'eduma-agenda-panel__month-title', [
            .text('${_shortMonths[_visibleMonth.month - 1]} ${_visibleMonth.year}'),
          ]),
          button(
            classes: 'eduma-agenda-panel__chevron-btn',
            type: ButtonType.button,
            attributes: {'aria-label': 'Previous month'},
            onClick: () => _shiftMonth(-1),
            [edumaIcon(EdumaIcons.back, size: 16)],
          ),
          button(
            classes: 'eduma-agenda-panel__chevron-btn',
            type: ButtonType.button,
            attributes: {'aria-label': 'Next month'},
            onClick: () => _shiftMonth(1),
            [edumaIcon(EdumaIcons.chevronRight, size: 16)],
          ),
          button(
            classes: 'eduma-agenda-panel__today-btn',
            type: ButtonType.button,
            onClick: () => _selectDate(DateTime.now()),
            [.text('Today')],
          ),
          button(
            classes: 'eduma-agenda-panel__add-btn',
            type: ButtonType.button,
            attributes: {'aria-label': 'New event', 'title': 'New event'},
            onClick: () => setState(() => _createOpen = true),
            [edumaIcon(EdumaIcons.calendarAdd, size: 20)],
          ),
        ]),
        div(classes: 'eduma-agenda-panel__weekdays', [
          for (final w in _weekHeaders) span([.text(w)]),
        ]),
        div(classes: 'eduma-agenda-panel__grid', [
          for (final day in gridDays)
            _compactDayCell(
              day: day,
              inMonth: day.month == _visibleMonth.month && day.year == _visibleMonth.year,
              isToday: calendarDayKey(day) == todayKey,
              isSelected: calendarDayKey(day) == selectedKey,
              isBusy: (eventsByDay[calendarDayKey(day)] ?? const []).isNotEmpty,
              streak: _streakByDay[calendarDayKey(day)],
              onTap: () => _selectDate(day),
            ),
        ]),
        div(classes: 'eduma-agenda-panel__divider', []),
        div(classes: 'eduma-agenda-panel__day-head', [
          div([
            span(classes: 'eduma-agenda-panel__summary', [
              .text(
                dayEvents.isEmpty
                    ? (_loading ? 'Loading schedule…' : 'Nothing scheduled')
                    : '${dayEvents.length} ${dayEvents.length == 1 ? 'session' : 'sessions'}',
              ),
            ]),
            h2(classes: 'eduma-agenda-panel__day-title', [
              .text('${_weekdaysFull[_selectedDate.weekday - 1]} ${_selectedDate.day}'),
            ]),
          ]),
          div(classes: 'eduma-agenda-panel__day-nav', [
            button(
              classes: 'eduma-agenda-panel__circle-nav',
              type: ButtonType.button,
              attributes: {'aria-label': 'Previous day'},
              onClick: () => _shiftDay(-1),
              [edumaIcon(EdumaIcons.arrowLeftStroke, size: 18)],
            ),
            button(
              classes: 'eduma-agenda-panel__circle-nav',
              type: ButtonType.button,
              attributes: {'aria-label': 'Next day'},
              onClick: () => _shiftDay(1),
              [edumaIcon(EdumaIcons.arrowRightStroke, size: 18)],
            ),
          ]),
        ]),
        div(classes: 'eduma-agenda-panel__agenda', [
          if (dayEvents.isEmpty && !_loading)
            div(classes: 'eduma-agenda-panel__empty', [
              div(classes: 'eduma-agenda-panel__empty-icon', [
                edumaIcon(EdumaIcons.calendarTick, size: 22),
              ]),
              strong([.text('No events scheduled for this day')]),
              p([
                .text(
                  'You have no scheduled classes, tasks, or study sessions on this date. Take some time to relax or plan a new session!',
                ),
              ]),
              button(
                classes: 'eduma-desktop-pill eduma-desktop-pill--primary eduma-agenda-panel__schedule-btn',
                type: ButtonType.button,
                onClick: () => setState(() => _createOpen = true),
                [
                  edumaIcon(EdumaIcons.addCircle, size: 17),
                  span([.text('Schedule Event')]),
                ],
              ),
            ])
          else
            for (var i = 0; i < dayEvents.length; i++)
              _agendaEventCard(dayEvents[i], index: i),
        ]),
        CalendarCreateDialog(
          open: _createOpen,
          initialDate: _selectedDate,
          onClose: () => setState(() => _createOpen = false),
          onCreated: (created) {
            setState(() => _createOpen = false);
            unawaited(_loadMonth(_visibleMonth));
          },
        ),
      ],
    );
  }

  Component _compactDayCell({
    required DateTime day,
    required bool inMonth,
    required bool isToday,
    required bool isSelected,
    required bool isBusy,
    required StreakDayEntry? streak,
    required VoidCallback onTap,
  }) {
    final streakState = !inMonth || streak == null ? null : streak.state;
    final cellCls = [
      'eduma-agenda-day',
      if (!inMonth) 'is-outside',
      if (isToday) 'is-today',
      if (isSelected) 'is-selected',
      if (streakState == 'studied') 'is-studied',
      if (streakState == 'missed') 'is-missed',
    ].join(' ');
    return button(
      classes: cellCls,
      type: ButtonType.button,
      onClick: onTap,
      [
        span(classes: 'eduma-agenda-day__num', [.text('${day.day}')]),
        span(
          classes: isBusy && inMonth
              ? 'eduma-agenda-day__dot is-busy'
              : 'eduma-agenda-day__dot',
          [],
        ),
      ],
    );
  }

  Component _agendaEventCard(CalendarEvent event, {required int index}) {
    final pastel = CalendarScheduleLogic.pastelStyleFor(event, indexOverride: index);
    final timeRange =
        '${formatShortClock(event.startTime)} – ${formatShortClock(event.endTime)}';
    return edumaLink(
      to: '/calendarTab',
      classes: 'eduma-agenda-event',
      attributes: {
        'style':
            '--agenda-fill: ${pastel.fill}; --agenda-bar: ${pastel.accentBar}; --agenda-ink: ${pastel.text};',
      },
      children: [
        span(classes: 'eduma-agenda-event__bar', attributes: {'aria-hidden': 'true'}, []),
        div(classes: 'eduma-agenda-event__body', [
          if (event.subject.isNotEmpty)
            span(classes: 'eduma-agenda-event__subject', [.text(event.subject)]),
          strong(classes: 'eduma-agenda-event__title', [.text(event.title)]),
          span(classes: 'eduma-agenda-event__time', [.text(timeRange)]),
        ]),
      ],
    );
  }
}
