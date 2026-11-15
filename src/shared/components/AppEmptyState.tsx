import React from 'react';
import { EdumaIcon } from '../../core/icons/EdumaIcon';

interface AppEmptyStateProps {
  iconFamily?: 'iconsax' | 'huge-stroke' | 'huge-solid';
  iconName?: string;
  title: string;
  description?: string;
  action?: React.ReactNode;
  compact?: boolean;
}

export function AppEmptyState({
  iconFamily = 'huge-stroke',
  iconName = 'folder01',
  title,
  description,
  action,
  compact = false,
}: AppEmptyStateProps) {
  return (
    <div
      className={`flex flex-col items-center justify-center rounded-[20px] border border-dashed border-[var(--eduma-border)] bg-[var(--eduma-surface)]/70 text-center ${
        compact ? 'px-5 py-7' : 'px-6 py-12'
      }`}
    >
      <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]">
        <EdumaIcon family={iconFamily} name={iconName} size={24} />
      </div>
      <p className="type-title-md text-[var(--eduma-text-primary)]">{title}</p>
      {description ? (
        <p className="type-body-sm mt-1 max-w-sm text-[var(--eduma-text-muted)]">
          {description}
        </p>
      ) : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}
