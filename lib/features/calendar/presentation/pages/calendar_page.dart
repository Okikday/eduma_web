import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../auth/logic/auth_actions.dart';
import '../../../main/data/main_space.dart';
import '../../../main/presentation/widgets/app_tab_shell.dart';
import '../../../main/presentation/widgets/main_home_navigation.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../../notifications/data/notifications_api.dart';
import '../../logic/calendar_actions.dart';
import '../widgets/calendar_create_dialog.dart';
import '../widgets/calendar_day_agenda.dart';
import '../widgets/calendar_mini_month.dart';
import '../widgets/calendar_modals.dart';

/// Native Eduma Calendar view matching `CalendarDesktopView` and `CalendarTab`
/// in `../eduma` (`/calendarTab` & `/calendar`).
class CalendarPage extends StatefulComponent {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  EdumaSession? _session = AuthActions.currentSession;
  bool _loadingSession = AuthActions.currentSession == null;
  String? _sessionError;
  int _unreadNotifications = 0;

  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  List<CalendarEvent> _events = const [];
  bool _loadingEvents = false;
  String? _error;
  String? _notice;
  bool _noticeIsError = false;

  bool _createOpen = false;
  late DateTime _createInitialDate;
  bool _browseAllOpen = false;
  CalendarEventKind? _browseKind;
  CalendarEvent? _detailEvent;
  CalendarEvent? _editingEvent;
  Set<String> _deletingIds = const {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _createInitialDate = _selectedDate;
    final session = _session;
    if (session != null) {
      EdumaMemoryCache.instance.ensureUser(session.userId);
      final cached = EdumaMemoryCache.instance.calendarMonths[EdumaMemoryCache.monthKey(_visibleMonth)];
      if (cached != null) {
        _events = cached;
        _loadingSession = false;
      }
      _unreadNotifications = EdumaMemoryCache.instance.unreadNotifications ?? 0;
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    final hasCached = _events.isNotEmpty;
    setState(() {
      _loadingSession = _session == null;
      _loadingEvents = !hasCached;
      _sessionError = null;
      _error = null;
    });

    try {
      final session = await AuthActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _session = null;
          _events = const [];
        });
        return;
      }
      setState(() => _session = session);
      await Future.wait([
        _loadMonth(_visibleMonth),
        _loadUnread(),
      ]);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _sessionError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sessionError = 'Could not load your session right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loadingEvents = false;
        });
      }
    }
  }

  Future<void> _loadUnread() async {
    final unread = await NotificationsApi.instance.loadUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotifications = unread);
  }

  Future<void> _loadMonth(DateTime month) async {
    final key = EdumaMemoryCache.monthKey(month);
    final cached = EdumaMemoryCache.instance.calendarMonths[key];
    setState(() {
      if (cached != null) _events = cached;
      _loadingEvents = cached == null;
      _error = null;
    });
    try {
      final list = await CalendarActions.loadMonthEvents(month: month);
      if (!mounted) return;
      EdumaMemoryCache.instance.calendarMonths[key] = list;
      setState(() => _events = list);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load events for this month.');
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  void _shiftMonth(int delta) {
    final targetMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    final daysInTarget = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final clampedDay = _selectedDate.day.clamp(1, daysInTarget);
    setState(() {
      _visibleMonth = targetMonth;
      _selectedDate = DateTime(targetMonth.year, targetMonth.month, clampedDay);
    });
    unawaited(_loadMonth(targetMonth));
  }

  void _shiftDay(int delta) {
    _selectDay(_selectedDate.add(Duration(days: delta)));
  }

  void _jumpToToday() {
    final now = DateTime.now();
    _selectDay(DateTime(now.year, now.month, now.day));
  }

  void _selectDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final month = DateTime(normalized.year, normalized.month, 1);
    final changedMonth = month.year != _visibleMonth.year || month.month != _visibleMonth.month;
    setState(() {
      _selectedDate = normalized;
      if (changedMonth) _visibleMonth = month;
    });
    if (changedMonth) unawaited(_loadMonth(month));
  }

  void _openCreateAt(DateTime initialDate) {
    setState(() {
      _editingEvent = null;
      _createInitialDate = initialDate;
      _createOpen = true;
    });
  }

  void _openEditEvent(CalendarEvent event) {
    setState(() {
      _detailEvent = null;
      _editingEvent = event;
      _createInitialDate = event.startTime;
      _createOpen = true;
    });
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    if (_deletingIds.contains(event.id)) return;
    setState(() {
      _deletingIds = {..._deletingIds, event.id};
      _notice = null;
    });
    try {
      await CalendarActions.deleteEvent(event.id);
      if (!mounted) return;
      setState(() {
        _events = _events.where((item) => item.id != event.id).toList();
        if (_detailEvent?.id == event.id) _detailEvent = null;
        _notice = 'Removed “${event.title}”.';
        _noticeIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = 'Could not remove “${event.title}”.';
        _noticeIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _deletingIds = {..._deletingIds}..remove(event.id));
      }
    }
  }

  @override
  Component build(BuildContext context) {
    final session = _session;
    final dayEvents = CalendarScheduleLogic.eventsOnDay(_events, _selectedDate);
    final eventsByDay = CalendarScheduleLogic.groupByDay(_events);
    final upcoming = CalendarScheduleLogic.summarizeUpcoming(_events, now: DateTime.now());
    final hasNearEvent = upcoming?.hasNearEvent ?? false;
    final upcomingEvents = _events.where((event) => event.endTime.isAfter(DateTime.now())).toList()
      ..sort((first, second) => first.startTime.compareTo(second.startTime));

    return div(
      classes: session != null ? 'main-home eduma-cal-page' : 'main-home main-home--gate',
      [
        if (session != null)
          mainHomeDesktopRail(
            session,
            activeTab: .calendar,
            unreadNotifications: _unreadNotifications,
            sidebarContent: [
              mainHomeRailSection(
                title: 'Upcoming events',
                onSeeAll: () => setState(() => _browseAllOpen = true),
                items: [
                  for (final event in upcomingEvents.take(4))
                    mainHomeRailItem(
                      icon: EdumaIcons.calendar,
                      title: event.title,
                      subtitle: '${formatShortDate(event.startTime)} · ${formatShortClock(event.startTime)}',
                      onClick: () => setState(() => _detailEvent = event),
                    ),
                ],
                emptyMessage: _loadingEvents ? 'Loading events…' : 'No upcoming events this month.',
              ),
            ],
          ),
        div(classes: 'main-home__center-wrap', [
          div(classes: 'main-home__content eduma-cal-content', [
            if (session == null)
              appSessionGateBody(
                session: session,
                loadingSession: _loadingSession,
                sessionError: _sessionError,
                onRetrySession: () => unawaited(_load()),
                builder: (_) => const [],
              )
            else ...[
              // ── Desktop View (CalendarDesktopView >= 840px) ──────────────────
              div(classes: 'eduma-cal-desktop', [
                desktopPinnedPageHeader(
                  title: 'Calendar',
                  classes: 'eduma-cal-desktop__header',
                  leading: calendarMonthSwitcher(
                    visibleMonth: _visibleMonth,
                    hasNearEvent: hasNearEvent,
                    onShiftMonth: _shiftMonth,
                    onToday: _jumpToToday,
                  ),
                  actions: [
                    if (upcoming case final item?)
                      calendarUpcomingSummaryChip(
                        summary: item.summary,
                        onTap: () => _selectDay(item.date),
                      ),
                    desktopPillButton(
                      icon: EdumaIcons.search,
                      label: 'Browse all',
                      variant: .tonal,
                      onPressed: () => setState(() => _browseAllOpen = true),
                    ),
                    desktopPillButton(
                      icon: EdumaIcons.calendarAdd,
                      label: 'New event',
                      variant: .primary,
                      onPressed: () => _openCreateAt(_selectedDate),
                    ),
                  ],
                ),
                if (_notice case final msg?)
                  div(classes: 'eduma-cal-desktop__notices', [
                    mainHomeNotice(msg, isError: _noticeIsError),
                  ]),
                div(classes: 'eduma-cal-desktop__split', [
                  div(classes: 'eduma-cal-desktop__month', [
                    calendarDesktopMonthGrid(
                      visibleMonth: _visibleMonth,
                      selectedDate: _selectedDate,
                      eventsByDay: eventsByDay,
                      onSelectDate: _selectDay,
                      onCreateOnDay: _openCreateAt,
                      onOpenEvent: (event) => setState(() => _detailEvent = event),
                    ),
                  ]),
                  aside(
                    classes: 'eduma-cal-desktop__panel',
                    attributes: {'aria-label': 'Selected day schedule'},
                    [
                      calendarDayHeading(
                        selectedDate: _selectedDate,
                        sessionCount: dayEvents.length,
                        hasError: _error != null && _events.isEmpty,
                        onPrevDay: () => _shiftDay(-1),
                        onNextDay: () => _shiftDay(1),
                      ),
                      div(classes: 'eduma-cal-desktop__timeline-scroll', [
                        calendarTimelineSchedule(
                          selectedDate: _selectedDate,
                          dayEvents: dayEvents,
                          loading: _loadingEvents,
                          hasError: _error != null && _events.isEmpty,
                          onRetry: () => unawaited(_loadMonth(_visibleMonth)),
                          onOpenCreateNow: () => _openCreateAt(_selectedDate),
                          onOpenCreateAt: _openCreateAt,
                          onOpenEvent: (event) => setState(() => _detailEvent = event),
                          isCompact: false,
                        ),
                      ]),
                    ],
                  ),
                ]),
              ]),

              // ── Mobile View (CalendarTab < 840px) ────────────────────────────
              div(classes: 'eduma-cal-mobile', [
                calendarMobileMiniHeader(
                  selectedDate: _selectedDate,
                  eventsByDay: eventsByDay,
                  hasNearEvent: hasNearEvent,
                  upcoming: upcoming,
                  onSelectDate: _selectDay,
                  onOpenBrowseAll: () => setState(() => _browseAllOpen = true),
                ),
                if (_notice case final msg?)
                  div(classes: 'eduma-cal-mobile__notices', [
                    mainHomeNotice(msg, isError: _noticeIsError),
                  ]),
                div(classes: 'eduma-cal-mobile__body', [
                  calendarDayHeading(
                    selectedDate: _selectedDate,
                    sessionCount: dayEvents.length,
                    hasError: _error != null && _events.isEmpty,
                    onPrevDay: () => _shiftDay(-1),
                    onNextDay: () => _shiftDay(1),
                  ),
                  div(classes: 'eduma-cal-mobile__timeline', [
                    calendarTimelineSchedule(
                      selectedDate: _selectedDate,
                      dayEvents: dayEvents,
                      loading: _loadingEvents,
                      hasError: _error != null && _events.isEmpty,
                      onRetry: () => unawaited(_loadMonth(_visibleMonth)),
                      onOpenCreateNow: () => _openCreateAt(_selectedDate),
                      onOpenCreateAt: _openCreateAt,
                      onOpenEvent: (event) => setState(() => _detailEvent = event),
                      isCompact: true,
                    ),
                  ]),
                ]),
              ]),

              mainHomeMobileNavigation(
                activeTab: .calendar,
                showActionsMenu: false,
                onPrimaryAction: () => _openCreateAt(_selectedDate),
              ),
            ],
          ]),
        ]),
        CalendarCreateDialog(
          open: _createOpen,
          initialDate: _createInitialDate,
          editingEvent: _editingEvent,
          onClose: () => setState(() {
            _createOpen = false;
            _editingEvent = null;
          }),
          onCreated: (saved) {
            final wasEditing = _editingEvent != null;
            if (saved != null) {
              setState(() {
                _selectedDate = DateTime(
                  saved.startTime.year,
                  saved.startTime.month,
                  saved.startTime.day,
                );
                _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
                _notice = wasEditing ? 'Updated “${saved.title}”.' : 'Scheduled “${saved.title}”.';
                _noticeIsError = false;
              });
            }
            unawaited(_loadMonth(_visibleMonth));
          },
        ),
        browseAllEventsModal(
          open: _browseAllOpen,
          allEvents: _events,
          selectedKind: _browseKind,
          onSelectKind: (kind) => setState(() => _browseKind = kind),
          onSelectEvent: (event) => setState(() {
            _browseAllOpen = false;
            _detailEvent = event;
          }),
          onClose: () => setState(() => _browseAllOpen = false),
        ),
        calendarEventDetailModal(
          event: _detailEvent,
          deleting: _detailEvent != null && _deletingIds.contains(_detailEvent!.id),
          onClose: () => setState(() => _detailEvent = null),
          onEdit: _openEditEvent,
          onDelete: (event) => unawaited(_deleteEvent(event)),
        ),
      ],
    );
  }
}
