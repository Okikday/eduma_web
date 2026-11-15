import React from 'react';
import { normalizeApiUrl } from '../../core/config/appConfig';
import { EdumaIcon } from '../../core/icons/EdumaIcon';
import { AdaptiveImage } from './AdaptiveImage';
import { EdumaCoverFallback } from './EdumaCoverFallback';

interface DesktopSplitScaffoldProps {
  hero: React.ReactNode;
  children?: React.ReactNode;
  body?: React.ReactNode;
  heroFraction?: number;
  minBodyWidth?: number;
}

export function DesktopSplitScaffold({
  hero,
  children,
  body,
  heroFraction = 0.5,
  minBodyWidth = 460,
}: DesktopSplitScaffoldProps) {
  const pct = Math.max(0, Math.min(1, heroFraction)) * 100;
  return (
    <div className="flex h-screen w-full overflow-hidden bg-[var(--eduma-bg)]">
      <div
        className="relative h-full shrink-0 overflow-hidden"
        style={{
          width: `clamp(0px, ${pct}%, calc(100% - ${minBodyWidth}px))`,
        }}
      >
        {hero}
      </div>
      <div className="h-full min-w-0 flex-1 overflow-y-auto bg-[var(--eduma-bg)]">
        {body ?? children}
      </div>
    </div>
  );
}

interface DesktopHeroButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  children: React.ReactNode;
}

export function DesktopHeroButton({
  label,
  children,
  className = '',
  type = 'button',
  ...rest
}: DesktopHeroButtonProps) {
  return (
    <button
      type={type}
      aria-label={label}
      title={label}
      className={`inline-flex h-[42px] w-[42px] shrink-0 cursor-pointer items-center justify-center rounded-full border border-white/18 bg-black/30 text-white backdrop-blur-md transition hover:bg-black/45 active:scale-95 ${className}`}
      {...rest}
    >
      {children}
    </button>
  );
}

interface DesktopHeroActionButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  icon?: React.ReactNode;
  label: string;
  isPrimary?: boolean;
}

export function DesktopHeroActionButton({
  icon,
  label,
  isPrimary = false,
  className = '',
  type = 'button',
  ...rest
}: DesktopHeroActionButtonProps) {
  return (
    <button
      type={type}
      className={`inline-flex h-[42px] cursor-pointer items-center justify-center gap-2 rounded-full px-[18px] text-[14px] font-semibold transition active:scale-[0.98] ${
        isPrimary
          ? 'bg-white text-[#1C1760] shadow-sm hover:bg-white/92'
          : 'border border-white/22 bg-white/14 text-white backdrop-blur-md hover:bg-white/22'
      } ${className}`}
      {...rest}
    >
      {icon}
      <span>{label}</span>
    </button>
  );
}

interface DesktopHeroPaneProps {
  background?: React.ReactNode;
  leading?: React.ReactNode;
  trailing?: React.ReactNode;
  content?: React.ReactNode;
  // Convenience props for simple callers
  title?: string;
  subtitle?: string;
  eyebrow?: string;
  coverUrl?: string | null;
  seed?: string;
  onBack?: () => void;
  badges?: React.ReactNode;
  stats?: React.ReactNode;
  actions?: React.ReactNode;
  children?: React.ReactNode;
}

