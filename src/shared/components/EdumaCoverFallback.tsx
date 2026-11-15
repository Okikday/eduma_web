import { pickAccentForId } from '../../core/utils/accentHash';

interface EdumaCoverFallbackProps {
  seed: string;
  label?: string;
  className?: string;
  compact?: boolean;
}

export function EdumaCoverFallback({
  seed,
  label,
  className = '',
  compact = false,
}: EdumaCoverFallbackProps) {
  const accent = pickAccentForId(seed);
  const displayChar = (label || seed || 'E').trim().charAt(0).toUpperCase() || 'E';

  return (
    <div
      className={`relative flex h-full w-full items-center justify-center overflow-hidden select-none ${className}`}
      style={{
        background: `linear-gradient(135deg, ${accent.cssVar} 0%, var(--space-circle-deep) 100%)`,
      }}
    >
      <img
        src="/assets/images/dust_pattern.webp"
        alt=""
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-20 mix-blend-screen"
      />
      <span
        className={`relative font-bold tracking-tight text-white/90 ${
          compact ? 'text-base' : 'text-3xl'
        }`}
      >
        {displayChar}
      </span>
    </div>
  );
}
