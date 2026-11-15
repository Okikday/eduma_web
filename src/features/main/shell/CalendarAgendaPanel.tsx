import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { apiClient } from '../../../core/api/apiClient';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import {
  buildSundayFirstMonthGrid,
  formatTimeRange,
  isSameDay,
  toDateKey,
} from '../../../core/utils/dateFormatters';

interface AgendaEvent {
  id: string;
  title: string;
  startTime: string;
  endTime?: string | null;
  category?: string;
}

interface CalendarAgendaPanelProps {
  onCreateEvent?: () => void;
}

const WEEKDAYS = ['S', 'M', 'T', 'W', 'T', 'F', 'S'] as const;

export function CalendarAgendaPanel({ onCreateEvent }: CalendarAgendaPanelProps) {
  const [visibleMonth, setVisibleMonth] = useState<Date>(() => {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
  });
  const [selectedDate, setSelectedDate] = useState<Date>(() => new Date());
  const [events, setEvents] = useState<AgendaEvent[]>([]);
  const [loading, setLoading] = useState(true);

  const loadMonth = useCallback(async () => {
    setLoading(true);
    const start = new Date(
      visibleMonth.getFullYear(),
      visibleMonth.getMonth() - 1,
      1
    );
    const end = new Date(
      visibleMonth.getFullYear(),
      visibleMonth.getMonth() + 2,
      1
    );
    try {
      const res = await apiClient.get<{
        events?: Record<string, unknown>[];
        items?: Record<string, unknown>[];
      }>('/events', {
        params: {
          from: start.toISOString(),
          to: end.toISOString(),
          limit: 120,
        },
      });
      const list = Array.isArray(res)
        ? res
        : Array.isArray(res?.events)
        ? res.events
        : Array.isArray(res?.items)
        ? res.items
        : [];
      setEvents(
        list.map((e) => ({
          id: String(e.id || e._id || ''),
          title: String(e.title || 'Study Event'),
          startTime: String(e.startTime || e.start || e.date || ''),
          endTime:
            typeof e.endTime === 'string'
              ? e.endTime
              : typeof e.end === 'string'
              ? e.end
              : null,
          category: typeof e.category === 'string' ? e.category : 'study',
        }))
      );
    } catch {
      setEvents([]);
    } finally {
      setLoading(false);
    }
  }, [visibleMonth]);

  useEffect(() => {
    loadMonth();
    const unsub = AppSyncBus.subscribe('events:changed', loadMonth);
    return unsub;
  }, [loadMonth]);

  const eventsByKey = useMemo(() => {
    const map: Record<string, AgendaEvent[]> = {};
    for (const ev of events) {
      if (!ev.startTime) continue;
      const d = new Date(ev.startTime);
      if (Number.isNaN(d.getTime())) continue;
      const key = toDateKey(d);
      if (!map[key]) map[key] = [];
      map[key].push(ev);
    }
    return map;
  }, [events]);

  const monthCells = useMemo(
    () =>
      buildSundayFirstMonthGrid(
        visibleMonth.getFullYear(),
        visibleMonth.getMonth()
      ),
    [visibleMonth]
  );

  const selectedKey = toDateKey(selectedDate);
  const selectedEvents = eventsByKey[selectedKey] || [];
  const monthLabel = visibleMonth.toLocaleDateString(undefined, {
    month: 'long',
    year: 'numeric',
  });

  const shiftMonth = (delta: number) => {
    const next = new Date(
      visibleMonth.getFullYear(),
      visibleMonth.getMonth() + delta,
      1
    );
    setVisibleMonth(next);
    setSelectedDate(next);
  };

  const jumpToday = () => {
    const now = new Date();
    setSelectedDate(now);
    setVisibleMonth(new Date(now.getFullYear(), now.getMonth(), 1));
  };

  return (
    <aside className="flex h-full w-[340px] shrink-0 flex-col bg-[var(--eduma-bg)] px-4 pt-[22px] pb-4">
      {/* Compact MonthSwitcher + New Event icon */}
      <div className="flex items-center justify-between gap-2">
        <div className="flex min-w-0 items-center gap-1">
          <button
            type="button"
            onClick={() => shiftMonth(-1)}
            aria-label="Previous month"
            className="flex h-7 w-7 cursor-pointer items-center justify-center rounded-full text-[var(--eduma-text-muted)] transition hover:bg-[var(--eduma-card)] hover:text-[var(--eduma-text-primary)]"
          >
            <EdumaIcon family="huge-stroke" name="arrowLeft01" size={14} />
          </button>

          <button
            type="button"
            onClick={jumpToday}
            title="Jump to today"
            className="truncate px-1 text-[15px] font-bold text-[var(--eduma-text-primary)] hover:text-[var(--eduma-primary)] cursor-pointer"
          >
            {monthLabel}
          </button>

          <button
            type="button"
            onClick={() => shiftMonth(1)}
            aria-label="Next month"
            className="flex h-7 w-7 cursor-pointer items-center justify-center rounded-full text-[var(--eduma-text-muted)] transition hover:bg-[var(--eduma-card)] hover:text-[var(--eduma-text-primary)]"
          >
            <EdumaIcon family="huge-stroke" name="arrowRight01" size={14} />
          </button>
        </div>

        {onCreateEvent ? (
          <button
            type="button"
            onClick={onCreateEvent}
            aria-label="New event"
            title="New event"
            className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-full text-[var(--eduma-primary)] transition hover:bg-[var(--eduma-nav-pill)]"
          >
            <EdumaIcon family="iconsax" name="calendar_add_copy" size={20} />
          </button>
        ) : (
          <Link
            to={`/calendarTab?create=1&date=${encodeURIComponent(selectedKey)}`}
            aria-label="New event"
            title="New event"
            className="flex h-8 w-8 items-center justify-center rounded-full text-[var(--eduma-primary)] transition hover:bg-[var(--eduma-nav-pill)]"
          >
            <EdumaIcon family="iconsax" name="calendar_add_copy" size={20} />
          </Link>
        )}
      </div>

      {/* Compact MonthGrid */}
      <div className="mt-2">
        <div className="grid grid-cols-7 pb-1 text-center text-[11px] font-semibold text-[var(--eduma-text-muted)]">
          {WEEKDAYS.map((w, idx) => (
            <div key={`${w}-${idx}`}>{w}</div>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-y-0.5">
          {monthCells.map((cell) => {
            const count = (eventsByKey[cell.key] || []).length;
            const selected = isSameDay(cell.date, selectedDate);
            return (
              <button
                key={cell.key}
                type="button"
                onClick={() => setSelectedDate(cell.date)}
                className={`relative mx-auto flex h-8 w-8 cursor-pointer flex-col items-center justify-center rounded-full text-[12px] font-semibold transition ${
                  selected
                    ? 'bg-[var(--eduma-primary)] text-white'
                    : cell.isToday
                    ? 'bg-[var(--eduma-nav-pill)] font-bold text-[var(--eduma-primary)]'
                    : 'text-[var(--eduma-text-primary)] hover:bg-[var(--eduma-card)]'
                } ${cell.inCurrentMonth ? '' : 'opacity-35'}`}
              >
                <span>{cell.date.getDate()}</span>
                {count > 0 ? (
                  <span
                    className="absolute bottom-0.5 h-1 w-1 rounded-full"
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

      <div className="my-3 h-[0.5px] bg-[var(--eduma-border)]" />

      {/* CalendarDayPanel */}
      <div className="mb-2 flex items-center justify-between gap-2">
        <p className="text-[13.5px] font-bold text-[var(--eduma-text-primary)]">
          {isSameDay(selectedDate, new Date())
            ? 'Today'
            : selectedDate.toLocaleDateString(undefined, {
                weekday: 'short',
                month: 'short',
                day: 'numeric',
              })}
        </p>
        <Link
          to={`/calendarTab?date=${encodeURIComponent(selectedKey)}`}
          className="text-[12px] font-semibold text-[var(--eduma-primary)] hover:underline"
        >
          Open calendar
        </Link>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto pr-0.5">
        {loading ? (
          <p className="py-3 text-[12.5px] text-[var(--eduma-text-muted)]">
            Loading schedule…
          </p>
        ) : selectedEvents.length === 0 ? (
          <div className="rounded-[16px] border border-[var(--eduma-border-subtle)] bg-[var(--eduma-surface)]/70 p-3.5 text-center">
            <p className="text-[13px] font-semibold text-[var(--eduma-text-secondary)]">
              Nothing scheduled
            </p>
            <p className="mt-0.5 text-[12px] text-[var(--eduma-text-muted)]">
              Your day is open.
            </p>
          </div>
        ) : (
          <div className="space-y-2">
            {selectedEvents.map((ev) => (
              <Link
                key={ev.id}
                to={`/calendarTab?date=${encodeURIComponent(selectedKey)}`}
                className="block rounded-[14px] border border-[var(--eduma-border-subtle)] bg-[var(--eduma-surface)] p-3 transition hover:border-[var(--eduma-primary)]/40"
              >
                <p className="truncate text-[13px] font-semibold text-[var(--eduma-text-primary)]">
                  {ev.title}
                </p>
                <p className="mt-0.5 text-[11.5px] text-[var(--eduma-text-muted)]">
                  {formatTimeRange(ev.startTime, ev.endTime)}
                </p>
              </Link>
            ))}
          </div>
        )}
      </div>
    </aside>
  );
}
