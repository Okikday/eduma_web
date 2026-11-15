import { Link } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { formatRelativeTime } from '../../../core/utils/dateFormatters';
import { AdaptiveImage } from '../../../shared/components/AdaptiveImage';
import { SpaceMemberStack, VerifiedBadge } from '../../../shared/components/BadgesAndAvatars';
import { EdumaCoverFallback } from '../../../shared/components/EdumaCoverFallback';
import type { Space, SpacePage } from '../models/spaceModels';

interface HomeHighlightsProps {
  recentPages: readonly SpacePage[];
  pinnedSpaces: readonly Space[];
  spacesById: Record<string, Space>;
}

function RecentCanvasCard({
  page,
  spaceTitle,
}: {
  page: SpacePage;
  spaceTitle: string;
}) {
  const previewUrl = page.thumbnailUrl || page.coverUrl;
  const pageType = page.pageType === 'static' || page.pageType === 'staticCanvas' ? 'Note' : 'Dynamic';
  const timeText = formatRelativeTime(page.lastOpenedAt || page.updatedAt || page.createdAt);

  return (
    <Link
      to={`/spacePageStatic?id=${encodeURIComponent(page.id)}&spaceId=${encodeURIComponent(page.spaceId)}`}
      className="group relative flex min-w-[285px] flex-1 snap-start overflow-hidden rounded-[20px] border border-white/12 px-3 pt-3 text-white shadow-[var(--eduma-card-shadow)] transition-transform duration-150 active:scale-[0.98]"
      style={{
        background:
          'linear-gradient(135deg, color-mix(in srgb, var(--eduma-primary) 26%, #1e1f2b) 0%, #171822 100%)',
      }}
    >
      {previewUrl ? (
        <div className="pointer-events-none absolute inset-0 opacity-10">
          <AdaptiveImage src={previewUrl} alt="" className="h-full w-full object-cover" />
        </div>
      ) : null}

      <span className="absolute right-2.5 top-2 z-10 inline-flex items-center gap-1 rounded-full border border-white/15 bg-black/35 px-2 py-0.5 text-[10px] font-bold text-white/90 backdrop-blur-sm">
        <EdumaIcon
          family="huge-stroke"
          name={pageType === 'Note' ? 'note01' : 'canvas'}
          size={11}
        />
        {pageType}
      </span>

      <div className="relative z-10 flex w-full items-stretch gap-3">
        <div className="mt-auto h-[104px] w-[88px] shrink-0 overflow-hidden rounded-t-[16px] border border-b-0 border-white/15 bg-white/10 shadow-sm">
          <AdaptiveImage
            src={previewUrl}
            alt={page.title}
            className="h-full w-full object-cover transition-transform duration-200 group-hover:scale-105"
            fallback={
              <EdumaCoverFallback
                seed={page.id}
                label={page.title}
                className="h-full w-full"
              />
            }
          />
        </div>

        <div className="flex min-w-0 flex-1 flex-col justify-between pb-3 pt-2">
          <div>
            <p className="truncate pr-14 text-[12px] font-medium text-white/75">{spaceTitle}</p>
            <h3 className="mt-0.5 truncate text-[17px] font-bold leading-tight tracking-[-0.2px] text-white">
              {page.title || 'Untitled page'}
            </h3>
          </div>

          <div className="mt-3 flex items-center justify-between gap-2">
            <span className="truncate text-[11px] font-medium text-white/65">
              {timeText || 'Edited recently'}
            </span>
            <span className="inline-flex shrink-0 items-center gap-1 rounded-full bg-white px-2.5 py-1 text-[11.5px] font-bold text-[#141522] shadow-sm transition-transform group-hover:translate-x-0.5">
              <span>Resume</span>
              <EdumaIcon family="huge-stroke" name="arrowRight01" size={12} />
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}

function PinnedSpaceCard({ space }: { space: Space }) {
  const description = space.description?.trim();
  return (
    <Link
      to={`/spaceDetail?id=${encodeURIComponent(space.id)}`}
      className="flex h-[88px] items-center gap-2.5 rounded-[20px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] p-3 shadow-[var(--eduma-card-shadow)] transition hover:-translate-y-0.5 hover:border-[var(--eduma-primary)]/40"
    >
      <div className="h-[46px] w-[46px] shrink-0 overflow-hidden rounded-[13px] border border-[var(--eduma-border)] bg-[var(--eduma-card)]">
        <AdaptiveImage
          src={space.coverUrl}
          alt={space.title}
          className="h-full w-full object-cover"
          fallback={
            <EdumaCoverFallback
              seed={space.id}
              label={space.title}
              compact
              className="h-full w-full"
            />
          }
        />
      </div>

      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1">
          <p className="truncate text-[15.5px] font-semibold leading-tight text-[var(--eduma-text-primary)]">
            {space.title}
          </p>
          {space.isVerified ? <VerifiedBadge size={14} /> : null}
        </div>
        {description ? (
          <p className="mt-0.5 truncate text-[12px] font-medium leading-tight text-[var(--eduma-text-muted)]">
            {description}
          </p>
        ) : null}
        <div className="mt-1.5 flex items-center gap-2">
          <SpaceMemberStack
            members={space.members}
            totalCount={space.membersCount}
            maxVisible={3}
            size={20}
          />
        </div>
      </div>

      <span className="shrink-0 text-[var(--eduma-text-muted)]">
        <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
      </span>
    </Link>
  );
}

export function HomeHighlights({
  recentPages,
  pinnedSpaces,
  spacesById,
}: HomeHighlightsProps) {
  if (recentPages.length === 0 && pinnedSpaces.length === 0) return null;

  const hasBoth = recentPages.length > 0 && pinnedSpaces.length > 0;
  const recentStrip = recentPages.slice(0, 3);
  const pinnedList = hasBoth ? pinnedSpaces.slice(0, 2) : pinnedSpaces.slice(0, 4);

  return (
    <section className="@container mb-7">
      <div className={hasBoth ? 'grid grid-cols-1 gap-6 @[880px]:grid-cols-5' : 'space-y-6'}>
        {recentPages.length > 0 ? (
          <div className={hasBoth ? 'min-w-0 @[880px]:col-span-3' : 'min-w-0'}>
            <div className="mb-3 flex h-8 items-center justify-between">
              <h2 className="text-[19px] font-bold tracking-[-0.015em] text-[var(--eduma-text-primary)]">
                Recent canvas
              </h2>
              <Link
                to="/recentCanvasesSeeAll"
                className="text-[13px] font-bold text-[var(--eduma-primary)] hover:underline"
              >
                See all
              </Link>
            </div>

            <div className="flex snap-x gap-3 overflow-x-auto pb-1">
              {recentStrip.map((page) => (
                <RecentCanvasCard
                  key={`${page.spaceId}:${page.id}`}
                  page={page}
                  spaceTitle={page.spaceTitle || spacesById[page.spaceId]?.title || 'Space'}
                />
              ))}
            </div>
          </div>
        ) : null}

        {pinnedSpaces.length > 0 ? (
          <div
            className={`min-w-0 rounded-[20px] border border-[var(--eduma-border)] p-4 ${
              hasBoth ? '@[880px]:col-span-2' : ''
            }`}
            style={{
              background:
                'linear-gradient(180deg, color-mix(in srgb, var(--eduma-primary) 5%, var(--eduma-surface)) 0%, color-mix(in srgb, var(--eduma-surface) 45%, transparent) 100%)',
            }}
          >
            <div className="mb-3 flex items-center justify-between px-1">
              <h2 className="text-[19px] font-bold tracking-[-0.015em] text-[var(--eduma-text-primary)]">
                Pinned
              </h2>
              <Link
                to="/pinnedSpacesSeeAll"
                className="text-[13px] font-bold text-[var(--eduma-primary)] hover:underline"
              >
                See all
              </Link>
            </div>

            <div
              className={
                hasBoth
                  ? 'flex flex-col gap-3'
                  : 'grid grid-cols-1 gap-3.5 md:grid-cols-2 lg:grid-cols-3'
              }
            >
              {pinnedList.map((space) => (
                <PinnedSpaceCard key={space.id} space={space} />
              ))}
            </div>
          </div>
        ) : null}
      </div>
    </section>
  );
}
