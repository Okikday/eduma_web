import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { formatRelativeTime } from '../../../core/utils/dateFormatters';
import { AppButton } from '../../../shared/components/AppButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { useToast } from '../../../shared/components/AppToast';
import { SeeAllScaffold } from '../../../shared/components/SeeAllScaffold';
import { spacesApi } from '../data/spacesApi';
import { sortSpaces } from '../logic/spaceLogic';
import type { Space, SpacePage } from '../models/spaceModels';
import { SpaceGridCard } from './SpaceCards';
import { JoinSpaceDialog } from './SpaceModals';

export function PinnedSpacesSeeAllView() {
  const { showToast } = useToast();
  const [spaces, setSpaces] = useState<Space[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    spacesApi
      .listSpaces()
      .then((list) => setSpaces(list.filter((s) => s.isPinned)))
      .finally(() => setLoading(false));
  }, []);

  const handleTogglePin = async (space: Space) => {
    await spacesApi.togglePinSpace(space.id, !space.isPinned);
    setSpaces((prev) => prev.filter((s) => s.id !== space.id));
    showToast(`Unpinned "${space.title}"`, 'success');
  };

  return (
    <SeeAllScaffold title="Pinned spaces" subtitle="Your quick-access workspaces">
      {loading ? (
        <p className="type-body-md text-[var(--eduma-text-muted)]">Loading…</p>
      ) : spaces.length === 0 ? (
        <AppEmptyState
          iconName="pin"
          title="No pinned spaces"
          description="Pin any space from Home to keep it within one tap."
        />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {spaces.map((s) => (
            <SpaceGridCard key={s.id} space={s} onTogglePin={handleTogglePin} />
          ))}
        </div>
      )}
    </SeeAllScaffold>
  );
}

export function RecentSpacesSeeAllView() {
  const { showToast } = useToast();
  const [spaces, setSpaces] = useState<Space[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    spacesApi
      .listSpaces()
      .then((list) => setSpaces(sortSpaces(list, 'recent')))
      .finally(() => setLoading(false));
  }, []);

  const handleTogglePin = async (space: Space) => {
    const nextPin = !space.isPinned;
    await spacesApi.togglePinSpace(space.id, nextPin);
    setSpaces((prev) =>
      prev.map((s) => (s.id === space.id ? { ...s, isPinned: nextPin } : s))
    );
    showToast(nextPin ? `Pinned "${space.title}"` : `Unpinned "${space.title}"`, 'success');
  };

  return (
    <SeeAllScaffold title="All study spaces" subtitle="Sorted by most recently active">
      {loading ? (
        <p className="type-body-md text-[var(--eduma-text-muted)]">Loading…</p>
      ) : spaces.length === 0 ? (
        <AppEmptyState title="No study spaces yet" />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {spaces.map((s) => (
            <SpaceGridCard key={s.id} space={s} onTogglePin={handleTogglePin} />
          ))}
        </div>
      )}
    </SeeAllScaffold>
  );
}

export function RecentCanvasesSeeAllView() {
  const [pages, setPages] = useState<SpacePage[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    spacesApi
      .listRecentPages(30)
      .then(setPages)
      .finally(() => setLoading(false));
  }, []);

  return (
    <SeeAllScaffold title="Recent pages" subtitle="Pages you opened recently">
      {loading ? (
        <p className="type-body-md text-[var(--eduma-text-muted)]">Loading…</p>
      ) : pages.length === 0 ? (
        <AppEmptyState
          iconName="canvas"
          title="No recent pages"
          description="Open any page inside a space to see it here."
        />
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {pages.map((page) => (
            <Link
              key={`${page.spaceId}-${page.id}`}
              to={`/spacePageStatic?id=${encodeURIComponent(
                page.id
              )}&spaceId=${encodeURIComponent(page.spaceId)}`}
              className="eduma-card-surface flex items-center justify-between gap-3 rounded-[18px] p-4 transition hover:border-[var(--eduma-primary)]/40"
            >
              <div className="flex min-w-0 items-center gap-3">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]">
                  <EdumaIcon family="huge-stroke" name="canvas" size={20} />
                </div>
                <div className="min-w-0">
                  <p className="type-title-md truncate text-[var(--eduma-text-primary)]">
                    {page.title}
                  </p>
                  <p className="type-body-sm truncate text-[var(--eduma-text-muted)]">
                    {page.spaceTitle || 'Study Space'} ·{' '}
                    {formatRelativeTime(page.lastOpenedAt || page.updatedAt)}
                  </p>
                </div>
              </div>
              <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
            </Link>
          ))}
        </div>
      )}
    </SeeAllScaffold>
  );
}

export function JoinByInviteRouteView() {
  const { code = '' } = useParams();
  const navigate = useNavigate();

  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--eduma-bg)] p-4">
      <JoinSpaceDialog
        open
        initialCode={code}
        onClose={() => navigate('/main', { replace: true })}
      />
      <div className="text-center">
        <AppButton variant="secondary" onClick={() => navigate('/main')}>
          Back to Spaces
        </AppButton>
      </div>
    </div>
  );
}
