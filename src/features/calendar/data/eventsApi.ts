import { apiClient } from '../../../core/api/apiClient';
import { normalizeEventCategory } from '../logic/calendarLogic';
import type { CalendarEvent, EventCategory } from '../models/calendarModels';

function mapEvent(raw: Record<string, unknown>): CalendarEvent {
  const ev =
    raw.event && typeof raw.event === 'object'
      ? (raw.event as Record<string, unknown>)
      : raw;
  const space =
    ev.space && typeof ev.space === 'object'
      ? (ev.space as Record<string, unknown>)
      : null;

  return {
    id: String(ev.id || ev._id || ''),
    title: String(ev.title || 'Study Event'),
    description: typeof ev.description === 'string' ? ev.description : null,
    category: normalizeEventCategory(
      typeof ev.category === 'string' ? ev.category : null
    ),
    startTime: String(ev.startTime || ev.start || ev.date || new Date().toISOString()),
    endTime:
      typeof ev.endTime === 'string'
        ? ev.endTime
        : typeof ev.end === 'string'
        ? ev.end
        : null,
    allDay: Boolean(ev.allDay ?? false),
    spaceId: typeof ev.spaceId === 'string' ? ev.spaceId : typeof space?.id === 'string' ? space.id : null,
    spaceTitle: typeof space?.title === 'string' ? space.title : null,
    pageId: typeof ev.pageId === 'string' ? ev.pageId : null,
    location: typeof ev.location === 'string' ? ev.location : null,
    createdAt: typeof ev.createdAt === 'string' ? ev.createdAt : null,
  };
}

export const eventsApi = {
  async listEvents(params: {
    from?: string;
    to?: string;
    spaceId?: string;
    category?: EventCategory;
    limit?: number;
  } = {}): Promise<CalendarEvent[]> {
    const res = await apiClient.get<unknown>('/events', {
      params: {
        from: params.from,
        to: params.to,
        spaceId: params.spaceId,
        category: params.category,
        limit: Math.min(200, params.limit ?? 150),
      },
    });

    const list = Array.isArray(res)
      ? res
      : res && typeof res === 'object'
      ? ((res as Record<string, unknown>).events ??
          (res as Record<string, unknown>).items ??
          [])
      : [];

    return Array.isArray(list)
      ? (list as Record<string, unknown>[]).map(mapEvent)
      : [];
  },

  async createEvent(input: {
    title: string;
    description?: string;
    category: EventCategory;
    startTime: string;
    endTime?: string;
    spaceId?: string;
    location?: string;
  }): Promise<CalendarEvent> {
    const res = await apiClient.post<Record<string, unknown>>('/events', input);
    return mapEvent(res);
  },

  async updateEvent(
    eventId: string,
    input: Partial<{
      title: string;
      description: string;
      category: EventCategory;
      startTime: string;
      endTime: string;
      spaceId: string;
      location: string;
    }>
  ): Promise<CalendarEvent> {
    const res = await apiClient.patch<Record<string, unknown>>(
      `/events/${encodeURIComponent(eventId)}`,
      input
    );
    return mapEvent(res);
  },

  async deleteEvent(eventId: string): Promise<void> {
    await apiClient.delete(`/events/${encodeURIComponent(eventId)}`);
  },
};
