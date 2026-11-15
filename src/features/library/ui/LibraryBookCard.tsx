import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AdaptiveImage } from '../../../shared/components/AdaptiveImage';
import { VerifiedBadge } from '../../../shared/components/BadgesAndAvatars';
import { EdumaCoverFallback } from '../../../shared/components/EdumaCoverFallback';
import { edgeLayersOfBook, pickLibraryBookTints } from '../logic/libraryLogic';
import type { LibraryDocument } from '../models/libraryModels';

interface LibraryBookCardProps {
  doc: LibraryDocument;
  onOpen: (doc: LibraryDocument) => void;
  onToggleSave?: (doc: LibraryDocument) => void;
}

/**
 * Ports `LibraryBookStage` from `../eduma`: category small-caps label above
 * the portrait book cover with 1–3 stacked paper edge sheets sized by pageCount.
 */
export function LibraryBookCard({
  doc,
  onOpen,
  onToggleSave,
}: LibraryBookCardProps) {
  const tints = pickLibraryBookTints(doc);
  const edgeCount = edgeLayersOfBook(doc.pageCount);
  const progress = Math.round(doc.progressPercent ?? 0);

  return (
    <article className="group flex flex-col">
      {/* Stage wash */}
      <button
        type="button"
        onClick={() => onOpen(doc)}
        className="relative flex w-full cursor-pointer flex-col items-center overflow-hidden rounded-[22px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-4 pt-3 pb-4 text-left transition hover:-translate-y-0.5 hover:border-[var(--eduma-primary)]/45"
      >
        <div
          className="pointer-events-none absolute inset-0 opacity-15"
          style={{
            background: `linear-gradient(160deg, ${tints.main} 0%, ${tints.end} 65%, transparent 100%)`,
          }}
        />

        {/* Small-caps category row */}
        <div className="relative z-10 mb-3 flex w-full items-center justify-between gap-2">
          <span
            className="truncate text-[10.5px] font-bold uppercase tracking-[0.08em]"
            style={{ color: tints.main }}
          >
            {doc.category || 'Resource'}
          </span>
          {doc.isPremium ? (
            <EdumaIcon
              family="huge-solid"
              name="crown"
              size={14}
              color="var(--eduma-gold)"
            />
          ) : null}
        </div>

        {/* Stacked paper edge sheets + Bound cover */}
        <div className="relative z-10 mx-auto aspect-[3/4] w-[76%] max-w-[138px]">
          {edgeCount >= 3 ? (
            <div className="absolute inset-y-1.5 -right-2.5 left-2 rounded-r-[11px] border border-black/10 bg-[#e6e4ef] dark:bg-[#2b2b34]" />
          ) : null}
          {edgeCount >= 2 ? (
            <div className="absolute inset-y-1 -right-1.5 left-1.5 rounded-r-[12px] border border-black/10 bg-[#f0eef7] dark:bg-[#32323d]" />
          ) : null}
          <div className="absolute inset-y-0.5 -right-0.5 left-1 rounded-r-[12px] border border-black/10 bg-[#faf9fd] dark:bg-[#3a3a46]" />

          {/* Bound Book Cover */}
          <div className="relative h-full w-full overflow-hidden rounded-[13px] border border-white/25 shadow-lg">
            {/* Spine binding shadow on left edge */}
            <div
              className="pointer-events-none absolute inset-y-0 left-0 z-10 w-2.5"
              style={{
                background:
                  'linear-gradient(90deg, rgba(0,0,0,0.34) 0%, rgba(255,255,255,0.16) 50%, transparent 100%)',
              }}
            />

            <AdaptiveImage
              src={doc.coverUrl || doc.thumbnailUrl}
              alt={doc.title}
              className="h-full w-full object-cover"
              fallback={
                <EdumaCoverFallback seed={doc.id || doc.title} label={doc.title} />
              }
            />

            {/* Bottom badge overlay (verified / pages / reading bar) */}
            <div
              className="absolute inset-x-0 bottom-0 z-10 px-2 py-1.5 text-white"
              style={{
                background:
                  'linear-gradient(180deg, transparent 0%, rgba(0,0,0,0.72) 100%)',
              }}
            >
              <div className="flex items-center justify-between gap-1 text-[10px] font-semibold">
                {doc.pageCount ? <span>{doc.pageCount}p</span> : <span />}
                {doc.isVerified ? <VerifiedBadge size={12} /> : null}
              </div>
              {progress > 0 ? (
                <div className="mt-1 h-1 w-full overflow-hidden rounded-full bg-white/30">
                  <div
                    className="h-full rounded-full bg-[var(--eduma-primary)]"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              ) : null}
            </div>
          </div>
        </div>
      </button>

      {/* Book Title + Author + Quick bookmark below stage */}
      <div className="mt-2.5 flex items-start justify-between gap-2 px-1">
        <div className="min-w-0">
          <h3 className="type-title-sm line-clamp-2 text-[var(--eduma-text-primary)]">
            {doc.title}
          </h3>
          {doc.author ? (
            <p className="type-body-sm truncate text-[var(--eduma-text-muted)]">
              {doc.author}
            </p>
          ) : null}
        </div>

        {onToggleSave ? (
          <button
            type="button"
            onClick={() => onToggleSave(doc)}
            aria-label={doc.isSaved ? 'Remove from saved' : 'Save book'}
            className="mt-0.5 shrink-0 cursor-pointer text-[var(--eduma-text-muted)] hover:text-[var(--eduma-primary)]"
          >
            <EdumaIcon
              family={doc.isSaved ? 'huge-solid' : 'huge-stroke'}
              name={doc.isSaved ? 'bookmark02' : 'bookmarkAdd02'}
              size={17}
              color={doc.isSaved ? 'var(--eduma-primary)' : undefined}
            />
          </button>
        ) : null}
      </div>
    </article>
  );
}
