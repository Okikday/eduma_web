export interface SegmentedOption<T extends string> {
  value: T;
  label: string;
  count?: number;
}

interface AppSegmentedControlProps<T extends string> {
  options: readonly SegmentedOption<T>[];
  value: T;
  onChange: (value: T) => void;
  fullWidth?: boolean;
  className?: string;
}

export function AppSegmentedControl<T extends string>({
  options,
  value,
  onChange,
  fullWidth = false,
  className = '',
}: AppSegmentedControlProps<T>) {
  return (
    <div
      role="tablist"
      className={`inline-flex items-center gap-1 rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-card)] p-1 ${
        fullWidth ? 'w-full' : ''
      } ${className}`}
    >
      {options.map((opt) => {
        const selected = opt.value === value;
        return (
          <button
            key={opt.value}
            type="button"
            role="tab"
            aria-selected={selected}
            onClick={() => onChange(opt.value)}
            className={`inline-flex cursor-pointer items-center justify-center gap-1.5 rounded-[10px] px-3 py-1.5 text-[13px] font-semibold transition ${
              fullWidth ? 'flex-1' : ''
            } ${
              selected
                ? 'bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)] shadow-xs'
                : 'text-[var(--eduma-text-muted)] hover:text-[var(--eduma-text-primary)]'
            }`}
          >
            <span>{opt.label}</span>
            {typeof opt.count === 'number' ? (
              <span className="rounded-full bg-[var(--eduma-nav-pill)] px-1.5 py-0.5 text-[11px] font-bold text-[var(--eduma-primary)]">
                {opt.count}
              </span>
            ) : null}
          </button>
        );
      })}
    </div>
  );
}
