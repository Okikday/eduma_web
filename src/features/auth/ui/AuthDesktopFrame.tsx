import React from 'react';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';

interface AuthDesktopFrameProps {
  children: React.ReactNode;
  maxBodyHeight?: number;
}

const BRAND_FEATURES = [
  {
    icon: 'book_1_copy',
    title: 'Curated notebooks',
    subtitle: 'Write, sketch and organize pages that stay in sync.',
  },
  {
    icon: 'people_copy',
    title: 'Interactive spaces',
    subtitle: 'Share notes, files and events with your study group.',
  },
  {
    icon: 'calendar_1_copy',
    title: 'Smart scheduling',
    subtitle: 'Keep deadlines, sessions and daily streaks on track.',
  },
] as const;

export function AuthDesktopFrame({
  children,
  maxBodyHeight,
}: AuthDesktopFrameProps) {
  return (
    <div className="min-h-screen w-full bg-[var(--eduma-bg)] lg:flex lg:h-screen lg:overflow-hidden">
      {/* Left Brand Panel (Desktop lg+) — 1:1 port of AuthBrandPanel */}
      <aside className="hidden lg:flex lg:h-full lg:min-w-0 lg:flex-1 lg:p-[14px]">
        <div
          className="relative flex h-full w-full flex-col justify-between overflow-hidden rounded-[28px] p-[44px] text-white select-none"
          style={{
            background:
              'linear-gradient(135deg, var(--space-circle-backdrop) 0%, var(--space-circle-1) 52%, var(--space-circle-deep) 100%)',
          }}
        >
          {/* Ambient dust texture */}
          <img
            src="/assets/images/dust_pattern.webp"
            alt=""
            aria-hidden="true"
            className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-[0.14] mix-blend-screen"
          />

          {/* Radial drifting accent glow */}
          <div
            aria-hidden="true"
            className="pointer-events-none absolute -top-24 -right-24 h-[460px] w-[460px] rounded-full blur-3xl"
            style={{
              background:
                'radial-gradient(circle, color-mix(in srgb, var(--space-circle-2) 45%, transparent) 0%, transparent 70%)',
            }}
          />

          {/* Floating sparkles book art */}
          <img
            src="/assets/images/book_sparkle_bg.webp"
            alt=""
            aria-hidden="true"
            className="animate-eduma-float pointer-events-none absolute top-[-24px] right-[-36px] h-[420px] w-[420px] object-contain opacity-[0.55]"
          />

          {/* Top-left brand badge */}
          <div className="relative z-10 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-white p-[7px] shadow-sm">
              <img
                src="/assets/logo/logo.png"
                alt="Eduma"
                className="h-full w-full object-contain"
              />
            </div>
            <span className="text-[21px] font-bold tracking-[-0.4px] text-white">
              Eduma
            </span>
          </div>

          {/* Bottom-left editorial copy + 3 BrandFeatureRows */}
          <div className="relative z-10 max-w-[460px]">
            <h2 className="whitespace-pre-line text-[38px] leading-[1.12] font-bold tracking-[-0.9px] text-white">
              {'Learn, plan and\nstudy together.'}
            </h2>
            <p className="mt-[14px] text-[15.5px] leading-[1.45] text-white/76">
              Your notebooks, study spaces and schedule in one calm place, on every device.
            </p>

            <div className="mt-8 flex flex-col gap-[14px]">
              {BRAND_FEATURES.map((feat) => (
                <div key={feat.title} className="flex items-center gap-3.5">
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-white/18 bg-white/12 text-white backdrop-blur-sm">
                    <EdumaIcon family="iconsax" name={feat.icon} size={20} />
                  </div>
                  <div className="min-w-0">
                    <p className="text-[14.5px] leading-[1.25] font-bold text-white">
                      {feat.title}
                    </p>
                    <p className="mt-0.5 text-[13px] leading-[1.35] text-white/72">
                      {feat.subtitle}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </aside>

      {/* Right Form Column — clamp(520px, 40vw, 680px) on var(--eduma-bg) */}
      <main className="flex min-h-screen w-full flex-col justify-center bg-[var(--eduma-bg)] px-5 py-7 lg:h-full lg:min-h-0 lg:w-[clamp(520px,40vw,680px)] lg:shrink-0 lg:overflow-y-auto lg:px-7 lg:py-8">
        <div
          className="mx-auto flex w-full max-w-[480px] flex-col justify-center lg:w-full"
          style={
            maxBodyHeight
              ? { maxHeight: `${maxBodyHeight}px` }
              : undefined
          }
        >
          {/* Compact mobile brand header (lg:hidden) */}
          <div className="mb-7 flex items-center gap-2.5 lg:hidden">
            <img
              src="/assets/logo/logo.png"
              alt="Eduma"
              className="h-9 w-9 rounded-xl object-contain"
            />
            <span className="text-[20px] font-bold tracking-tight text-[var(--eduma-text-primary)]">
              Eduma
            </span>
          </div>

          {children}
        </div>
      </main>
    </div>
  );
}
