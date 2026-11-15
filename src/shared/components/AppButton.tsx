import React from 'react';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
type ButtonSize = 'sm' | 'md' | 'lg';

interface AppButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  fullWidth?: boolean;
  leadingIcon?: React.ReactNode;
}

const VARIANT_CLASSES: Record<ButtonVariant, string> = {
  primary:
    'bg-[var(--eduma-primary)] text-[var(--eduma-on-primary)] hover:bg-[var(--eduma-primary-hover)] shadow-sm',
  secondary:
    'bg-[var(--eduma-card)] text-[var(--eduma-text-primary)] border border-[var(--eduma-border)] hover:brightness-95',
  ghost:
    'bg-transparent text-[var(--eduma-text-secondary)] hover:bg-[var(--eduma-card)]/70',
  danger:
    'bg-[var(--eduma-error)] text-white hover:brightness-95 shadow-sm',
};

const SIZE_CLASSES: Record<ButtonSize, string> = {
  sm: 'h-9 px-3.5 text-[13px] rounded-[11px]',
  md: 'h-11 px-4.5 text-[14px] rounded-[13px]',
  lg: 'h-12 px-5 text-[15px] rounded-[14px]',
};

export function AppButton({
  variant = 'primary',
  size = 'md',
  loading = false,
  fullWidth = false,
  leadingIcon,
  disabled,
  children,
  className = '',
  type = 'button',
  ...rest
}: AppButtonProps) {
  return (
    <button
      type={type}
      disabled={disabled || loading}
      className={`inline-flex cursor-pointer items-center justify-center gap-2 font-semibold transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-55 ${
        VARIANT_CLASSES[variant]
      } ${SIZE_CLASSES[size]} ${fullWidth ? 'w-full' : ''} ${className}`}
      {...rest}
    >
      {loading ? (
        <span
          className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
          aria-hidden="true"
        />
      ) : (
        leadingIcon
      )}
      <span>{children}</span>
    </button>
  );
}
