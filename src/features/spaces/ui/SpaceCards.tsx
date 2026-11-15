import { Link } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { formatRelativeTime } from '../../../core/utils/dateFormatters';
import { AdaptiveImage } from '../../../shared/components/AdaptiveImage';
import {
  PersonalSpaceBadge,
  SpaceMemberStack,
} from '../../../shared/components/BadgesAndAvatars';
import { EdumaCoverFallback } from '../../../shared/components/EdumaCoverFallback';
import { FloatingContextMenu } from '../../../shared/components/FloatingContextMenu';
import { pickSpaceGridTints } from '../logic/spaceLogic';
import type { Space } from '../models/spaceModels';

interface SpaceCardActions {
  onTogglePin: (space: Space) => void;
  onCopyInvite?: (space: Space) => void;
  onDelete?: (space: Space) => void;
}

export function SpaceGridCard({
  space,
  onTogglePin,
  onCopyInvite,
  onDelete,
}: { space: Space } & SpaceCardActions) {
  const tints = pickSpaceGridTints(space.id);
  const href = `/spaceDetail?id=${encodeURIComponent(space.id)}`;

  return (
    <article className="group eduma-card-surface relative flex flex-col justify-between overflow-hidden rounded-[22px] p-4 transition hover:-translate-y-0.5 hover:border-[var(--eduma-primary)]/40">
      {/* Top accent wash matching SpaceGridTints */}
      <div
        className="pointer-events-none absolute inset-x-0 top-0 h-28 opacity-20"
        style={{
          background: `radial-gradient(circle at 50% 0%, ${tints.main}, transparent 72%)`,
        }}
      />

      <div className="relative z-10 flex items-start justify-between gap-2">
        <div className="flex flex-wrap items-center gap-1.5">
          {space.isPinned ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-[var(--eduma-nav-pill)] px-2 py-0.5 text-[11px] font-bold text-[var(--eduma-primary)]">
              <EdumaIcon family="huge-solid" name="pin" size={11} />
              <span>Pinned</span>
            </span>
          ) : null}
          {space.isPersonal ? <PersonalSpaceBadge compact /> : null}
        </div>

        <FloatingContextMenu
          trigger={({ onClick }) => (
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onClick();
              }}
              aria-label={`Options for ${space.title}`}
              className="flex h-7 w-7 cursor-pointer items-center justify-center rounded-full bg-[var(--eduma-surface)]/80 text-[var(--eduma-text-muted)] transition hover:bg-[var(--eduma-card)] hover:text-[var(--eduma-text-primary)]"
            >
              <EdumaIcon family="huge-stroke" name="moreHorizontal" size={16} />
            </button>
          )}
          items={[
            {
              id: 'pin',
              label: space.isPinned ? 'Unpin space' : 'Pin space',
              icon: <EdumaIcon family="huge-stroke" name={space.isPinned ? 'pinOff' : 'pin'} size={15} />,
              onSelect: () => onTogglePin(space),
            },
            ...(onCopyInvite && space.inviteCode
              ? [
                  {
                    id: 'invite',
                    label: 'Copy invite link',
                    icon: <EdumaIcon family="huge-stroke" name="copyLink" size={15} />,
                    onSelect: () => onCopyInvite(space),
                  },
                ]
              : []),
            ...(onDelete && !space.isPersonal
              ? [
                  {
                    id: 'delete',
                    label: 'Delete space',
                    danger: true,
                    icon: <EdumaIcon family="huge-stroke" name="delete02" size={15} />,
                    onSelect: () => onDelete(space),
                  },
                ]
              : []),
          ]}
        />
      </div>

      {/* 3-sheet fanned cover stack matching SpaceGridFan (-0.2rad, 0.16rad, -0.035rad) */}
      <Link to={href} className="relative mx-auto my-5 block h-28 w-28">
        <div
          className="absolute inset-0 overflow-hidden rounded-[14px] opacity-85 shadow-sm transition-transform group-hover:scale-[1.03]"
          style={{
            transform: 'translateX(-13%) rotate(-11.4deg) scale(0.8)',
            backgroundColor: tints.left,
          }}
        >
          <AdaptiveImage
            src={space.coverUrl}
            alt=""
            className="h-full w-full object-cover opacity-55 mix-blend-multiply"
            fallback={<div className="h-full w-full" style={{ backgroundColor: tints.left }} />}
          />
        </div>

        <div
          className="absolute inset-0 overflow-hidden rounded-[14px] opacity-80 shadow-sm transition-transform group-hover:scale-[1.03]"
          style={{
            transform: 'translateX(13%) rotate(9.2deg) scale(0.84)',
            backgroundColor: tints.right,
          }}
        >
          <AdaptiveImage
            src={space.coverUrl}
            alt=""
            className="h-full w-full object-cover opacity-55 mix-blend-multiply"
            fallback={<div className="h-full w-full" style={{ backgroundColor: tints.right }} />}
          />
        </div>

        <div
          className="relative h-full w-full overflow-hidden rounded-[14px] border border-white/25 shadow-md transition-transform group-hover:scale-[1.04]"
          style={{ transform: 'rotate(-2deg)' }}
        >
          <AdaptiveImage
            src={space.coverUrl}
            alt={space.title}
            className="h-full w-full object-cover"
            fallback={<EdumaCoverFallback seed={space.id} label={space.title} />}
          />
        </div>
      </Link>

      <Link to={href} className="relative z-10 block min-w-0">
        <h3 className="type-title-md truncate text-[var(--eduma-text-primary)]">
          {space.title}
        </h3>
        <div className="mt-2 flex items-center justify-between gap-2">
          <span className="type-body-sm text-[var(--eduma-text-muted)]">
            {space.pagesCount} {space.pagesCount === 1 ? 'page' : 'pages'}
            {space.updatedAt ? ` · ${formatRelativeTime(space.updatedAt)}` : ''}
          </span>
          <SpaceMemberStack
            members={space.members}
            totalCount={space.membersCount}
            size={20}
          />
        </div>
      </Link>
    </article>
  );
}

