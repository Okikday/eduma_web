import React, { useEffect, useState } from 'react';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { toDateKey } from '../../../core/utils/dateFormatters';
import { AppButton } from '../../../shared/components/AppButton';
import { AppModalDialog } from '../../../shared/components/AppModalDialog';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useToast } from '../../../shared/components/AppToast';
import { spacesApi } from '../../spaces/data/spacesApi';
import type { Space } from '../../spaces/models/spaceModels';
import { eventsApi } from '../data/eventsApi';
import {
  EVENT_CATEGORY_META,
  type CalendarEvent,
  type EventCategory,
} from '../models/calendarModels';

interface CreateEventDialogProps {
  open: boolean;
  onClose: () => void;
  defaultDate?: Date;
  defaultSpaceId?: string;
  editingEvent?: CalendarEvent | null;
  onSaved?: () => void;
}

export function CreateEventDialog({
  open,
  onClose,
  defaultDate = new Date(),
  defaultSpaceId = '',
  editingEvent = null,
  onSaved,
}: CreateEventDialogProps) {
  const { showToast } = useToast();
  const [spaces, setSpaces] = useState<Space[]>([]);
  const [title, setTitle] = useState('');
  const [category, setCategory] = useState<EventCategory>('study');
  const [dateStr, setDateStr] = useState(() => toDateKey(defaultDate));
  const [startTimeStr, setStartTimeStr] = useState('09:00');
  const [endTimeStr, setEndTimeStr] = useState('10:00');
  const [spaceId, setSpaceId] = useState(defaultSpaceId);
  const [description, setDescription] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!open) return;
    spacesApi.listSpaces().then(setSpaces).catch(() => null);
    if (editingEvent) {
      setTitle(editingEvent.title);
      setCategory(editingEvent.category);
      const start = new Date(editingEvent.startTime);
      setDateStr(toDateKey(start));
      setStartTimeStr(
        `${String(start.getHours()).padStart(2, '0')}:${String(
          start.getMinutes()
        ).padStart(2, '0')}`
      );
      if (editingEvent.endTime) {
        const end = new Date(editingEvent.endTime);
        setEndTimeStr(
          `${String(end.getHours()).padStart(2, '0')}:${String(
            end.getMinutes()
          ).padStart(2, '0')}`
        );
      }
      setSpaceId(editingEvent.spaceId || '');
      setDescription(editingEvent.description || '');
    } else {
      setTitle('');
      setCategory('study');
      setDateStr(toDateKey(defaultDate));
      setStartTimeStr('09:00');
      setEndTimeStr('10:00');
      setSpaceId(defaultSpaceId);
      setDescription('');
    }
  }, [open, editingEvent, defaultDate, defaultSpaceId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    try {
      const startIso = new Date(`${dateStr}T${startTimeStr}:00`).toISOString();
      const endIso = new Date(`${dateStr}T${endTimeStr}:00`).toISOString();

      if (editingEvent) {
        await eventsApi.updateEvent(editingEvent.id, {
          title: title.trim(),
          category,
          startTime: startIso,
          endTime: endIso,
          spaceId: spaceId || undefined,
          description: description.trim() || undefined,
        });
        showToast('Event updated.', 'success');
      } else {
        await eventsApi.createEvent({
          title: title.trim(),
          category,
          startTime: startIso,
          endTime: endIso,
          spaceId: spaceId || undefined,
          description: description.trim() || undefined,
        });
        showToast('Event scheduled.', 'success');
      }
      AppSyncBus.emit('events:changed');
      onClose();
      onSaved?.();
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to save event.',
        'error'
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <AppModalDialog
      open={open}
      onClose={onClose}
      title={editingEvent ? 'Edit event' : 'Schedule study event'}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        <AppTextFormField
          label="Event title"
          placeholder="e.g. Linear Algebra Review"
          autoFocus
          required
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />

        <div className="flex flex-col gap-1.5">
          <span className="type-label-md text-[var(--eduma-text-secondary)]">
            Category
          </span>
          <div className="flex flex-wrap gap-1.5">
            {(Object.keys(EVENT_CATEGORY_META) as EventCategory[]).map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => setCategory(cat)}
                className={`cursor-pointer rounded-full border px-3 py-1 text-[12.5px] font-semibold transition ${
                  category === cat
                    ? 'border-[var(--eduma-primary)] bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]'
                    : 'border-[var(--eduma-border)] bg-[var(--eduma-surface)] text-[var(--eduma-text-secondary)]'
                }`}
              >
                {EVENT_CATEGORY_META[cat].label}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <AppTextFormField
            label="Date"
            type="date"
            required
            value={dateStr}
            onChange={(e) => setDateStr(e.target.value)}
          />
          <AppTextFormField
            label="Starts"
            type="time"
            required
            value={startTimeStr}
            onChange={(e) => setStartTimeStr(e.target.value)}
          />
          <AppTextFormField
            label="Ends"
            type="time"
            required
            value={endTimeStr}
            onChange={(e) => setEndTimeStr(e.target.value)}
          />
        </div>

        <div className="flex flex-col gap-1.5">
          <label
            htmlFor="event-space-select"
            className="type-label-md text-[var(--eduma-text-secondary)]"
          >
            Linked Study Space (optional)
          </label>
          <select
            id="event-space-select"
            value={spaceId}
            onChange={(e) => setSpaceId(e.target.value)}
            className="h-12 rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 text-[14.5px] font-medium text-[var(--eduma-text-primary)] outline-none focus:border-[var(--eduma-primary)]"
          >
            <option value="">No linked space</option>
            {spaces.map((s) => (
              <option key={s.id} value={s.id}>
                {s.title}
              </option>
            ))}
          </select>
        </div>

        <div className="flex flex-col gap-1.5">
          <label
            htmlFor="event-notes"
            className="type-label-md text-[var(--eduma-text-secondary)]"
          >
            Notes (optional)
          </label>
          <textarea
            id="event-notes"
            rows={2}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 py-2.5 text-[14px]"
          />
        </div>

        <div className="mt-2 flex justify-end gap-2">
          <AppButton variant="ghost" onClick={onClose}>
            Cancel
          </AppButton>
          <AppButton type="submit" loading={saving} disabled={!title.trim()}>
            {editingEvent ? 'Save changes' : 'Save event'}
          </AppButton>
        </div>
      </form>
    </AppModalDialog>
  );
}
