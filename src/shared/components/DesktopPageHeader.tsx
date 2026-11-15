import React from 'react';
import { useNavigate } from 'react-router-dom';
import { EdumaIcon } from '../../core/icons/EdumaIcon';
import { AppCircleIconButton } from './AppCircleIconButton';

interface DesktopPageHeaderProps {
  title?: string;
  leading?: React.ReactNode;
  subtitle?: string;
  backTo?: string;
  onBack?: () => void;
  actions?: React.ReactNode;
  trailing?: React.ReactNode;
  badge?: React.ReactNode;
  sticky?: boolean;
  className?: string;
}

export function DesktopPageHeader({
  title,
  leading,
  subtitle,
  backTo,
  onBack,
  actions,
  trailing,
  badge,
  sticky = false,
  className = '',
}: DesktopPageHeaderProps) {
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

  const rightSlot = actions ?? trailing;

  return (
    <header
      className={`${
        sticky
          ? 'sticky top-0 z-20 bg-[var(--eduma-bg)]/86 backdrop-blur-xl'
          : 'bg-transparent'
      } border-b border-[var(--eduma-border-subtle)] px-8 pt-7 pb-5 ${className}`}
    >
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex min-w-0 items-center gap-3.5">
          {(onBack || backTo) ? (
            <AppCircleIconButton label="Go back" size={40} onClick={handleBack}>
              <EdumaIcon family="huge-stroke" name="arrowLeft01" size={18} />
            </AppCircleIconButton>
          ) : null}

          {leading ? (
            <div className="min-w-0">{leading}</div>
          ) : (
            <div className="min-w-0">
              <div className="flex items-center gap-2.5">
                <h1 className="truncate text-[28px] leading-[1.15] font-bold tracking-[-0.025em] text-[var(--eduma-text-primary)] sm:text-[32px]">
                  {title}
                </h1>
                {badge}
              </div>
              {subtitle ? (
                <p className="mt-1 text-[14.5px] font-medium text-[var(--eduma-text-secondary)]">
                  {subtitle}
                </p>
              ) : null}
            </div>
          )}
        </div>

        {rightSlot ? (
          <div className="flex shrink-0 flex-wrap items-center gap-[10px]">
            {rightSlot}
          </div>
        ) : null}
      </div>
    </header>
  );
}

export function DesktopPinnedPageHeader(props: DesktopPageHeaderProps) {
  return <DesktopPageHeader {...props} sticky />;
}

export type DesktopPillVariant = 'outlined' | 'filled' | 'tonal';

interface DesktopActionButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  label?: string;
  children?: React.ReactNode;
  icon?: React.ReactNode;
  variant?: DesktopPillVariant;
  filled?: boolean;
}

export function DesktopActionButton({
  label,
  children,
  icon,
  variant,
  filled = false,
  className = '',
  type = 'button',
  ...rest
}: DesktopActionButtonProps) {
  const effectiveVariant: DesktopPillVariant =
    variant ?? (filled ? 'filled' : 'outlined');

  const styleMap: Record<DesktopPillVariant, string> = {
    filled:
      'bg-[var(--eduma-primary)] text-[var(--eduma-on-primary)] border border-transparent shadow-xs hover:brightness-105',
    tonal:
      'bg-[var(--eduma-primary)]/12 text-[var(--eduma-primary)] border border-transparent hover:bg-[var(--eduma-primary)]/18',
    outlined:
      'bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)] border border-[var(--eduma-border)] hover:border-[var(--eduma-primary)]/40 hover:bg-[var(--eduma-card)]/40',
  };

  return (
    <button
      type={type}
      className={`inline-flex h-[42px] shrink-0 cursor-pointer items-center justify-center gap-2 rounded-full px-[18px] text-[14px] font-semibold transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50 ${styleMap[effectiveVariant]} ${className}`}
      {...rest}
    >
      {icon}
      <span>{label ?? children}</span>
    </button>
  );
}

export const DesktopPillButton = DesktopActionButton;
