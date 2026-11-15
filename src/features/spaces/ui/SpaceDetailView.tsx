import React, { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { apiClient } from '../../../core/api/apiClient';
import { normalizeApiUrl } from '../../../core/config/appConfig';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { formatRelativeTime, formatTimeRange } from '../../../core/utils/dateFormatters';
import { AppButton } from '../../../shared/components/AppButton';
import { AppCircleIconButton } from '../../../shared/components/AppCircleIconButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { AppModalDialog } from '../../../shared/components/AppModalDialog';
import { AppSegmentedControl } from '../../../shared/components/AppSegmentedControl';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useToast } from '../../../shared/components/AppToast';
import { UserAvatar } from '../../../shared/components/BadgesAndAvatars';
import { DesktopSplitScaffold } from '../../../shared/components/DesktopSplitScaffold';
import { FloatingContextMenu } from '../../../shared/components/FloatingContextMenu';
import { useFormFactor } from '../../../shared/components/formFactor';
import { PureAppBar } from '../../../shared/components/PureAppBar';
import { spacesApi } from '../data/spacesApi';
import type { Space, SpaceAsset, SpaceMember, SpacePage } from '../models/spaceModels';
import { SpaceDesktopHero } from './SpaceDesktopHero';
import { SpaceDesktopToolbar } from './SpaceDesktopToolbar';

type DetailTab = 'pages' | 'assets' | 'events' | 'members';

interface SpaceEvent {
  id: string;
  title: string;
  startTime: string;
  endTime?: string | null;
}

