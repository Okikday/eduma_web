import React from 'react';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppSegmentedControl } from '../../../shared/components/AppSegmentedControl';
import { DesktopActionButton } from '../../../shared/components/DesktopPageHeader';

interface SpaceDesktopToolbarProps {
  tab: 'pages' | 'assets' | 'events';
  onTabChange: (tab: 'pages' | 'assets' | 'events') => void;
  itemFilter: string;
  onFilterChange: (value: string) => void;
  onNewPage: () => void;
  onUploadAsset: (e: React.ChangeEvent<HTMLInputElement>) => void;
  onNewEvent: () => void;
}

export function SpaceDesktopToolbar({
  tab,
  onTabChange,
  itemFilter,
  onFilterChange,
  onNewPage,
  onUploadAsset,
  onNewEvent,
}: SpaceDesktopToolbarProps) {
  return (
    <div className="shrink-0 border-b-[0.5px] border-[var(--eduma-border)] bg-[var(--eduma-bg)] px-7 pb-3.5 pt-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <AppSegmentedControl<'pages' | 'assets' | 'events'>
          value={tab}
          onChange={onTabChange}
          options={[
            { value: 'pages', label: 'Pages' },
            { value: 'assets', label: 'Assets' },
            { value: 'events', label: 'Events' },
          ]}
        />

        <div className="flex min-w-0 flex-1 items-center justify-end gap-2.5">
          <div className="flex h-[38px] min-w-[180px] max-w-[260px] flex-1 items-center gap-2 rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 focus-within:border-[var(--eduma-primary)]">
            <EdumaIcon
              family="huge-stroke"
              name="search01"
              size={15}
              className="shrink-0 text-[var(--eduma-text-muted)]"
            />
            <input
              type="search"
              value={itemFilter}
              onChange={(e) => onFilterChange(e.target.value)}
              placeholder={`Filter ${tab}…`}
              aria-label={`Filter ${tab}`}
              className="w-full bg-transparent text-[13.5px] font-medium text-[var(--eduma-text-primary)] placeholder:text-[var(--eduma-text-muted)] focus:outline-none"
            />
          </div>

          {tab === 'pages' ? (
            <DesktopActionButton
              label="New page"
              variant="filled"
              icon={<EdumaIcon family="huge-stroke" name="add01" size={16} />}
              onClick={onNewPage}
            />
          ) : null}

          {tab === 'assets' ? (
            <label className="inline-flex h-[42px] cursor-pointer items-center gap-2 rounded-full bg-[var(--eduma-primary)] px-4 text-[13.5px] font-bold text-white shadow-sm transition hover:bg-[var(--eduma-primary-hover)]">
              <EdumaIcon family="huge-stroke" name="fileAdd" size={16} />
              <span>Upload asset</span>
              <input type="file" className="hidden" onChange={onUploadAsset} />
            </label>
          ) : null}

          {tab === 'events' ? (
            <DesktopActionButton
              label="New event"
              variant="filled"
              icon={<EdumaIcon family="huge-stroke" name="calendarAdd01" size={16} />}
              onClick={onNewEvent}
            />
          ) : null}
        </div>
      </div>
    </div>
  );
}
