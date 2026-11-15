import React from 'react';

interface AppCircleIconButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  size?: number;
  badgeCount?: number;
  active?: boolean;
  children: React.ReactNode;
}

export function AppCircleIconButton({
  label,
  size = 40,
  badgeCount,
  active = false,
  children,
  className = '',
  type = 'button',
  ...rest
}: AppCircleIconButtonProps) {
  return (
    <button
      type={type}
      aria-label={label}
      title={label}
      className={`relative inline-flex shrink-0 cursor-pointer items-center justify-center rounded-full border transition active:scale-95 ${
        active
          ? 'border-[var(--eduma-primary)] bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]'
          : 'border-[var(--eduma-border)] bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)] hover:bg-[var(--eduma-card)]'
      } ${className}`}
      style={{ width: `${size}px`, height: `${size}px` }}
      {...rest}
    >
      {children}
      {typeof badgeCount === 'number' && badgeCount > 0 ? (
        <span className="absolute -top-1 -right-1 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-[var(--eduma-error)] px-1 text-[10px] font-bold text-white">
          {badgeCount > 99 ? '99+' : badgeCount}
        </span>
      ) : null}
    </button>
  );
}
