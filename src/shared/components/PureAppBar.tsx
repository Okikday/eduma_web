import React from 'react';
import { useNavigate } from 'react-router-dom';
import { EdumaIcon } from '../../core/icons/EdumaIcon';
import { AppCircleIconButton } from './AppCircleIconButton';

interface PureAppBarProps {
  title: string;
  subtitle?: string;
  backTo?: string;
  onBack?: () => void;
  leading?: React.ReactNode;
  trailing?: React.ReactNode;
  sticky?: boolean;
}

export function PureAppBar({
  title,
  subtitle,
  backTo,
  onBack,
  leading,
  trailing,
  sticky = true,
}: PureAppBarProps) {
  const navigate = useNavigate();

  const handleBack = () => {
    if (onBack) {
      onBack();
      return;
    }
    if (backTo) {
      navigate(backTo);
      return;
    }
    navigate(-1);
  };

  return (
    <header
      className={`${
        sticky ? 'sticky top-0 z-30' : ''
      } eduma-glass flex min-h-[60px] items-center justify-between gap-3 border-b border-[var(--eduma-border)] px-4 py-2.5`}
    >
      <div className="flex min-w-0 items-center gap-3">
        {leading ??
          (onBack || backTo ? (
            <AppCircleIconButton label="Go back" size={36} onClick={handleBack}>
              <EdumaIcon family="huge-stroke" name="arrowLeft01" size={18} />
            </AppCircleIconButton>
          ) : null)}
        <div className="min-w-0">
          <h1 className="type-title-lg truncate text-[var(--eduma-text-primary)]">
            {title}
          </h1>
          {subtitle ? (
            <p className="type-body-sm truncate text-[var(--eduma-text-muted)]">
              {subtitle}
            </p>
          ) : null}
        </div>
      </div>

      {trailing ? <div className="flex shrink-0 items-center gap-2">{trailing}</div> : null}
    </header>
  );
}
