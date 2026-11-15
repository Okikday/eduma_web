import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import {
  buildSundayFirstMonthGrid,
  formatTimeRange,
  isSameDay,
  toDateKey,
} from '../../../core/utils/dateFormatters';
import { AppButton } from '../../../shared/components/AppButton';
import { AppCircleIconButton } from '../../../shared/components/AppCircleIconButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { AppModalDialog } from '../../../shared/components/AppModalDialog';
import { useToast } from '../../../shared/components/AppToast';
import {
  DesktopActionButton,
  DesktopPageHeader,
} from '../../../shared/components/DesktopPageHeader';
import { useViewportWidth } from '../../../shared/components/formFactor';
import { MainShell } from '../../main/shell/MainShell';
import { eventsApi } from '../data/eventsApi';
import { groupEventsByDateKey, positionEventsForDay } from '../logic/calendarLogic';
import { EVENT_CATEGORY_META, type CalendarEvent } from '../models/calendarModels';
import { CreateEventDialog } from './CreateEventDialog';

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as const;

export function CalendarView() {
  const [searchParams] = useSearchParams();
  const { showToast } = useToast();
  const width = useViewportWidth();
  const isSplitDesktop = width >= 800; // Matches CalendarDesktopView.minDesktopWidth = 800

  const [cursorMonth, setCursorMonth] = useState<Date>(() => {
    const qDate = searchParams.get('date');
    if (qDate) {
      const d = new Date(`${qDate}T12:00:00`);
      if (!Number.isNaN(d.getTime())) return new Date(d.getFullYear(), d.getMonth(), 1);
    }
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
  });

  const [selectedDay, setSelectedDay] = useState<Date>(() => {
    const qDate = searchParams.get('date');
    if (qDate) {
      const d = new Date(`${qDate}T12:00:00`);
      if (!Number.isNaN(d.getTime())) return d;
    }
    return new Date();
  });

  const [miniOpen, setMiniOpen] = useState(true);
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [createOpen, setCreateOpen] = useState(
    () => searchParams.get('create') === '1'
  );
  const [browseAllOpen, setBrowseAllOpen] = useState(false);
  const [activeEvent, setActiveEvent] = useState<CalendarEvent | null>(null);
  const [editingEvent, setEditingEvent] = useState<CalendarEvent | null>(null);

  const loadMonthEvents = useCallback(async () => {
    setLoading(true);
    const start = new Date(
      cursorMonth.getFullYear(),
      cursorMonth.getMonth() - 1,
      1
    );
    const end = new Date(
      cursorMonth.getFullYear(),
      cursorMonth.getMonth() + 2,
      1
    );
    try {
      const list = await eventsApi.listEvents({
        from: start.toISOString(),
        to: end.toISOString(),
        limit: 200,
      });
      setEvents(list);
    } catch {
      setEvents([]);
    } finally {
      setLoading(false);
    }
  }, [cursorMonth]);

  useEffect(() => {
    loadMonthEvents();
    const unsub = AppSyncBus.subscribe('events:changed', loadMonthEvents);
    return unsub;
  }, [loadMonthEvents]);

  const monthCells = useMemo(
    () =>
      buildSundayFirstMonthGrid(
        cursorMonth.getFullYear(),
        cursorMonth.getMonth()
      ),
    [cursorMonth]
  );

  const groupedByKey = useMemo(() => groupEventsByDateKey(events), [events]);
  const selectedKey = toDateKey(selectedDay);
  const selectedEvents = groupedByKey[selectedKey] || [];
  const positionedTimeline = useMemo(
    () => positionEventsForDay(selectedEvents),
    [selectedEvents]
  );

  const handleDeleteEvent = async (ev: CalendarEvent) => {
    if (!window.confirm(`Delete "${ev.title}"?`)) return;
    await eventsApi.deleteEvent(ev.id);
    setActiveEvent(null);
    showToast('Event deleted.', 'success');
    loadMonthEvents();
    AppSyncBus.emit('events:changed');
  };

  const monthLabel = cursorMonth.toLocaleDateString(undefined, {
    month: 'long',
    year: 'numeric',
  });

  const shiftMonth = (delta: number) => {
    setCursorMonth(
      (prev) => new Date(prev.getFullYear(), prev.getMonth() + delta, 1)
    );
  };

  const jumpToToday = () => {
    const now = new Date();
    setSelectedDay(now);
    setCursorMonth(new Date(now.getFullYear(), now.getMonth(), 1));
  };

  const nowMinutes = new Date().getHours() * 60 + new Date().getMinutes();
  const isTodaySelected = isSameDay(selectedDay, new Date());
  const upcomingCount = useMemo(
    () => events.filter((ev) => new Date(ev.startTime).getTime() >= Date.now()).length,
    [events]
  );

  return (
    <MainShell
      activeTab="calendar"
      onQuickCreateEvent={() => setCreateOpen(true)}
    >
      {isSplitDesktop ? (
        <DesktopPageHeader
          leading={
            <div className="flex flex-wrap items-center gap-2">
              <AppCircleIconButton
                label="Previous month"
                size={38}
                onClick={() => shiftMonth(-1)}
              >
                <EdumaIcon family="huge-stroke" name="arrowLeft01" size={16} />
              </AppCircleIconButton>
              <h1 className="min-w-[165px] text-center text-[22px] font-bold tracking-[-0.02em] text-[var(--eduma-text-primary)]">
                {monthLabel}
              </h1>
              <AppCircleIconButton
                label="Next month"
                size={38}
                onClick={() => shiftMonth(1)}
              >
                <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
              </AppCircleIconButton>
              <button
                type="button"
                onClick={jumpToToday}
                className="ml-1 inline-flex h-[34px] items-center rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 text-[12.5px] font-bold text-[var(--eduma-text-primary)] transition hover:border-[var(--eduma-primary)]"
              >
                Today
              </button>
            </div>
          }
          actions={
            <>
              <AppCircleIconButton
                label="Refresh events"
                size={42}
                onClick={() => void loadMonthEvents()}
              >
                <EdumaIcon family="iconsax" name="refresh_copy" size={18} />
              </AppCircleIconButton>
              {upcomingCount > 0 ? (
                <span className="inline-flex h-[38px] items-center gap-1.5 rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 text-[12.5px] font-bold text-[var(--eduma-text-secondary)]">
                  <EdumaIcon family="huge-stroke" name="calendar03" size={15} color="var(--eduma-primary)" />
                  <span>{upcomingCount} upcoming</span>
                </span>
              ) : null}
              <DesktopActionButton
                label="Browse all"
                onClick={() => setBrowseAllOpen(true)}
              />
              <DesktopActionButton
                label="New event"
                variant="filled"
                icon={<EdumaIcon family="huge-stroke" name="calendarAdd01" size={16} />}
                onClick={() => {
                  setEditingEvent(null);
                  setCreateOpen(true);
                }}
              />
            </>
          }
        />
      ) : null}

      <div className={isSplitDesktop ? 'w-full px-8 pb-8 pt-2' : 'mx-auto w-full max-w-[1260px] px-4 py-5 sm:px-6'}>
        {/* Mobile Header */}
        {!isSplitDesktop ? (
          <header className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="type-display-sm text-[var(--eduma-text-primary)]">
                Calendar
              </h1>
              <p className="type-body-sm mt-0.5 text-[var(--eduma-text-muted)]">
                {selectedDay.toLocaleDateString(undefined, {
                  weekday: 'long',
                  month: 'long',
                  day: 'numeric',
                })}
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <AppButton variant="secondary" size="sm" onClick={jumpToToday}>
                Today
              </AppButton>
              <AppButton
                variant="secondary"
                size="sm"
                onClick={() => setBrowseAllOpen(true)}
              >
                All events ({events.length})
              </AppButton>
              <AppButton
                size="sm"
                onClick={() => {
                  setEditingEvent(null);
                  setCreateOpen(true);
                }}
                leadingIcon={<EdumaIcon family="huge-stroke" name="calendarAdd01" size={16} />}
              >
                New event
              </AppButton>
            </div>
          </header>
        ) : null}

        {isSplitDesktop ? (
          /* Desktop Split Layout: 7:3 10-column MonthGrid + CalendarDayPanel */
          <div className="grid grid-cols-10 gap-7">
            <section className="eduma-card-surface col-span-7 rounded-[24px] p-5">
              <div className="grid grid-cols-7 gap-1 pb-2 text-center text-[11.5px] font-bold uppercase tracking-wider text-[var(--eduma-text-muted)]">
                {WEEKDAYS.map((w) => (
                  <div key={w}>{w}</div>
                ))}
              </div>

              <div className="grid grid-cols-7 gap-1.5">
                {monthCells.map((cell) => {
                  const dayList = groupedByKey[cell.key] || [];
                  const selected = isSameDay(cell.date, selectedDay);
                  return (
                    <button
                      key={cell.key}
                      type="button"
                      onClick={() => setSelectedDay(cell.date)}
                      className={`flex min-h-[82px] cursor-pointer flex-col justify-between rounded-[14px] border p-2 text-left transition ${
                        selected
                          ? 'border-[var(--eduma-primary)] bg-[var(--eduma-nav-pill)]'
                          : 'border-[var(--eduma-border-subtle)] bg-[var(--eduma-surface)]/75 hover:border-[var(--eduma-border)]'
                      } ${cell.inCurrentMonth ? '' : 'opacity-45'}`}
                    >
                      <span
                        className={`inline-flex h-6 w-6 items-center justify-center rounded-full text-[12px] font-bold ${
                          cell.isToday
                            ? 'bg-[var(--eduma-primary)] text-white'
                            : 'text-[var(--eduma-text-primary)]'
                        }`}
                      >
                        {cell.date.getDate()}
                      </span>

                      <div className="mt-1 space-y-0.5">
                        {dayList.slice(0, 2).map((ev) => (
                          <div
                            key={ev.id}
                            className="truncate rounded px-1 py-0.5 text-[10.5px] font-semibold text-white"
                            style={{
                              backgroundColor:
                                EVENT_CATEGORY_META[ev.category].colorVar,
                            }}
                          >
                            {ev.title}
                          </div>
                        ))}
                        {dayList.length > 2 ? (
                          <span className="block text-[10px] font-bold text-[var(--eduma-text-muted)]">
                            +{dayList.length - 2} more
                          </span>
                        ) : null}
                      </div>
                    </button>
                  );
                })}
              </div>
            </section>

            {/* Right CalendarDayPanel */}
            <aside className="eduma-card-surface col-span-3 flex flex-col rounded-[24px] p-5">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="type-title-lg text-[var(--eduma-text-primary)]">
                  Day schedule
                </h2>
                <span className="rounded-full bg-[var(--eduma-nav-pill)] px-2.5 py-0.5 text-[12px] font-bold text-[var(--eduma-primary)]">
                  {selectedEvents.length} events
                </span>
              </div>

              {loading ? (
                <p className="type-body-sm text-[var(--eduma-text-muted)]">
                  Loading events…
                </p>
              ) : selectedEvents.length === 0 ? (
                <AppEmptyState
                  compact
                  iconName="calendar03"
                  title="Nothing planned"
                  description="Tap New event to block off study time for this date."
                />
              ) : (
                <div className="space-y-2.5">
                  {selectedEvents.map((ev) => (
                    <button
                      key={ev.id}
                      type="button"
                      onClick={() => setActiveEvent(ev)}
                      className="w-full cursor-pointer rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] p-3.5 text-left transition hover:border-[var(--eduma-primary)]/45"
                    >
                      <div className="flex items-center gap-2">
                        <span
                          className="h-2.5 w-2.5 shrink-0 rounded-full"
                          style={{
                            backgroundColor:
                              EVENT_CATEGORY_META[ev.category].colorVar,
                          }}
                        />
                        <p className="type-title-sm truncate text-[var(--eduma-text-primary)]">
                          {ev.title}
                        </p>
                      </div>
                      <p className="type-body-sm mt-1 text-[var(--eduma-text-muted)]">
                        {formatTimeRange(ev.startTime, ev.endTime)}
                        {ev.spaceTitle ? ` · ${ev.spaceTitle}` : ''}
                      </p>
                    </button>
                  ))}
                </div>
              )}
            </aside>
          </div>
        ) : (
          /* Mobile / Compact CalendarTab with collapsible MiniCalendarHeader + 24h Timeline */
          <div className="space-y-4">
            <section className="eduma-card-surface rounded-[20px] p-4">
              <div className="flex items-center justify-between">
                <button
                  type="button"
                  onClick={() => setMiniOpen((o) => !o)}
                  className="flex cursor-pointer items-center gap-1.5 font-bold text-[var(--eduma-text-primary)]"
                >
                  <span>{monthLabel}</span>
                  <EdumaIcon
                    family="huge-stroke"
                    name={miniOpen ? 'arrowDown01' : 'arrowRight01'}
                    size={16}
                  />
                </button>
                <div className="flex items-center gap-1">
                  <AppCircleIconButton label="Previous month" size={32} onClick={() => shiftMonth(-1)}>
                    <EdumaIcon family="huge-stroke" name="arrowLeft01" size={15} />
                  </AppCircleIconButton>
                  <AppCircleIconButton label="Next month" size={32} onClick={() => shiftMonth(1)}>
                    <EdumaIcon family="huge-stroke" name="arrowRight01" size={15} />
                  </AppCircleIconButton>
                </div>
              </div>

              {miniOpen ? (
                <div className="mt-3">
                  <div className="grid grid-cols-7 gap-1 pb-1.5 text-center text-[10.5px] font-bold uppercase text-[var(--eduma-text-muted)]">
                    {WEEKDAYS.map((w) => (
                      <div key={w}>{w[0]}</div>
                    ))}
                  </div>
                  <div className="grid grid-cols-7 gap-1">
                    {monthCells.map((cell) => {
                      const hasEvents = (groupedByKey[cell.key] || []).length > 0;
                      const selected = isSameDay(cell.date, selectedDay);
                      return (
                        <button
                          key={cell.key}
                          type="button"
                          onClick={() => setSelectedDay(cell.date)}
                          className={`relative flex h-9 cursor-pointer flex-col items-center justify-center rounded-xl text-[13px] font-semibold ${
                            selected
                              ? 'bg-[var(--eduma-primary)] text-white'
                              : cell.isToday
                              ? 'bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]'
                              : 'text-[var(--eduma-text-primary)]'
                          } ${cell.inCurrentMonth ? '' : 'opacity-40'}`}
                        >
                          <span>{cell.date.getDate()}</span>
                          {hasEvents ? (
                            <span
                              className="h-1 w-1 rounded-full"
                              style={{
                                backgroundColor: selected
                                  ? '#ffffff'
                                  : 'var(--eduma-primary)',
                              }}
                            />
                          ) : null}
                        </button>
                      );
                    })}
                  </div>
                </div>
              ) : null}
            </section>

            {/* 24h CalendarTimelineSchedule */}
            <section className="eduma-card-surface relative rounded-[20px] p-4">
              <div className="relative" style={{ height: `${24 * 52}px` }}>
                {Array.from({ length: 24 }, (_, hour) => (
                  <div
                    key={hour}
                    className="flex items-start border-t border-[var(--eduma-border-subtle)] text-[11px] font-semibold text-[var(--eduma-text-muted)]"
                    style={{ height: '52px' }}
                  >
                    <span className="-mt-2 w-12 shrink-0 bg-[var(--eduma-surface)] pr-2">
                      {hour === 0
                        ? '12 AM'
                        : hour < 12
                        ? `${hour} AM`
                        : hour === 12
                        ? '12 PM'
                        : `${hour - 12} PM`}
                    </span>
                  </div>
                ))}

                {/* Current time red marker */}
                {isTodaySelected ? (
                  <div
                    className="pointer-events-none absolute right-0 left-12 z-20 flex items-center"
                    style={{ top: `${(nowMinutes / 1440) * 100}%` }}
                  >
                    <span className="h-2.5 w-2.5 -ml-1 rounded-full bg-[var(--eduma-error)]" />
                    <div className="h-[1.5px] flex-1 bg-[var(--eduma-error)]" />
                  </div>
                ) : null}

                {/* Positioned overlapping events */}
                <div className="pointer-events-none absolute inset-y-0 right-0 left-12">
                  {positionedTimeline.map((pos) => {
                    const widthPct = 100 / pos.columnCount;
                    const leftPct = pos.column * widthPct;
                    return (
                      <button
                        key={pos.item.id}
                        type="button"
                        onClick={() => setActiveEvent(pos.item.event)}
                        className="pointer-events-auto absolute cursor-pointer overflow-hidden rounded-xl border border-white/20 px-2.5 py-1.5 text-left text-white shadow-sm"
                        style={{
                          top: `${pos.topPercent}%`,
                          height: `${pos.heightPercent}%`,
                          left: `${leftPct}%`,
                          width: `calc(${widthPct}% - 4px)`,
                          backgroundColor:
                            EVENT_CATEGORY_META[pos.item.event.category].colorVar,
                        }}
                      >
                        <p className="truncate text-[12px] font-bold">
                          {pos.item.event.title}
                        </p>
                        <p className="truncate text-[10.5px] opacity-90">
                          {formatTimeRange(
                            pos.item.event.startTime,
                            pos.item.event.endTime
                          )}
                        </p>
                      </button>
                    );
                  })}
                </div>
              </div>
            </section>
          </div>
        )}
      </div>

      <CreateEventDialog
        open={createOpen}
        defaultDate={selectedDay}
        defaultSpaceId={searchParams.get('spaceId') || ''}
        editingEvent={editingEvent}
        onClose={() => {
          setCreateOpen(false);
          setEditingEvent(null);
        }}
        onSaved={loadMonthEvents}
      />

      {/* Event Detail Modal */}
      <AppModalDialog
        open={Boolean(activeEvent)}
        onClose={() => setActiveEvent(null)}
        title={activeEvent?.title || 'Event'}
        subtitle={
          activeEvent
            ? formatTimeRange(activeEvent.startTime, activeEvent.endTime)
            : ''
        }
      >
        {activeEvent ? (
          <div className="space-y-4">
            <div className="flex flex-wrap items-center gap-2">
              <span
                className="rounded-full px-3 py-1 text-[12px] font-bold text-white"
                style={{
                  backgroundColor:
                    EVENT_CATEGORY_META[activeEvent.category].colorVar,
                }}
              >
                {EVENT_CATEGORY_META[activeEvent.category].label}
              </span>
              {activeEvent.spaceTitle ? (
                <span className="rounded-full bg-[var(--eduma-nav-pill)] px-3 py-1 text-[12px] font-semibold text-[var(--eduma-primary)]">
                  {activeEvent.spaceTitle}
                </span>
              ) : null}
            </div>

            {activeEvent.description ? (
              <p className="type-body-md text-[var(--eduma-text-secondary)]">
                {activeEvent.description}
              </p>
            ) : null}

            <div className="flex justify-between gap-2 pt-2">
              <AppButton
                variant="danger"
                size="sm"
                onClick={() => handleDeleteEvent(activeEvent)}
              >
                Delete event
              </AppButton>
              <AppButton
                variant="secondary"
                size="sm"
                onClick={() => {
                  const target = activeEvent;
                  setActiveEvent(null);
                  setEditingEvent(target);
                  setCreateOpen(true);
                }}
              >
                Edit event
              </AppButton>
            </div>
          </div>
        ) : null}
      </AppModalDialog>

      {/* Browse All Events Modal */}
      <AppModalDialog
        open={browseAllOpen}
        onClose={() => setBrowseAllOpen(false)}
        title="Upcoming events"
        maxWidth={560}
      >
        {events.length === 0 ? (
          <AppEmptyState compact title="No scheduled events" />
        ) : (
          <div className="space-y-2.5">
            {events.map((ev) => (
              <button
                key={ev.id}
                type="button"
                onClick={() => {
                  setBrowseAllOpen(false);
                  const d = new Date(ev.startTime);
                  setSelectedDay(d);
                  setCursorMonth(new Date(d.getFullYear(), d.getMonth(), 1));
                  setActiveEvent(ev);
                }}
                className="w-full cursor-pointer rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] p-3.5 text-left hover:border-[var(--eduma-primary)]/40"
              >
                <p className="type-title-sm text-[var(--eduma-text-primary)]">
                  {ev.title}
                </p>
                <p className="type-body-sm mt-0.5 text-[var(--eduma-text-muted)]">
                  {new Date(ev.startTime).toLocaleDateString()} ·{' '}
                  {formatTimeRange(ev.startTime, ev.endTime)}
                </p>
              </button>
            ))}
          </div>
        )}
      </AppModalDialog>
    </MainShell>
  );
}
