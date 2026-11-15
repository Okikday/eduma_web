import { useId } from 'react';

interface AppOtpFieldProps {
  value: string;
  onChange: (value: string) => void;
  label?: string;
  hint?: string;
  disabled?: boolean;
  autoFocus?: boolean;
  onComplete?: (code: string) => void;
}

/**
 * Single-input 6-digit verification code field using `autocomplete="one-time-code"`
 * and `inputMode="numeric"` (never split across 6 inputs or `type="number"`).
 */
export function AppOtpField({
  value,
  onChange,
  label = 'Verification code',
  hint = 'Enter the 6-digit code sent to your email address.',
  disabled = false,
  autoFocus = true,
  onComplete,
}: AppOtpFieldProps) {
  const inputId = useId();
  const hintId = useId();

  return (
    <div className="flex flex-col gap-1.5">
      <label
        htmlFor={inputId}
        className="type-label-md text-[var(--eduma-text-secondary)]"
      >
        {label}
      </label>
      <p id={hintId} className="type-body-sm text-[var(--eduma-text-muted)]">
        {hint}
      </p>
      <input
        id={inputId}
        name="otp"
        type="text"
        inputMode="numeric"
        autoComplete="one-time-code"
        pattern="\d{6}"
        maxLength={6}
        required
        disabled={disabled}
        autoFocus={autoFocus}
        aria-describedby={hintId}
        placeholder="000000"
        value={value}
        onChange={(e) => {
          const digits = e.target.value.replace(/\D/g, '').slice(0, 6);
          onChange(digits);
          if (digits.length === 6 && onComplete) {
            onComplete(digits);
          }
        }}
        className="h-14 w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-4 text-center font-mono text-[1.35rem] font-bold tracking-[0.42em] text-[var(--eduma-text-primary)] outline-none transition focus:border-[var(--eduma-primary)] focus:ring-2 focus:ring-[var(--eduma-primary)]/20"
      />
    </div>
  );
}
