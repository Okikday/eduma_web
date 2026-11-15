import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { apiClient } from '../../../core/api/apiClient';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import {
  getStorageItem,
  setStorageItem,
  STORAGE_KEYS,
} from '../../../core/storage/storageService';
import { getGreetingForHour } from '../../../core/utils/dateFormatters';
import { AppButton } from '../../../shared/components/AppButton';
import { AppCircleIconButton } from '../../../shared/components/AppCircleIconButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { useToast } from '../../../shared/components/AppToast';
import { ProfileAvatarButton } from '../../../shared/components/BadgesAndAvatars';
import {
  DesktopActionButton,
  DesktopPinnedPageHeader,
} from '../../../shared/components/DesktopPageHeader';
import { FloatingContextMenu } from '../../../shared/components/FloatingContextMenu';
import { useFormFactor } from '../../../shared/components/formFactor';
import { useAuth } from '../../auth/data/AuthContext';
import { EmailVerificationBanner } from '../../auth/ui/EmailVerificationBanner';
import { MainShell } from '../../main/shell/MainShell';
import { spacesApi } from '../data/spacesApi';
import {
  filterSpaces,
  searchCachedPageContent,
  sortSpaces,
} from '../logic/spaceLogic';
import type {
  Space,
  SpaceCardStyle,
  SpacePage,
  SpaceSortOrder,
} from '../models/spaceModels';
import { HomeHighlights } from './HomeHighlights';
import { SpaceGridCard, SpaceTile } from './SpaceCards';
import { CreateSpaceDialog, JoinSpaceDialog } from './SpaceModals';