export function DesktopHeroPane({
  background,
  leading,
  trailing,
  content,
  title,
  subtitle,
  eyebrow,
  coverUrl,
  seed = 'eduma',
  onBack,
  badges,
  stats,
  actions,
  children,
}: DesktopHeroPaneProps) {
  const defaultBackground = background ?? (
    <AdaptiveImage
      src={coverUrl ? normalizeApiUrl(coverUrl) : null}
      alt={title || 'Eduma'}
      className="h-full w-full object-cover"
      fallback={<EdumaCoverFallback seed={seed} label={title || seed} />}
    />
  );

  const defaultLeading =
    leading ??
    (onBack ? (
      <DesktopHeroButton label="Go back" onClick={onBack}>
        <EdumaIcon family="huge-stroke" name="arrowLeft01" size={18} />
      </DesktopHeroButton>
    ) : null);

  const defaultContent =
    content ??
    children ??
    (title ? (
      <div className="max-w-[520px]">
        {eyebrow ? (
          <p className="mb-2 text-[12px] font-bold uppercase tracking-wider text-white/80">
            {eyebrow}
          </p>
        ) : null}
        <div className="flex flex-wrap items-center gap-2.5">
          <h1 className="text-[36px] leading-[1.1] font-bold tracking-[-0.025em] text-white sm:text-[39px]">
            {title}
          </h1>
          {badges}
        </div>
        {subtitle ? (
          <p className="mt-2.5 line-clamp-3 text-[15.5px] leading-[1.45] text-white/80">
            {subtitle}
          </p>
        ) : null}
        {stats ? <div className="mt-5 flex flex-wrap gap-2">{stats}</div> : null}
        {actions ? (
          <div className="mt-6 flex flex-wrap items-center gap-2.5">{actions}</div>
        ) : null}
      </div>
    ) : null);

  return (
    <div className="relative h-full w-full overflow-hidden">
      {/* Layer 1: Full-bleed background */}
      <div className="absolute inset-0 h-full w-full">{defaultBackground}</div>

      {/* Layer 2: Bottom readability scrim */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            'linear-gradient(to top, color-mix(in srgb, var(--eduma-hero-scrim) 74%, transparent) 0%, color-mix(in srgb, var(--eduma-hero-scrim) 22%, transparent) 48%, transparent 100%)',
        }}
      />

      {/* Layer 3: Top bar contrast scrim (120px) */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-x-0 top-0 h-[120px]"
        style={{
          background:
            'linear-gradient(to bottom, color-mix(in srgb, var(--eduma-hero-scrim) 36%, transparent) 0%, transparent 100%)',
        }}
      />

      {/* Layer 4: Right-edge 34% width 6-stop fade into scaffold background */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-y-0 right-0 w-[34%]"
        style={{
          background:
            'linear-gradient(to right, color-mix(in srgb, var(--eduma-bg) 0%, transparent) 0%, color-mix(in srgb, var(--eduma-bg) 4%, transparent) 20%, color-mix(in srgb, var(--eduma-bg) 16%, transparent) 40%, color-mix(in srgb, var(--eduma-bg) 42%, transparent) 60%, color-mix(in srgb, var(--eduma-bg) 78%, transparent) 80%, var(--eduma-bg) 100%)',
        }}
      />

      {/* Top-left action */}
      {defaultLeading ? (
        <div className="absolute top-[20px] left-[20px] z-10">{defaultLeading}</div>
      ) : null}

      {/* Top-right actions (pulled inward from the right fade) */}
      {trailing ? (
        <div className="absolute top-[20px] right-[88px] z-10 flex items-center gap-[10px]">
          {trailing}
        </div>
      ) : null}

      {/* Bottom-left identity & action stack */}
      {defaultContent ? (
        <div className="absolute inset-x-0 bottom-0 z-10 pt-0 pr-[72px] pb-[40px] pl-[40px]">
          {defaultContent}
        </div>
      ) : null}
    </div>
  );
}

interface ReadableWidthProps {
  children: React.ReactNode;
  maxWidth?: number;
  showEdges?: boolean;
  className?: string;
}

export function ReadableWidth({
  children,
  maxWidth = 840,
  showEdges = false,
  className = '',
}: ReadableWidthProps) {
  return (
    <div
      className={`mx-auto w-full ${
        showEdges
          ? 'min-h-full border-x border-[var(--eduma-border-subtle)]/70'
          : ''
      } ${className}`}
      style={{ maxWidth: `${maxWidth}px` }}
    >
      {children}
    </div>
  );
}
