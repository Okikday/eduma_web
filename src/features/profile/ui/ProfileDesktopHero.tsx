import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AdaptiveImage } from '../../../shared/components/AdaptiveImage';
import { VerifiedBadge } from '../../../shared/components/BadgesAndAvatars';
import {
  DesktopHeroActionButton,
  DesktopHeroButton,
  DesktopHeroPane,
} from '../../../shared/components/DesktopSplitScaffold';
import type { AuthUser } from '../../auth/models/authModels';

export interface ProfileStats {
  spacesCount: number;
  notebooksCount: number;
  studyMinutes: number;
}

interface ProfileDesktopHeroProps {
  user: AuthUser | null;
  stats: ProfileStats;
  onBack: () => void;
  onRefresh: () => void;
  onEditProfile: () => void;
  onPickPhoto: () => void;
  onLogout: () => void;
}

function getInitials(name?: string | null): string {
  const parts = (name || 'Eduma').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return 'E';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0] || ''}${parts[parts.length - 1][0] || ''}`.toUpperCase();
}

function formatStudyTime(minutes: number): string {
  if (!Number.isFinite(minutes) || minutes <= 0) return '0m studied';
  if (minutes < 60) return `${Math.round(minutes)}m studied`;
  const hrs = (minutes / 60).toFixed(1).replace(/\.0$/, '');
  return `${hrs}h studied`;
}

export function ProfileDesktopHero({
  user,
  stats,
  onBack,
  onRefresh,
  onEditProfile,
  onPickPhoto,
  onLogout,
}: ProfileDesktopHeroProps) {
  const initials = getInitials(user?.name);
  const memberSince = user?.createdAt
    ? new Date(user.createdAt).toLocaleDateString(undefined, {
        month: 'short',
        year: 'numeric',
      })
    : null;
  const sublineParts = [
    user?.username ? `@${user.username}` : null,
    user?.email || null,
  ].filter(Boolean);

  return (
    <DesktopHeroPane
      background={
        user?.avatarUrl ? (
          <AdaptiveImage
            src={user.avatarUrl}
            alt={user.name || 'Profile avatar'}
            className="h-full w-full object-cover"
          />
        ) : (
          <div
            className="relative flex h-full w-full items-center justify-center overflow-hidden"
            style={{
              background:
                'linear-gradient(145deg, var(--space-circle-backdrop) 0%, var(--space-circle-1) 48%, var(--space-circle-deep) 100%)',
            }}
          >
            <img
              src="/assets/images/dust_pattern.webp"
              alt=""
              aria-hidden="true"
              className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-[0.06]"
            />
            <div className="pointer-events-none absolute -left-24 -top-24 h-80 w-80 rounded-full bg-[radial-gradient(circle,rgba(157,215,251,0.28),transparent_70%)] blur-2xl" />
            <div className="pointer-events-none absolute -bottom-24 right-8 h-80 w-80 rounded-full bg-[radial-gradient(circle,rgba(83,117,246,0.32),transparent_70%)] blur-2xl" />
            <div className="relative z-10 flex h-[148px] w-[148px] items-center justify-center rounded-full border border-white/22 bg-white/10 shadow-[0_18px_48px_rgba(0,0,0,0.28)] backdrop-blur-md">
              <span className="text-[54px] font-bold tracking-tight text-white">
                {initials}
              </span>
            </div>
          </div>
        )
      }
      leading={
        <DesktopHeroButton label="Back to home" onClick={onBack}>
          <EdumaIcon family="huge-stroke" name="arrowLeft01" size={19} />
        </DesktopHeroButton>
      }
      trailing={
        <>
          <DesktopHeroButton label="Refresh profile" onClick={onRefresh}>
            <EdumaIcon family="iconsax" name="refresh_copy" size={18} />
          </DesktopHeroButton>
          <DesktopHeroButton label="Change photo" onClick={onPickPhoto}>
            <EdumaIcon family="iconsax" name="camera_copy" size={18} />
          </DesktopHeroButton>
        </>
      }
      content={
        <div className="space-y-4">
          <div className="flex flex-wrap items-center gap-2">
            {user?.isPremium ? (
              <span className="inline-flex items-center gap-1 rounded-full border border-white/25 bg-white/15 px-3 py-1 text-[12px] font-bold text-white backdrop-blur-md">
                <EdumaIcon family="huge-solid" name="crown" size={13} />
                <span>Eduma Pro</span>
              </span>
            ) : null}
            {user?.hasVerifiedBadge ? (
              <span className="inline-flex items-center gap-1 rounded-full border border-white/25 bg-white/15 px-3 py-1 text-[12px] font-bold text-white backdrop-blur-md">
                <EdumaIcon family="iconsax" name="verify_copy" size={13} />
                <span>Verified</span>
              </span>
            ) : null}
            <span className="inline-flex items-center rounded-full border border-white/20 bg-white/12 px-3 py-1 text-[12px] font-semibold text-white/95 backdrop-blur-md">
              {stats.spacesCount} {stats.spacesCount === 1 ? 'space' : 'spaces'}
            </span>
            <span className="inline-flex items-center rounded-full border border-white/20 bg-white/12 px-3 py-1 text-[12px] font-semibold text-white/95 backdrop-blur-md">
              {stats.notebooksCount} {stats.notebooksCount === 1 ? 'page' : 'pages'}
            </span>
            <span className="inline-flex items-center rounded-full border border-white/20 bg-white/12 px-3 py-1 text-[12px] font-semibold text-white/95 backdrop-blur-md">
              {formatStudyTime(stats.studyMinutes)}
            </span>
            {memberSince ? (
              <span className="inline-flex items-center rounded-full border border-white/20 bg-white/12 px-3 py-1 text-[12px] font-semibold text-white/90 backdrop-blur-md">
                Joined {memberSince}
              </span>
            ) : null}
          </div>

          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-[39px] font-bold leading-[1.1] tracking-[-0.025em] text-white">
                {user?.name || 'Eduma Student'}
              </h1>
              {user?.hasVerifiedBadge ? <VerifiedBadge size={20} /> : null}
            </div>
            {sublineParts.length > 0 ? (
              <p className="mt-1.5 truncate text-[14.5px] font-medium text-white/80">
                {sublineParts.join(' · ')}
              </p>
            ) : null}
          </div>

          <div className="flex flex-wrap items-center gap-2.5 pt-1">
            <DesktopHeroActionButton
              isPrimary
              icon={<EdumaIcon family="iconsax" name="user_edit_copy" size={16} />}
              label="Edit profile"
              onClick={onEditProfile}
            />
            <DesktopHeroActionButton
              icon={<EdumaIcon family="iconsax" name="camera_copy" size={16} />}
              label="Change photo"
              onClick={onPickPhoto}
            />
            <DesktopHeroActionButton
              icon={<EdumaIcon family="iconsax" name="logout_copy" size={16} />}
              label="Log out"
              onClick={onLogout}
            />
          </div>
        </div>
      }
    />
  );
}