export function SpaceDetailView() {
  const { id: paramId } = useParams();
  const [searchParams] = useSearchParams();
  const spaceId = paramId || searchParams.get('id') || '';
  const initialTab = (searchParams.get('tab') as DetailTab | null) || 'pages';

  const navigate = useNavigate();
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();

  const [space, setSpace] = useState<Space | null>(null);
  const [pages, setPages] = useState<SpacePage[]>([]);
  const [assets, setAssets] = useState<SpaceAsset[]>([]);
  const [events, setEvents] = useState<SpaceEvent[]>([]);
  const [tab, setTab] = useState<DetailTab>(initialTab);
  const [itemFilter, setItemFilter] = useState('');
  const [loading, setLoading] = useState(true);

  // Modals
  const [newPageOpen, setNewPageOpen] = useState(false);
  const [newPageTitle, setNewPageTitle] = useState('');
  const [inviteOpen, setInviteOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [editTitle, setEditTitle] = useState('');
  const [editDesc, setEditDesc] = useState('');
  const [memberQuery, setMemberQuery] = useState('');
  const [searchResults, setSearchResults] = useState<SpaceMember[]>([]);
  const [busy, setBusy] = useState(false);

  const loadAll = useCallback(async () => {
    if (!spaceId) return;
    setLoading(true);
    try {
      const [detail, pagesList, assetsList, evRes] = await Promise.all([
        spacesApi.getSpaceDetail(spaceId),
        spacesApi.listSpacePages(spaceId).catch(() => [] as SpacePage[]),
        spacesApi.listSpaceAssets(spaceId).catch(() => [] as SpaceAsset[]),
        apiClient
          .get<{ events?: Record<string, unknown>[]; items?: Record<string, unknown>[] }>(
            '/events',
            { params: { spaceId, limit: 30 } }
          )
          .catch(() => null),
      ]);
      setSpace(detail);
      setEditTitle(detail.title);
      setEditDesc(detail.description || '');
      setPages(pagesList.length > 0 ? pagesList : detail.pages || []);
      setAssets(assetsList);

      const rawEv = Array.isArray(evRes)
        ? evRes
        : Array.isArray(evRes?.events)
        ? evRes.events
        : Array.isArray(evRes?.items)
        ? evRes.items
        : [];
      setEvents(
        rawEv.map((e) => ({
          id: String(e.id || e._id || ''),
          title: String(e.title || 'Space Event'),
          startTime: String(e.startTime || e.start || ''),
          endTime: typeof e.endTime === 'string' ? e.endTime : null,
        }))
      );
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to load space.',
        'error'
      );
    } finally {
      setLoading(false);
    }
  }, [spaceId, showToast]);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  useEffect(() => {
    if (!inviteOpen || memberQuery.trim().length < 2) {
      setSearchResults([]);
      return;
    }
    const timer = window.setTimeout(async () => {
      try {
        const res = await spacesApi.searchUsers(memberQuery.trim(), spaceId);
        setSearchResults(res);
      } catch {
        setSearchResults([]);
      }
    }, 320);
    return () => window.clearTimeout(timer);
  }, [inviteOpen, memberQuery, spaceId]);

  const handleTogglePinSpace = async () => {
    if (!space) return;
    const nextPin = !space.isPinned;
    await spacesApi.togglePinSpace(space.id, nextPin);
    setSpace({ ...space, isPinned: nextPin });
    showToast(nextPin ? 'Pinned space' : 'Unpinned space', 'success');
  };

  const handleCreatePage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!space || !newPageTitle.trim()) return;
    setBusy(true);
    try {
      const created = await spacesApi.createPage(space.id, newPageTitle.trim());
      setPages((prev) => [created, ...prev]);
      setNewPageTitle('');
      setNewPageOpen(false);
      showToast(`Created page "${created.title}"`, 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Unable to create page.', 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleTogglePinPage = async (page: SpacePage) => {
    if (!space) return;
    const updated = pages.map((p) =>
      p.id === page.id ? { ...p, isPinned: !p.isPinned } : p
    );
    setPages(updated);
    try {
      const pinnedIds = updated.filter((p) => p.isPinned).map((p) => p.id);
      await spacesApi.savePinnedPages(space.id, pinnedIds);
      showToast(page.isPinned ? 'Unpinned page' : 'Pinned page', 'success');
    } catch {
      setPages(pages);
    }
  };

  const handleDuplicatePage = async (page: SpacePage) => {
    if (!space) return;
    try {
      const copy = await spacesApi.duplicatePage(space.id, page.id);
      setPages((prev) => [copy, ...prev]);
      showToast(`Duplicated "${page.title}"`, 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Unable to duplicate page.', 'error');
    }
  };

  const handleDeletePage = async (page: SpacePage) => {
    if (!space || !window.confirm(`Delete page "${page.title}"?`)) return;
    await spacesApi.deletePage(space.id, page.id);
    setPages((prev) => prev.filter((p) => p.id !== page.id));
    showToast('Page deleted.', 'success');
  };

  const handleAssetUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !space) return;
    setBusy(true);
    try {
      const created = await spacesApi.uploadAndAttachAsset(space.id, file);
      setAssets((prev) => [created, ...prev]);
      showToast(`Uploaded ${file.name}`, 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Upload failed.', 'error');
    } finally {
      setBusy(false);
      e.target.value = '';
    }
  };

  const handleInviteMember = async (member: SpaceMember) => {
    if (!space) return;
    try {
      await spacesApi.inviteUsersToSpace(space.id, [member.userId || member.id]);
      showToast(`Invited ${member.name}`, 'success');
      setSearchResults((prev) => prev.filter((m) => m.id !== member.id));
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Invite failed.', 'error');
    }
  };

  const handleCopyInviteLink = async () => {
    if (!space) return;
    let code = space.inviteCode;
    if (!code) {
      code = await spacesApi.regenerateInviteCode(space.id);
      setSpace({ ...space, inviteCode: code });
    }
    const link = `${window.location.origin}/join/${encodeURIComponent(code)}`;
    await navigator.clipboard.writeText(link).catch(() => null);
    showToast('Invite link copied!', 'success');
  };

  const handleSaveSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!space || !editTitle.trim()) return;
    setBusy(true);
    try {
      const updated = await spacesApi.updateSpace(space.id, {
        title: editTitle.trim(),
        description: editDesc.trim(),
      });
      setSpace(updated);
      setSettingsOpen(false);
      showToast('Space updated.', 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Update failed.', 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleCoverUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !space) return;
    try {
      const updated = await spacesApi.uploadSpaceCover(space.id, file);
      setSpace(updated);
      showToast('Cover photo updated.', 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Failed to upload cover.', 'error');
    }
  };

  const handleDeleteSpace = async () => {
    if (!space || !window.confirm(`Delete "${space.title}" permanently?`)) return;
    await spacesApi.deleteSpace(space.id);
    showToast('Space deleted.', 'success');
    navigate('/main', { replace: true });
  };

  if (!spaceId) {
    return (
      <div className="p-8">
        <AppEmptyState
          title="No space selected"
          action={<AppButton onClick={() => navigate('/main')}>Go Home</AppButton>}
        />
      </div>
    );
  }

  const normalizedFilter = itemFilter.trim().toLowerCase();
  const visiblePages = normalizedFilter
    ? pages.filter((p) => (p.title || '').toLowerCase().includes(normalizedFilter))
    : pages;
  const visibleAssets = normalizedFilter
    ? assets.filter((a) =>
        `${a.title || ''} ${a.name || ''}`.toLowerCase().includes(normalizedFilter)
      )
    : assets;
  const visibleEvents = normalizedFilter
    ? events.filter((ev) => (ev.title || '').toLowerCase().includes(normalizedFilter))
    : events;
  const archivedPagesCount = pages.filter((p) => p.isArchived).length;
  const desktopTab: 'pages' | 'assets' | 'events' =
    tab === 'assets' || tab === 'events' ? tab : 'pages';

  const content = (
    <div>
      {!isExpanded ? (
        <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <AppSegmentedControl
          value={tab}
          onChange={setTab}
          options={[
            { value: 'pages', label: 'Pages', count: pages.length },
            { value: 'assets', label: 'Assets', count: assets.length },
            { value: 'events', label: 'Events', count: events.length },
            {
              value: 'members',
              label: 'Members',
              count: space?.members.length ?? space?.membersCount ?? 0,
            },
          ]}
        />

        <div className="flex items-center gap-2">
          {tab === 'pages' ? (
            <AppButton
              size="sm"
              onClick={() => setNewPageOpen(true)}
              leadingIcon={<EdumaIcon family="huge-stroke" name="add01" size={16} />}
            >
              New page
            </AppButton>
          ) : null}

          {tab === 'assets' ? (
            <label className="inline-flex cursor-pointer items-center gap-2 rounded-[11px] bg-[var(--eduma-primary)] px-3.5 py-2 text-[13px] font-semibold text-white">
              <EdumaIcon family="huge-stroke" name="fileAdd" size={16} />
              <span>Upload asset</span>
              <input
                type="file"
                onChange={handleAssetUpload}
                className="sr-only"
              />
            </label>
          ) : null}

          {tab === 'members' ? (
            <AppButton
              size="sm"
              onClick={() => setInviteOpen(true)}
              leadingIcon={<EdumaIcon family="huge-stroke" name="addTeam" size={16} />}
            >
              Invite
            </AppButton>
          ) : null}
        </div>
        </div>
      ) : null}

      {loading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((n) => (
            <div
              key={n}
              className="h-20 animate-pulse rounded-[18px] bg-[var(--eduma-surface)]/80"
            />
          ))}
        </div>
      ) : null}

      {!loading && tab === 'pages' ? (
        visiblePages.length === 0 ? (
          <AppEmptyState
            iconName="note01"
            title={normalizedFilter ? 'No matching pages' : 'No pages yet'}
            description={
              normalizedFilter
                ? 'No pages match your filter query.'
                : 'Create a structured notes page or open it in Flutter Canvas for freehand work.'
            }
            action={
              normalizedFilter ? (
                <AppButton variant="secondary" onClick={() => setItemFilter('')}>
                  Clear filter
                </AppButton>
              ) : (
                <AppButton onClick={() => setNewPageOpen(true)}>Create first page</AppButton>
              )
            }
          />
        ) : (
          <div className="space-y-2.5">
            {visiblePages.map((page) => (
              <div
                key={page.id}
                className="eduma-card-surface flex items-center justify-between gap-3 rounded-[18px] p-3.5"
              >
                <Link
                  to={`/spacePageStatic?id=${encodeURIComponent(
                    page.id
                  )}&spaceId=${encodeURIComponent(spaceId)}`}
                  className="flex min-w-0 flex-1 items-center gap-3.5"
                >
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]">
                    <EdumaIcon
                      family="huge-stroke"
                      name={page.pageType === 'canvas' ? 'canvas' : 'note01'}
                      size={20}
                    />
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className="type-title-md truncate text-[var(--eduma-text-primary)]">
                        {page.title}
                      </h3>
                      {page.isPinned ? (
                        <EdumaIcon
                          family="huge-solid"
                          name="pin"
                          size={13}
                          color="var(--eduma-primary)"
                        />
                      ) : null}
                    </div>
                    <p className="type-body-sm text-[var(--eduma-text-muted)]">
                      {page.updatedAt ? `Updated ${formatRelativeTime(page.updatedAt)}` : 'Open to view & edit'}
                    </p>
                  </div>
                </Link>

                <FloatingContextMenu
                  trigger={({ onClick }) => (
                    <AppCircleIconButton label="Page options" size={34} onClick={onClick}>
                      <EdumaIcon family="huge-stroke" name="moreVertical" size={16} />
                    </AppCircleIconButton>
                  )}
                  items={[
                    {
                      id: 'pin',
                      label: page.isPinned ? 'Unpin page' : 'Pin page',
                      onSelect: () => handleTogglePinPage(page),
                    },
                    {
                      id: 'dup',
                      label: 'Duplicate page',
                      onSelect: () => handleDuplicatePage(page),
                    },
                    {
                      id: 'del',
                      label: 'Delete page',
                      danger: true,
                      onSelect: () => handleDeletePage(page),
                    },
                  ]}
                />
              </div>
            ))}
          </div>
        )
      ) : null}

      {!loading && tab === 'assets' ? (
        visibleAssets.length === 0 ? (
          <AppEmptyState
            iconName="documentAttachment"
            title={normalizedFilter ? 'No matching assets' : 'No uploaded assets'}
            description={
              normalizedFilter
                ? 'No assets match your filter query.'
                : 'Attach lecture slides, PDFs, or images to keep study files close by.'
            }
          />
        ) : (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            {visibleAssets.map((asset) => (
              <div
                key={asset.id}
                className="eduma-card-surface flex items-center justify-between gap-3 rounded-[18px] p-3.5"
              >
                <a
                  href={normalizeApiUrl(asset.url)}
                  target="_blank"
                  rel="noreferrer"
                  className="flex min-w-0 flex-1 items-center gap-3"
                >
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]">
                    <EdumaIcon family="huge-stroke" name="pdf01" size={18} />
                  </div>
                  <div className="min-w-0">
                    <p className="type-title-sm truncate text-[var(--eduma-text-primary)]">
                      {asset.title}
                    </p>
                    <p className="type-body-sm truncate text-[var(--eduma-text-muted)]">
                      {asset.mimeType || asset.type || 'File'}
                    </p>
                  </div>
                </a>

                <AppCircleIconButton
                  label="Remove asset"
                  size={34}
                  onClick={async () => {
                    await spacesApi.deleteSpaceAsset(spaceId, asset.id);
                    setAssets((prev) => prev.filter((a) => a.id !== asset.id));
                    showToast('Asset removed.', 'success');
                  }}
                >
                  <EdumaIcon family="huge-stroke" name="delete02" size={15} color="var(--eduma-error)" />
                </AppCircleIconButton>
              </div>
            ))}
          </div>
        )
      ) : null}

      {!loading && tab === 'events' ? (
        visibleEvents.length === 0 ? (
          <AppEmptyState
            iconName="calendar03"
            title={normalizedFilter ? 'No matching events' : 'No space events scheduled'}
            description={
              normalizedFilter
                ? 'No events match your filter query.'
                : 'Create a study session or exam reminder linked to this space.'
            }
            action={
              normalizedFilter ? (
                <AppButton variant="secondary" onClick={() => setItemFilter('')}>
                  Clear filter
                </AppButton>
              ) : (
                <Link to={`/calendarTab?create=1&spaceId=${encodeURIComponent(spaceId)}`}>
                  <AppButton>Schedule event</AppButton>
                </Link>
              )
            }
          />
        ) : (
          <div className="space-y-2.5">
            {visibleEvents.map((ev) => (
              <Link
                key={ev.id}
                to="/calendarTab"
                className="eduma-card-surface block rounded-[18px] p-4 transition hover:border-[var(--eduma-primary)]/40"
              >
                <p className="type-title-md text-[var(--eduma-text-primary)]">
                  {ev.title}
                </p>
                <p className="type-body-sm mt-1 text-[var(--eduma-text-muted)]">
                  {formatTimeRange(ev.startTime, ev.endTime)}
                </p>
              </Link>
            ))}
          </div>
        )
      ) : null}

      {!loading && tab === 'members' ? (
        <div className="space-y-2.5">
          {(space?.members || []).map((member) => (
            <div
              key={member.id}
              className="eduma-card-surface flex items-center justify-between gap-3 rounded-[18px] p-3.5"
            >
              <div className="flex min-w-0 items-center gap-3">
                <UserAvatar person={member} size={40} />
                <div className="min-w-0">
                  <p className="type-title-sm truncate text-[var(--eduma-text-primary)]">
                    {member.name}
                  </p>
                  <p className="type-body-sm truncate text-[var(--eduma-text-muted)]">
                    {member.username ? `@${member.username}` : member.email || 'Member'}
                  </p>
                </div>
              </div>

              <span className="rounded-full bg-[var(--eduma-nav-pill)] px-2.5 py-1 text-[11.5px] font-bold capitalize text-[var(--eduma-primary)]">
                {member.role || 'member'}
              </span>
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );

  return (
    <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">
      {!isExpanded ? (
        <PureAppBar
          title={space?.title || 'Study Space'}
          subtitle={`${pages.length} pages · ${space?.membersCount ?? 0} members`}
          backTo="/main"
          trailing={
            <div className="flex items-center gap-1.5">
              <AppCircleIconButton label="Invite classmates" size={36} onClick={() => setInviteOpen(true)}>
                <EdumaIcon family="huge-stroke" name="addTeam" size={17} />
              </AppCircleIconButton>
              <AppCircleIconButton label="Space settings" size={36} onClick={() => setSettingsOpen(true)}>
                <EdumaIcon family="huge-stroke" name="settings02" size={17} />
              </AppCircleIconButton>
            </div>
          }
        />
      ) : null}

      {isExpanded ? (
        <DesktopSplitScaffold
          minBodyWidth={480}
          hero={
            <SpaceDesktopHero
              space={space}
              pagesCount={pages.length}
              archivedCount={archivedPagesCount}
              assetsCount={assets.length}
              eventsCount={events.length}
              onBack={() => navigate('/main')}
              onRefresh={() => void loadAll()}
              onTogglePin={() => void handleTogglePinSpace()}
              onOpenSettings={() => setSettingsOpen(true)}
              onInvite={() => setInviteOpen(true)}
              onSelectTab={(nextTab) => setTab(nextTab)}
            />
          }
          body={
            <div className="mx-auto flex h-full w-full max-w-[800px] flex-col">
              <SpaceDesktopToolbar
                tab={desktopTab}
                onTabChange={(nextTab) => setTab(nextTab)}
                itemFilter={itemFilter}
                onFilterChange={setItemFilter}
                onNewPage={() => setNewPageOpen(true)}
                onUploadAsset={handleAssetUpload}
                onNewEvent={() => navigate('/calendarTab?create=1')}
              />
              <div className="min-h-0 flex-1 overflow-y-auto px-7 py-6">{content}</div>
            </div>
          }
        />
      ) : (
        <div className="mx-auto max-w-3xl px-4 pt-4">{content}</div>
      )}

      {/* New Page Dialog */}
      <AppModalDialog
        open={newPageOpen}
        onClose={() => setNewPageOpen(false)}
        title="New page"
        subtitle="Add a structured note page to this space."
      >
        <form onSubmit={handleCreatePage} className="flex flex-col gap-4">
          <AppTextFormField
            label="Page title"
            placeholder="e.g. Week 4 — Thermodynamics"
            autoFocus
            required
            value={newPageTitle}
            onChange={(e) => setNewPageTitle(e.target.value)}
          />
          <div className="flex justify-end gap-2">
            <AppButton variant="ghost" onClick={() => setNewPageOpen(false)}>
              Cancel
            </AppButton>
            <AppButton type="submit" loading={busy} disabled={!newPageTitle.trim()}>
              Create page
            </AppButton>
          </div>
        </form>
      </AppModalDialog>

      {/* Invite Users Dialog */}
      <AppModalDialog
        open={inviteOpen}
        onClose={() => setInviteOpen(false)}
        title="Invite to space"
        subtitle="Search classmates by name or @username."
      >
        <div className="flex flex-col gap-4">
          <AppTextFormField
            label="Find Eduma users"
            placeholder="Search name or username…"
            autoFocus
            value={memberQuery}
            onChange={(e) => setMemberQuery(e.target.value)}
          />

          <div className="space-y-2">
            {searchResults.map((person) => (
              <div
                key={person.id}
                className="flex items-center justify-between gap-3 rounded-[14px] border border-[var(--eduma-border)] p-2.5"
              >
                <div className="flex min-w-0 items-center gap-2.5">
                  <UserAvatar person={person} size={34} />
                  <div className="min-w-0">
                    <p className="type-title-sm truncate">{person.name}</p>
                    {person.username ? (
                      <p className="type-body-sm truncate text-[var(--eduma-text-muted)]">
                        @{person.username}
                      </p>
                    ) : null}
                  </div>
                </div>
                <AppButton size="sm" onClick={() => handleInviteMember(person)}>
                  Invite
                </AppButton>
              </div>
            ))}
          </div>

          <div className="border-t border-[var(--eduma-border-subtle)] pt-3">
            <AppButton variant="secondary" fullWidth onClick={handleCopyInviteLink}>
              Copy shareable invite link
            </AppButton>
          </div>
        </div>
      </AppModalDialog>

      {/* Space Settings Dialog */}
      <AppModalDialog
        open={settingsOpen}
        onClose={() => setSettingsOpen(false)}
        title="Space settings"
      >
        <form onSubmit={handleSaveSettings} className="flex flex-col gap-4">
          <AppTextFormField
            label="Space name"
            required
            value={editTitle}
            onChange={(e) => setEditTitle(e.target.value)}
          />
          <div className="flex flex-col gap-1.5">
            <label
              htmlFor="edit-space-desc"
              className="type-label-md text-[var(--eduma-text-secondary)]"
            >
              Description
            </label>
            <textarea
              id="edit-space-desc"
              rows={3}
              value={editDesc}
              onChange={(e) => setEditDesc(e.target.value)}
              className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 py-2.5 text-[14px]"
            />
          </div>

          <label className="inline-flex cursor-pointer items-center justify-center gap-2 rounded-[13px] border border-[var(--eduma-border)] bg-[var(--eduma-card)] px-4 py-2.5 text-[13.5px] font-semibold">
            <EdumaIcon family="huge-stroke" name="imageAdd02" size={17} />
            <span>Upload new cover photo</span>
            <input
              type="file"
              accept="image/*"
              onChange={handleCoverUpload}
              className="sr-only"
            />
          </label>

          <div className="mt-2 flex flex-wrap items-center justify-between gap-2 border-t border-[var(--eduma-border-subtle)] pt-4">
            {!space?.isPersonal ? (
              <AppButton variant="danger" size="sm" onClick={handleDeleteSpace}>
                Delete space
              </AppButton>
            ) : (
              <span />
            )}
            <div className="flex gap-2">
              <AppButton variant="ghost" onClick={() => setSettingsOpen(false)}>
                Cancel
              </AppButton>
              <AppButton type="submit" loading={busy}>
                Save changes
              </AppButton>
            </div>
          </div>
        </form>
      </AppModalDialog>
    </div>
  );
}
