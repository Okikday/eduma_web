import React from 'react';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppSegmentedControl } from '../../../shared/components/AppSegmentedControl';
import { ReadableWidth } from '../../../shared/components/DesktopSplitScaffold';

interface ProfileDesktopPanelProps {
  desktopTab: 'profile' | 'settings';
  onTabChange: (tab: 'profile' | 'settings') => void;
  settingsQuery: string;
  onSettingsQueryChange: (q: string) => void;
  profileContent: React.ReactNode;
  settingsContent: React.ReactNode;
}

export function ProfileDesktopPanel({
  desktopTab,
  onTabChange,
  settingsQuery,
  onSettingsQueryChange,
  profileContent,
  settingsContent,
}: ProfileDesktopPanelProps) {
  return (
    <ReadableWidth maxWidth={640} className="pb-12">
      <div className="sticky top-0 z-20 mb-5 border-b border-[var(--eduma-border)] bg-[var(--eduma-bg)]/92 pb-4 pt-6 backdrop-blur-md">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h1 className="text-[24px] font-bold tracking-[-0.02em] text-[var(--eduma-text-primary)]">
            Profile &amp; Settings
          </h1>
          <AppSegmentedControl<'profile' | 'settings'>
            value={desktopTab}
            onChange={onTabChange}
            options={[
              { value: 'profile', label: 'Profile' },
              { value: 'settings', label: 'Settings' },
            ]}
          />
        </div>

        {desktopTab === 'settings' ? (
          <div className="mt-3 flex h-[40px] items-center gap-2.5 rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 focus-within:border-[var(--eduma-primary)]">
            <EdumaIcon
              family="huge-stroke"
              name="search01"
              size={16}
              className="shrink-0 text-[var(--eduma-text-muted)]"
            />
            <input
              type="search"
              value={settingsQuery}
              onChange={(e) => onSettingsQueryChange(e.target.value)}
              placeholder="Filter settings (theme, font, memory, billing, legal…)"
              aria-label="Filter settings"
              className="w-full bg-transparent text-[13.5px] font-medium text-[var(--eduma-text-primary)] placeholder:text-[var(--eduma-text-muted)] focus:outline-none"
            />
          </div>
        ) : null}
      </div>

      {desktopTab === 'profile' ? profileContent : settingsContent}
    </ReadableWidth>
  );
}
