export function getGreetingForHour(hour: number): string {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

export function formatRelativeTime(input?: string | Date | null): string {
  if (!input) return '';
  const date = input instanceof Date ? input : new Date(input);
  if (Number.isNaN(date.getTime())) return '';

  const diffMs = Date.now() - date.getTime();
  const absSec = Math.floor(Math.abs(diffMs) / 1000);
  if (absSec < 45) return 'Just now';

  const mins = Math.floor(absSec / 60);
  if (mins < 60) return `${mins}m ago`;

  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;

  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;

  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: date.getFullYear() !== new Date().getFullYear() ? 'numeric' : undefined,
  });
}

export function formatTimeRange(startIso: string, endIso?: string | null): string {
  const start = new Date(startIso);
  if (Number.isNaN(start.getTime())) return '';
  const startStr = start.toLocaleTimeString(undefined, {
    hour: 'numeric',
    minute: '2-digit',
  });
  if (!endIso) return startStr;
  const end = new Date(endIso);
  if (Number.isNaN(end.getTime())) return startStr;
  const endStr = end.toLocaleTimeString(undefined, {
    hour: 'numeric',
    minute: '2-digit',
  });
  return `${startStr} – ${endStr}`;
}

export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

export function toDateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export interface MonthCell {
  date: Date;
  key: string;
  inCurrentMonth: boolean;
  isToday: boolean;
}

/**
 * Generates a fixed 42-cell (6 rows x 7 cols, Sunday-first) month matrix matching
 * `CalendarDesktopView` and `MiniCalendarHeader` in `../eduma`.
 */
export function buildSundayFirstMonthGrid(year: number, monthIndex: number): MonthCell[] {
  const firstOfMonth = new Date(year, monthIndex, 1);
  const startOffset = firstOfMonth.getDay(); // 0 (Sun) .. 6 (Sat)
  const startDate = new Date(year, monthIndex, 1 - startOffset);
  const today = new Date();
  const cells: MonthCell[] = [];

  for (let i = 0; i < 42; i += 1) {
    const cellDate = new Date(
      startDate.getFullYear(),
      startDate.getMonth(),
      startDate.getDate() + i
    );
    cells.push({
      date: cellDate,
      key: toDateKey(cellDate),
      inCurrentMonth: cellDate.getMonth() === monthIndex,
      isToday: isSameDay(cellDate, today),
    });
  }

  return cells;
}

export interface TimelineItemInput {
  id: string;
  startMinutes: number;
  endMinutes: number;
}

export interface PositionedTimelineItem<T extends TimelineItemInput> {
  item: T;
  column: number;
  columnCount: number;
  topPercent: number;
  heightPercent: number;
}

/**
 * Computes non-overlapping horizontal columns for concurrent events within a 24h day.
 */
export function layoutTimelineEvents<T extends TimelineItemInput>(
  items: readonly T[]
): PositionedTimelineItem<T>[] {
  if (items.length === 0) return [];
  const sorted = [...items].sort((a, b) =>
    a.startMinutes !== b.startMinutes
      ? a.startMinutes - b.startMinutes
      : b.endMinutes - a.endMinutes
  );

  // Group into connected overlap clusters.
  const clusters: T[][] = [];
  let currentCluster: T[] = [];
  let clusterEnd = -1;

  for (const item of sorted) {
    const safeEnd = Math.max(item.startMinutes + 30, item.endMinutes);
    if (currentCluster.length === 0 || item.startMinutes < clusterEnd) {
      currentCluster.push(item);
      clusterEnd = Math.max(clusterEnd, safeEnd);
    } else {
      clusters.push(currentCluster);
      currentCluster = [item];
      clusterEnd = safeEnd;
    }
  }
  if (currentCluster.length > 0) {
    clusters.push(currentCluster);
  }

  const results: PositionedTimelineItem<T>[] = [];
  const minutesInDay = 24 * 60;

  for (const cluster of clusters) {
    const colEnds: number[] = [];
    const assigned: { item: T; col: number }[] = [];

    for (const item of cluster) {
      const safeEnd = Math.max(item.startMinutes + 30, item.endMinutes);
      let placedCol = -1;
      for (let c = 0; c < colEnds.length; c += 1) {
        if (colEnds[c] <= item.startMinutes) {
          placedCol = c;
          colEnds[c] = safeEnd;
          break;
        }
      }
      if (placedCol === -1) {
        placedCol = colEnds.length;
        colEnds.push(safeEnd);
      }
      assigned.push({ item, col: placedCol });
    }

    const totalCols = Math.max(1, colEnds.length);
    for (const { item, col } of assigned) {
      const clampedStart = Math.max(0, Math.min(minutesInDay - 15, item.startMinutes));
      const clampedEnd = Math.max(clampedStart + 30, Math.min(minutesInDay, item.endMinutes));
      results.push({
        item,
        column: col,
        columnCount: totalCols,
        topPercent: (clampedStart / minutesInDay) * 100,
        heightPercent: ((clampedEnd - clampedStart) / minutesInDay) * 100,
      });
    }
  }

  return results;
}
