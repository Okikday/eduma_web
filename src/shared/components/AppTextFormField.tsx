import React, { useId, useState } from 'react';
import { EdumaIcon } from '../../core/icons/EdumaIcon';

interface AppTextFormFieldProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'id'> {
  label: string;
  id?: string;
  hint?: string;
  error?: string | null;
  leadingIcon?: React.ReactNode;
  trailingElement?: React.ReactNode;
  showPasswordToggle?: boolean;
}

export function AppTextFormField({
  label,
  id,
  hint,
  error,
  leadingIcon,
  trailingElement,
  showPasswordToggle = false,
  type = 'text',
  className = '',
  ...rest
}: AppTextFormFieldProps) {
  const generatedId = useId();
  const fieldId = id || generatedId;
  const errorId = `${fieldId}-error`;
  const [revealPassword, setRevealPassword] = useState(false);

  const effectiveType =
    showPasswordToggle && type === 'password'
      ? revealPassword
        ? 'text'
        : 'password'
      : type;

  return (
    <div className="flex flex-col gap-1.5">
      <label
        htmlFor={fieldId}
        className="type-label-md text-[var(--eduma-text-secondary)]"
      >
        {label}
      </label>

      <div
        className={`flex min-h-[48px] items-center gap-2.5 rounded-[14px] border bg-[var(--eduma-surface)] px-3.5 transition focus-within:ring-2 ${
          error
            ? 'border-[var(--eduma-error)] focus-within:border-[var(--eduma-error)] focus-within:ring-[var(--eduma-error)]/20'
            : 'border-[var(--eduma-border)] focus-within:border-[var(--eduma-primary)] focus-within:ring-[var(--eduma-primary)]/20'
        }`}
      >
        {leadingIcon ? (
          <span className="shrink-0 text-[var(--eduma-text-muted)]">
            {leadingIcon}
          </span>
        ) : null}

        <input
          id={fieldId}
          type={effectiveType}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? errorId : undefined}
          className={`w-full bg-transparent py-2.5 text-[15px] font-medium text-[var(--eduma-text-primary)] placeholder:text-[var(--eduma-text-muted)] focus:outline-none ${className}`}
          {...rest}
        />

        {showPasswordToggle && type === 'password' ? (
          <button
            type="button"
            onClick={() => setRevealPassword((prev) => !prev)}
            aria-label={revealPassword ? 'Hide password' : 'Show password'}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-[var(--eduma-text-muted)] transition hover:bg-[var(--eduma-card)] hover:text-[var(--eduma-text-primary)]"
          >
            <EdumaIcon
              family="huge-stroke"
              name={revealPassword ? 'viewOffSlash' : 'view'}
              size={18}
            />
          </button>
        ) : null}

        {trailingElement}
      </div>

      {error ? (
        <p id={errorId} className="type-body-sm text-[var(--eduma-error)]">
          {error}
        </p>
      ) : hint ? (
        <p className="type-body-sm text-[var(--eduma-text-muted)]">{hint}</p>
      ) : null}
    </div>
  );
}