export function HomeTabView() {
  const { user } = useAuth();
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();
  const navigate = useNavigate();

  const [spaces, setSpaces] = useState<Space[]>([]);
  const [recentPages, setRecentPages] = useState<SpacePage[]>([]);
  const [streakDays, setStreakDays] = useState<number>(0);
  const [unreadCount, setUnreadCount] = useState<number>(0);
  const [loading, setLoading] = useState(true);

  const [query, setQuery] = useState('');
  const [sortOrder, setSortOrder] = useState<SpaceSortOrder>(() => {
    const saved = getStorageItem(STORAGE_KEYS.spaceSort);
    return saved === 'name' || saved === 'pages' ? saved : 'recent';
  });
  const [cardStyle, setCardStyle] = useState<SpaceCardStyle>(() => {
    const saved = getStorageItem(STORAGE_KEYS.spaceCardStyle);
    return saved === 'list' ? 'list' : 'grid';
  });

  const [createOpen, setCreateOpen] = useState(false);
  const [joinOpen, setJoinOpen] = useState(false);

  const loadData = useCallback(async () => {
    try {
      const [spacesList, recentsList, streakRes, unreadRes] =
        await Promise.all([
          spacesApi.listSpaces().catch(() => [] as Space[]),
          spacesApi.listRecentPages(12).catch(() => [] as SpacePage[]),
          apiClient
            .get<{ current?: number; currentStreak?: number; streak?: number }>(
              '/streaks/me',
              { params: { days: 7 } }
            )
            .catch(() => null),
          apiClient
            .get<{ count?: number; unreadCount?: number }>(
              '/notifications/unread-count'
            )
            .catch(() => null),
        ]);

      setSpaces(spacesList);
      setRecentPages(recentsList);
      if (streakRes) {
        setStreakDays(
          Number(streakRes.current ?? streakRes.currentStreak ?? streakRes.streak ?? 0)
        );
      }
      if (unreadRes) {
        setUnreadCount(Number(unreadRes.unreadCount ?? unreadRes.count ?? 0));
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    const unsubSpaces = AppSyncBus.subscribe('spaces:changed', loadData);
    const unsubNotif = AppSyncBus.subscribe('notifications:changed', loadData);
    const unsubStreaks = AppSyncBus.subscribe('streaks:changed', loadData);
    return () => {
      unsubSpaces();
      unsubNotif();
      unsubStreaks();
    };
  }, [loadData]);

  const firstName = useMemo(() => {
    const first = (user?.name || '').trim().split(/\s+/)[0];
    return first || 'Student';
  }, [user?.name]);

  const greeting = getGreetingForHour(new Date().getHours());

  const spacesById = useMemo(() => {
    const map: Record<string, Space> = {};
    for (const s of spaces) map[s.id] = s;
    return map;
  }, [spaces]);

  const pinnedSpaces = useMemo(
    () => spaces.filter((s) => s.isPinned),
    [spaces]
  );

  const cachedAllPages = useMemo(() => {
    const seen = new Map<string, SpacePage>();
    for (const p of recentPages) seen.set(`${p.spaceId}:${p.id}`, p);
    for (const s of spaces) {
      for (const p of s.pages || []) {
        const key = `${p.spaceId || s.id}:${p.id}`;
        if (!seen.has(key)) seen.set(key, { ...p, spaceTitle: s.title });
      }
    }
    return Array.from(seen.values());
  }, [recentPages, spaces]);

  const visibleSpaces = useMemo(() => {
    const filtered = filterSpaces(spaces, query);
    return sortSpaces(filtered, sortOrder);
  }, [spaces, query, sortOrder]);

  const contentHits = useMemo(
    () => searchCachedPageContent(cachedAllPages, spacesById, query),
    [cachedAllPages, spacesById, query]
  );

  const handleTogglePin = async (space: Space) => {
    const nextPin = !space.isPinned;
    setSpaces((prev) =>
      prev.map((s) => (s.id === space.id ? { ...s, isPinned: nextPin } : s))
    );
    try {
      await spacesApi.togglePinSpace(space.id, nextPin);
      showToast(
        nextPin ? `Pinned "${space.title}"` : `Unpinned "${space.title}"`,
        'success'
      );
      AppSyncBus.emit('spaces:changed');
    } catch (err) {
      setSpaces((prev) =>
        prev.map((s) => (s.id === space.id ? { ...s, isPinned: !nextPin } : s))
      );
      showToast(
        err instanceof Error ? err.message : 'Unable to update pin state.',
        'error'
      );
    }
  };

  const handleCopyInvite = async (space: Space) => {
    if (!space.inviteCode) return;
    const url = `${window.location.origin}/join/${encodeURIComponent(
      space.inviteCode
    )}`;
    try {
      await navigator.clipboard.writeText(url);
      showToast('Invite link copied to clipboard.', 'success');
    } catch {
      showToast(`Invite code: ${space.inviteCode}`, 'info');
    }
  };

  const handleDeleteSpace = async (space: Space) => {
    if (!window.confirm(`Delete "${space.title}"? This cannot be undone.`)) {
      return;
    }
    try {
      await spacesApi.deleteSpace(space.id);
      setSpaces((prev) => prev.filter((s) => s.id !== space.id));
      showToast(`Deleted "${space.title}"`, 'success');
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to delete space.',
        'error'
      );
    }
  };

  const updateSort = (next: SpaceSortOrder) => {
    setSortOrder(next);
    setStorageItem(STORAGE_KEYS.spaceSort, next);
  };

  const toggleCardStyle = () => {
    const next: SpaceCardStyle = cardStyle === 'grid' ? 'list' : 'grid';
    setCardStyle(next);
    setStorageItem(STORAGE_KEYS.spaceCardStyle, next);
  };

  const isSearching = query.trim().length > 0;

  return (
    <MainShell
      activeTab="home"
      onQuickCreateSpace={() => setCreateOpen(true)}
      onQuickJoinSpace={() => setJoinOpen(true)}
      onQuickCreateEvent={() => navigate('/calendarTab?create=1')}
    >
      {isExpanded ? (
        <DesktopPinnedPageHeader
          title={`${greeting}, ${firstName}`}
          subtitle={new Date().toLocaleDateString(undefined, {
            weekday: 'long',
            day: 'numeric',
            month: 'long',
          })}
          actions={
            <>
              <Link
                to="/streak"
                title={streakDays > 0 ? `${streakDays}-day study streak` : 'Start a streak'}
                className="inline-flex h-[42px] items-center gap-1 rounded-full border-[1.5px] border-[var(--eduma-border)] bg-[color-mix(in_srgb,#f5a524_18%,var(--eduma-surface))] px-3 text-[var(--eduma-text-primary)] backdrop-blur-sm transition hover:border-[var(--eduma-primary)]"
              >
                <EdumaIcon
                  family={streakDays > 0 ? 'huge-solid' : 'huge-stroke'}
                  name="fire"
                  size={18}
                  className={streakDays > 0 ? 'text-[var(--eduma-warning)]' : ''}
                />
                {streakDays > 0 ? (
                  <span className="text-[14px] font-bold leading-none">{streakDays}</span>
                ) : null}
              </Link>
              <AppCircleIconButton
                size={42}
                label="AI chats"
                onClick={() => navigate('/assistantHistory')}
              >
                <EdumaIcon family="huge-stroke" name="sparkles" size={19} />
              </AppCircleIconButton>
              {spaces.length > 0 ? (
                <AppCircleIconButton
                  size={42}
                  label="Recent pages"
                  onClick={() => navigate('/recentCanvasesSeeAll')}
                >
                  <EdumaIcon family="huge-stroke" name="canvas" size={19} />
                </AppCircleIconButton>
              ) : null}
              <AppCircleIconButton
                size={42}
                label="Refresh"
                onClick={() => void loadData()}
              >
                <EdumaIcon family="iconsax" name="refresh_copy" size={19} />
              </AppCircleIconButton>
              <DesktopActionButton
                label="Join space"
                icon={<EdumaIcon family="iconsax" name="login_copy" size={17} />}
                onClick={() => setJoinOpen(true)}
              />
              <DesktopActionButton
                label="Create space"
                variant="filled"
                icon={<EdumaIcon family="iconsax" name="add_circle_copy" size={17} />}
                onClick={() => setCreateOpen(true)}
              />
            </>
          }
        />
      ) : null}

      <div
        className={
          isExpanded
            ? 'w-full px-8 pb-10 pt-2'
            : 'mx-auto w-full max-w-[1040px] px-4 py-4 sm:px-6'
        }
      >
        {!isExpanded ? (
          <header className="mb-5 flex items-center justify-between gap-3">
            <div className="flex min-w-0 items-center gap-3">
              <ProfileAvatarButton
                name={user?.name}
                avatarUrl={user?.avatarUrl}
                size={42}
                onClick={() => navigate('/profile')}
              />
              <button
                type="button"
                onClick={() => navigate('/profile')}
                className="min-w-0 text-left"
              >
                <p className="truncate text-[16px] font-bold text-[var(--eduma-text-primary)]">
                  Hi, {firstName}
                </p>
                <p className="text-[12px] font-medium text-[var(--eduma-text-muted)]">
                  {greeting}
                </p>
              </button>
            </div>

            <div className="flex shrink-0 items-center gap-2">
              <Link
                to="/streak"
                title={streakDays > 0 ? `${streakDays}-day study streak` : 'Start a streak'}
                className="inline-flex h-10 items-center gap-1 rounded-full border border-[var(--eduma-border)] bg-[color-mix(in_srgb,#f5a524_18%,var(--eduma-surface))] px-3 text-[var(--eduma-text-primary)]"
              >
                <EdumaIcon
                  family={streakDays > 0 ? 'huge-solid' : 'huge-stroke'}
                  name="fire"
                  size={17}
                  className={streakDays > 0 ? 'text-[var(--eduma-warning)]' : ''}
                />
                {streakDays > 0 ? (
                  <span className="text-[13.5px] font-bold leading-none">{streakDays}</span>
                ) : null}
              </Link>
              <AppCircleIconButton
                label="Notifications"
                badgeCount={unreadCount}
                onClick={() => navigate('/notifications')}
              >
                <EdumaIcon family="iconsax" name="notification_status_copy" size={19} />
              </AppCircleIconButton>
            </div>
          </header>
        ) : null}

        <EmailVerificationBanner />

        {/* SpaceHighlights (Recent canvases & Pinned spaces - hidden while searching) */}
        {!isSearching ? (
          <HomeHighlights
            recentPages={recentPages}
            pinnedSpaces={pinnedSpaces}
            spacesById={spacesById}
          />
        ) : null}

        {/* SpaceSearchBar + Sort + View Style Toggle */}
        <div className="mb-6 flex flex-wrap items-center justify-between gap-2.5">
          <div className="flex min-w-[220px] max-w-[640px] flex-1 items-center gap-2.5 rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 py-2.5 focus-within:border-[var(--eduma-primary)]">
            <EdumaIcon
              family="huge-stroke"
              name="search01"
              size={18}
              color="var(--eduma-text-muted)"
            />
            <input
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search spaces, notes, or page text…"
              aria-label="Search spaces and page content"
              className="w-full bg-transparent text-[14.5px] font-medium text-[var(--eduma-text-primary)] placeholder:text-[var(--eduma-text-muted)] focus:outline-none"
            />
            {query ? (
              <button
                type="button"
                onClick={() => setQuery('')}
                aria-label="Clear search"
                className="cursor-pointer text-[var(--eduma-text-muted)] hover:text-[var(--eduma-text-primary)]"
              >
                <EdumaIcon family="huge-stroke" name="cancel01" size={16} />
              </button>
            ) : null}
          </div>

          <FloatingContextMenu
            trigger={({ onClick }) => (
              <AppCircleIconButton label="Sort spaces" size={44} onClick={onClick}>
                <EdumaIcon family="huge-stroke" name="sortByDown01" size={18} />
              </AppCircleIconButton>
            )}
            items={[
              {
                id: 'recent',
                label: `Recent${sortOrder === 'recent' ? ' ✓' : ''}`,
                onSelect: () => updateSort('recent'),
              },
              {
                id: 'name',
                label: `Name (A–Z)${sortOrder === 'name' ? ' ✓' : ''}`,
                onSelect: () => updateSort('name'),
              },
              {
                id: 'pages',
                label: `Most pages${sortOrder === 'pages' ? ' ✓' : ''}`,
                onSelect: () => updateSort('pages'),
              },
            ]}
          />

          <AppCircleIconButton
            label={cardStyle === 'grid' ? 'Switch to list view' : 'Switch to grid view'}
            size={44}
            onClick={toggleCardStyle}
          >
            <EdumaIcon
              family="huge-stroke"
              name={cardStyle === 'grid' ? 'listView' : 'gridTable'}
              size={18}
            />
          </AppCircleIconButton>
        </div>

        {/* SpaceContentHitsSliver while searching */}
        {query.trim().length >= 2 && contentHits.length > 0 ? (
          <section className="mb-7">
            <h2 className="type-title-md mb-3 text-[var(--eduma-text-primary)]">
              Matching pages ({contentHits.length})
            </h2>
            <div className="space-y-2">
              {contentHits.slice(0, 6).map((hit) => (
                <Link
                  key={`${hit.page.spaceId}-${hit.page.id}`}
                  to={`/spacePageStatic?id=${encodeURIComponent(
                    hit.page.id
                  )}&spaceId=${encodeURIComponent(hit.page.spaceId)}`}
                  className="eduma-card-surface flex items-center justify-between gap-3 rounded-[16px] p-3.5 transition hover:border-[var(--eduma-primary)]/40"
                >
                  <div className="min-w-0">
                    <p className="type-title-sm truncate text-[var(--eduma-text-primary)]">
                      {hit.page.title}
                    </p>
                    <p className="type-body-sm mt-0.5 truncate text-[var(--eduma-text-muted)]">
                      {hit.spaceTitle} · {hit.matchedSnippet}
                    </p>
                  </div>
                  <EdumaIcon
                    family="huge-stroke"
                    name="arrowRight01"
                    size={16}
                    color="var(--eduma-text-muted)"
                  />
                </Link>
              ))}
            </div>
          </section>
        ) : null}

        {/* Main Spaces Section */}
        <section>
          <div className="mb-4 flex items-center justify-between gap-2">
            <h2 className="type-headline-sm text-[var(--eduma-text-primary)]">
              {isSearching ? 'Matching spaces' : 'Your spaces'}
            </h2>
            <div className="flex items-center gap-3">
              <Link
                to="/recentSpacesSeeAll"
                className="text-[13px] font-semibold text-[var(--eduma-primary)] hover:underline"
              >
                See all ({spaces.length})
              </Link>
            </div>
          </div>

          {loading ? (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {[1, 2, 3, 4, 5, 6].map((n) => (
                <div
                  key={n}
                  className="h-52 animate-pulse rounded-[22px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)]/70"
                />
              ))}
            </div>
          ) : visibleSpaces.length === 0 ? (
            <AppEmptyState
              iconFamily="huge-stroke"
              iconName="folder01"
              title={isSearching ? 'No spaces match your search' : 'No study spaces yet'}
              description={
                isSearching
                  ? 'Try another keyword or clear your search filter.'
                  : 'Create your first space or join a classmate with an invite code.'
              }
              action={
                isSearching ? (
                  <AppButton variant="secondary" onClick={() => setQuery('')}>
                    Clear search
                  </AppButton>
                ) : (
                  <div className="flex flex-wrap justify-center gap-2.5">
                    <AppButton onClick={() => setCreateOpen(true)}>
                      Create space
                    </AppButton>
                    <AppButton variant="secondary" onClick={() => setJoinOpen(true)}>
                      Join space
                    </AppButton>
                  </div>
                )
              }
            />
          ) : cardStyle === 'grid' ? (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {visibleSpaces.map((space) => (
                <SpaceGridCard
                  key={space.id}
                  space={space}
                  onTogglePin={handleTogglePin}
                  onCopyInvite={handleCopyInvite}
                  onDelete={handleDeleteSpace}
                />
              ))}
            </div>
          ) : (
            <div className="space-y-2.5">
              {visibleSpaces.map((space) => (
                <SpaceTile
                  key={space.id}
                  space={space}
                  onTogglePin={handleTogglePin}
                  onCopyInvite={handleCopyInvite}
                  onDelete={handleDeleteSpace}
                />
              ))}
            </div>
          )}
        </section>
      </div>

      <CreateSpaceDialog open={createOpen} onClose={() => setCreateOpen(false)} />
      <JoinSpaceDialog open={joinOpen} onClose={() => setJoinOpen(false)} />
    </MainShell>
  );
}