export function SpaceTile({
  space,
  onTogglePin,
  onCopyInvite,
  onDelete,
}: { space: Space } & SpaceCardActions) {
  const href = `/spaceDetail?id=${encodeURIComponent(space.id)}`;

  return (
    <div className="eduma-card-surface flex items-center justify-between gap-3 rounded-[18px] p-3.5 transition hover:border-[var(--eduma-primary)]/40">
      <Link to={href} className="flex min-w-0 flex-1 items-center gap-3.5">
        <div className="h-14 w-14 shrink-0 overflow-hidden rounded-[14px] border border-[var(--eduma-border)]">
          <AdaptiveImage
            src={space.coverUrl}
            alt={space.title}
            className="h-full w-full object-cover"
            fallback={
              <EdumaCoverFallback seed={space.id} label={space.title} compact />
            }
          />
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <h3 className="type-title-md truncate text-[var(--eduma-text-primary)]">
              {space.title}
            </h3>
            {space.isPinned ? (
              <EdumaIcon
                family="huge-solid"
                name="pin"
                size={13}
                color="var(--eduma-primary)"
              />
            ) : null}
            {space.isPersonal ? <PersonalSpaceBadge compact /> : null}
          </div>
          <p className="type-body-sm mt-0.5 truncate text-[var(--eduma-text-muted)]">
            {space.pagesCount} {space.pagesCount === 1 ? 'page' : 'pages'}
            {space.membersCount > 0 ? ` · ${space.membersCount} members` : ''}
            {space.updatedAt ? ` · ${formatRelativeTime(space.updatedAt)}` : ''}
          </p>
        </div>
      </Link>

      <div className="flex shrink-0 items-center gap-2">
        <SpaceMemberStack
          members={space.members}
          totalCount={space.membersCount}
          size={24}
        />
        <FloatingContextMenu
          trigger={({ onClick }) => (
            <button
              type="button"
              onClick={onClick}
              aria-label={`Options for ${space.title}`}
              className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-full text-[var(--eduma-text-muted)] hover:bg-[var(--eduma-card)] hover:text-[var(--eduma-text-primary)]"
            >
              <EdumaIcon family="huge-stroke" name="moreVertical" size={16} />
            </button>
          )}
          items={[
            {
              id: 'pin',
              label: space.isPinned ? 'Unpin space' : 'Pin space',
              icon: <EdumaIcon family="huge-stroke" name={space.isPinned ? 'pinOff' : 'pin'} size={15} />,
              onSelect: () => onTogglePin(space),
            },
            ...(onCopyInvite && space.inviteCode
              ? [
                  {
                    id: 'invite',
                    label: 'Copy invite link',
                    icon: <EdumaIcon family="huge-stroke" name="copyLink" size={15} />,
                    onSelect: () => onCopyInvite(space),
                  },
                ]
              : []),
            ...(onDelete && !space.isPersonal
              ? [
                  {
                    id: 'delete',
                    label: 'Delete space',
                    danger: true,
                    icon: <EdumaIcon family="huge-stroke" name="delete02" size={15} />,
                    onSelect: () => onDelete(space),
                  },
                ]
              : []),
          ]}
        />
      </div>
    </div>
  );
}
