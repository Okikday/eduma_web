import {
  layoutTimelineEvents,
  toDateKey,
  type PositionedTimelineItem,
  type TimelineItemInput,
} from '../../../core/utils/dateFormatters';
import type { CalendarEvent, EventCategory } from '../models/calendarModels';

export function normalizeEventCategory(raw?: string | null): EventCategory {
  const val = (raw || '').toLowerCase();
  if (val === 'study' || val === 'lecture' || val === 'exam' || val === 'deadline') {
    return val;
  }
  return 'other';
}

export function groupEventsByDateKey(
  events: readonly CalendarEvent[]
): Record<string, CalendarEvent[]> {
  const grouped: Record<string, CalendarEvent[]> = {};
  for (const ev of events) {
    const dt = new Date(ev.startTime);
    if (Number.isNaN(dt.getTime())) continue;
    const key = toDateKey(dt);
    if (!grouped[key]) grouped[key] = [];
    grouped[key].push(ev);
  }
  for (const list of Object.values(grouped)) {
    list.sort(
      (a, b) => Date.parse(a.startTime) - Date.parse(b.startTime)
    );
  }
  return grouped;
}

export interface TimelineCalendarEvent extends TimelineItemInput {
  event: CalendarEvent;
}

export function positionEventsForDay(
  dayEvents: readonly CalendarEvent[]
): PositionedTimelineItem<TimelineCalendarEvent>[] {
  const inputs: TimelineCalendarEvent[] = dayEvents.map((event) => {
    const start = new Date(event.startTime);
    const startMinutes = start.getHours() * 60 + start.getMinutes();
    let endMinutes = startMinutes + 60;
    if (event.endTime) {
      const end = new Date(event.endTime);
      if (!Number.isNaN(end.getTime())) {
        const diff =
          (end.getTime() - start.getTime()) / (60 * 1000);
        if (diff >= 15) {
          endMinutes = Math.min(24 * 60, startMinutes + diff);
        }
      }
    }
    return {
      id: event.id,
      startMinutes,
      endMinutes,
      event,
    };
  });
  return layoutTimelineEvents(inputs);
}
