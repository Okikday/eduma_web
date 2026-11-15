import { EdumaIcon } from '../../core/icons/EdumaIcon';
import { getInitials, pickAccentForId } from '../../core/utils/accentHash';
import { AdaptiveImage } from './AdaptiveImage';

export function VerifiedBadge({ size = 15 }: { size?: number }) {
  return (
    <span
      title="Verified"
      className="inline-flex shrink-0 items-center justify-center text-[var(--eduma-primary)]"
    >
      <EdumaIcon family="iconsax" name="verify_copy" size={size} />
    </span>
  );
}

export function PersonalSpaceBadge({ compact = false }: { compact?: boolean }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-[var(--eduma-nav-pill)] px-2 py-0.5 text-[11px] font-bold text-[var(--eduma-primary)]">
      <EdumaIcon family="huge-solid" name="shieldUser" size={12} />
      {compact ? null : <span>Personal</span>}
    </span>
  );
}

export interface AvatarPerson {
  id?: string;
  name?: string;
  avatarUrl?: string | null;
}

export function UserAvatar({
  person,
  size = 36,
  className = '',
}: {
  person: AvatarPerson;
  size?: number;
  className?: string;
}) {
  const accent = pickAccentForId(person.id || person.name || 'user');
  const initials = getInitials(person.name);

  return (
    <div
      className={`relative inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full border border-[var(--eduma-border)] font-bold text-white select-none ${className}`}
      style={{
        width: `${size}px`,
        height: `${size}px`,
        backgroundColor: accent.cssVar,
        fontSize: `${Math.max(11, Math.round(size * 0.38))}px`,
      }}
    >
      <AdaptiveImage
        src={person.avatarUrl}
        alt={person.name || 'User avatar'}
        className="h-full w-full object-cover"
        fallback={<span>{initials}</span>}
      />
    </div>
  );
}

export function SpaceMemberStack({
  members,
  totalCount,
  maxVisible = 3,
  size = 24,
}: {
  members?: AvatarPerson[];
  totalCount?: number;
  maxVisible?: number;
  size?: number;
}) {
  const list = members || [];
  const shown = list.slice(0, maxVisible);
  const extra = Math.max(0, (totalCount ?? list.length) - shown.length);

  if (shown.length === 0 && !extra) return null;

  return (
    <div className="flex items-center">
      <div className="flex items-center">
        {shown.map((m, idx) => (
          <div
            key={m.id || `${idx}-${m.name || 'm'}`}
            style={{ marginLeft: idx === 0 ? 0 : `-${Math.round(size * 0.28)}px` }}
            className="ring-2 ring-[var(--eduma-surface)] rounded-full"
          >
            <UserAvatar person={m} size={size} />
          </div>
        ))}
      </div>
      {extra > 0 ? (
        <span className="ml-1.5 text-[11px] font-semibold text-[var(--eduma-text-muted)]">
          +{extra}
        </span>
      ) : null}
    </div>
  );
}

export function ProfileAvatarButton({
  name,
  avatarUrl,
  size = 40,
  onClick,
}: {
  name?: string;
  avatarUrl?: string | null;
  size?: number;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label="Open profile"
      className="cursor-pointer rounded-full transition hover:scale-105 active:scale-95"
    >
      <UserAvatar person={{ name, avatarUrl }} size={size} />
    </button>
  );
}
