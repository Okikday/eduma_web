import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AdaptiveImage } from '../../../shared/components/AdaptiveImage';
import {
  PersonalSpaceBadge,
  SpaceMemberStack,
  VerifiedBadge,
} from '../../../shared/components/BadgesAndAvatars';
import {
  DesktopHeroActionButton,
  DesktopHeroButton,
  DesktopHeroPane,
} from '../../../shared/components/DesktopSplitScaffold';
import { EdumaCoverFallback } from '../../../shared/components/EdumaCoverFallback';
import type { Space } from '../models/spaceModels';

interface SpaceDesktopHeroProps {
  space: Space | null;
  pagesCount: number;
  archivedCount: number;
  assetsCount: number;
  eventsCount: number;
  onBack: () => void;
  onRefresh: () => void;
  onTogglePin: () => void;
  onOpenSettings: () => void;
  onInvite: () => void;
  onSelectTab: (tab: 'pages' | 'assets' | 'events') => void;
}

function getRoleMeta(role?: string | null) {
  const normalized = (role || '').toLowerCase();
  if (normalized === 'owner') {
    return { icon: 'crown_1_copy' as const, label: 'Owner' };
  }
  if (normalized === 'admin' || normalized === 'moderator') {
    return { icon: 'shield_tick_copy' as const, label: 'Admin' };
  }
  return { icon: 'user_copy' as const, label: 'Member' };
}

export function SpaceDesktopHero({
  space,
  pagesCount,
  archivedCount,
  assetsCount,
  eventsCount,
  onBack,
  onRefresh,
  onTogglePin,
  onOpenSettings,
  onInvite,
  onSelectTab,
}: SpaceDesktopHeroProps) {
  const roleMeta = getRoleMeta(space?.role);
  const memberCount = space?.membersCount || space?.members?.length || 1;
  const description = space?.description?.trim();

  return (
    <DesktopHeroPane
      background={
        <AdaptiveImage
          src={space?.coverUrl}
          alt={space?.title || 'Study space'}
          className="h-full w-full object-cover"
          fallback={
            <EdumaCoverFallback
              seed={space?.id || 'space'}
              label={space?.title || 'S'}
              className="h-full w-full"
            />
          }
        />
      }
      leading={
        <DesktopHeroButton label="Back to home" onClick={onBack}>
          <EdumaIcon family="huge-stroke" name="arrowLeft01" size={19} />
        </DesktopHeroButton>
      }
      trailing={
        <>
          <DesktopHeroButton label="Refresh space" onClick={onRefresh}>
            <EdumaIcon family="iconsax" name="refresh_copy" size={18} />
          </DesktopHeroButton>
          <DesktopHeroButton
            label={space?.isPinned ? 'Unpin space' : 'Pin space'}
            onClick={onTogglePin}
          >
            <EdumaIcon
              family="huge-stroke"
              name={space?.isPinned ? 'pinOff' : 'pin'}
              size={18}
            />
          </DesktopHeroButton>
          <DesktopHeroButton label="Space settings" onClick={onOpenSettings}>
            <EdumaIcon family="huge-stroke" name="moreHorizontal" size={18} />
          </DesktopHeroButton>
        </>
      }
      content={
        <div className="space-y-4">
          <div className="flex flex-wrap items-center gap-2">
            <span className="inline-flex items-center gap-1.5 rounded-full border border-white/25 bg-white/15 px-3 py-1 text-[12px] font-bold text-white backdrop-blur-md">
              <EdumaIcon family="iconsax" name={roleMeta.icon} size={14} />
              <span>{roleMeta.label}</span>
            </span>
            {space?.isPersonal ? <PersonalSpaceBadge /> : null}
          </div>

          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-[39px] font-bold leading-[1.1] tracking-[-0.025em] text-white">
                {space?.title || 'Loading space…'}
              </h1>
              {space?.isVerified ? <VerifiedBadge size={20} /> : null}
            </div>
            {description ? (
              <p className="mt-2 line-clamp-2 max-w-[46ch] text-[14.5px] leading-[1.45] text-white/80">
                {description}
              </p>
            ) : null}
          </div>

          {/* SpaceHeroFacts */}
          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={onInvite}
              className="inline-flex items-center gap-2 rounded-full border border-white/22 bg-white/14 px-3 py-1.5 text-[12.5px] font-semibold text-white backdrop-blur-md transition hover:bg-white/24"
            >
              <SpaceMemberStack
                members={space?.members}
                totalCount={memberCount}
                maxVisible={3}
                size={20}
              />
              <span>
                {memberCount} {memberCount === 1 ? 'member' : 'members'}
              </span>
            </button>

            <button
              type="button"
              onClick={() => onSelectTab('pages')}
              className="inline-flex items-center gap-1.5 rounded-full border border-white/22 bg-white/14 px-3 py-1.5 text-[12.5px] font-semibold text-white backdrop-blur-md transition hover:bg-white/24"
            >
              <EdumaIcon family="huge-stroke" name="note01" size={14} />
              <span>
                {pagesCount} {pagesCount === 1 ? 'page' : 'pages'}
              </span>
            </button>

            {archivedCount > 0 ? (
              <button
                type="button"
                onClick={() => onSelectTab('pages')}
                className="inline-flex items-center gap-1.5 rounded-full border border-white/22 bg-white/14 px-3 py-1.5 text-[12.5px] font-semibold text-white/90 backdrop-blur-md transition hover:bg-white/24"
              >
                <EdumaIcon family="iconsax" name="archive_copy" size={13} />
                <span>{archivedCount} archived</span>
              </button>
            ) : null}

            <button
              type="button"
              onClick={() => onSelectTab('assets')}
              className="inline-flex items-center gap-1.5 rounded-full border border-white/22 bg-white/14 px-3 py-1.5 text-[12.5px] font-semibold text-white backdrop-blur-md transition hover:bg-white/24"
            >
              <EdumaIcon family="huge-stroke" name="documentAttachment" size={14} />
              <span>
                {assetsCount} {assetsCount === 1 ? 'asset' : 'assets'}
              </span>
            </button>

            <button
              type="button"
              onClick={() => onSelectTab('events')}
              className="inline-flex items-center gap-1.5 rounded-full border border-white/22 bg-white/14 px-3 py-1.5 text-[12.5px] font-semibold text-white backdrop-blur-md transition hover:bg-white/24"
            >
              <EdumaIcon family="huge-stroke" name="calendar03" size={14} />
              <span>
                {eventsCount} {eventsCount === 1 ? 'event' : 'events'}
              </span>
            </button>
          </div>

          {/* SpaceHeroActions */}
          <div className="flex flex-wrap items-center gap-2.5 pt-1">
            {!space?.isPersonal ? (
              <DesktopHeroActionButton
                isPrimary
                icon={<EdumaIcon family="iconsax" name="user_add_copy" size={16} />}
                label="Invite"
                onClick={onInvite}
              />
            ) : null}
            <DesktopHeroActionButton
              icon={<EdumaIcon family="iconsax" name="edit_2_copy" size={16} />}
              label="Edit space"
              onClick={onOpenSettings}
            />
          </div>
        </div>
      }
    />
  );
}
