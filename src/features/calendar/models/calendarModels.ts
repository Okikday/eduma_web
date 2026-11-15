export type EventCategory = 'study' | 'lecture' | 'exam' | 'deadline' | 'other';

export interface CalendarEvent {
  id: string;
  title: string;
  description?: string | null;
  category: EventCategory;
  startTime: string;
  endTime?: string | null;
  allDay?: boolean;
  spaceId?: string | null;
  spaceTitle?: string | null;
  pageId?: string | null;
  location?: string | null;
  createdAt?: string | null;
}

export const EVENT_CATEGORY_META: Record<
  EventCategory,
  { label: string; colorVar: string }
> = {
  study: { label: 'Study Session', colorVar: 'var(--accent-violet)' },
  lecture: { label: 'Lecture', colorVar: 'var(--accent-sky)' },
  exam: { label: 'Exam', colorVar: 'var(--accent-rose)' },
  deadline: { label: 'Deadline', colorVar: 'var(--accent-amber)' },
  other: { label: 'Other', colorVar: 'var(--accent-teal)' },
};
