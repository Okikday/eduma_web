import React, { useCallback, useEffect, useRef, useState } from 'react';
import { normalizeApiUrl } from '../../../core/config/appConfig';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { formatRelativeTime } from '../../../core/utils/dateFormatters';
import { AdaptiveImage } from '../../../shared/components/AdaptiveImage';
import { AppButton } from '../../../shared/components/AppButton';
import { AppCircleIconButton } from '../../../shared/components/AppCircleIconButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { AppModalDialog } from '../../../shared/components/AppModalDialog';
import { AppSegmentedControl } from '../../../shared/components/AppSegmentedControl';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useToast } from '../../../shared/components/AppToast';
import {
  DesktopActionButton,
  DesktopPinnedPageHeader,
} from '../../../shared/components/DesktopPageHeader';
import { DesktopWidths, useFormFactor } from '../../../shared/components/formFactor';
import { MainShell } from '../../main/shell/MainShell';
import { libraryApi } from '../data/libraryApi';
import type {
  LibraryDocument,
  LibraryGroup,
  LibraryShelfFilter,
  LibrarySortOption,
} from '../models/libraryModels';
import { LibraryBookCard } from './LibraryBookCard';

export function LibraryView() {
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();
  const deviceFileInputRef = useRef<HTMLInputElement | null>(null);
  const [shelf, setShelf] = useState<LibraryShelfFilter>('all');
  const [sort, setSort] = useState<LibrarySortOption>('popular');
  const [query, setQuery] = useState('');

  const [documents, setDocuments] = useState<LibraryDocument[]>([]);
  const [recents, setRecents] = useState<LibraryDocument[]>([]);
  const [groups, setGroups] = useState<LibraryGroup[]>([]);
  const [loading, setLoading] = useState(true);

  const [activeDoc, setActiveDoc] = useState<LibraryDocument | null>(null);
  const [pageDraft, setPageDraft] = useState<string>('1');
  const [groupOpen, setGroupOpen] = useState(false);
  const [groupName, setGroupName] = useState('');

  const loadLibrary = useCallback(async () => {
    setLoading(true);
    try {
      const [docsRes, recentsRes, groupsRes] = await Promise.all([
        shelf === 'saved'
          ? libraryApi.listSaved().catch(() => [] as LibraryDocument[])
          : libraryApi
              .listDocuments({
                query,
                shelf: shelf === 'all' ? undefined : shelf,
                sort,
              })
              .catch(() => [] as LibraryDocument[]),
        libraryApi.listRecents().catch(() => [] as LibraryDocument[]),
        libraryApi.listGroups().catch(() => [] as LibraryGroup[]),
      ]);
      setDocuments(docsRes);
      setRecents(recentsRes);
      setGroups(groupsRes);
    } finally {
      setLoading(false);
    }
  }, [query, shelf, sort]);

  useEffect(() => {
    const timer = window.setTimeout(loadLibrary, query ? 260 : 0);
    return () => window.clearTimeout(timer);
  }, [loadLibrary, query]);

  const handleOpenBook = (doc: LibraryDocument) => {
    setActiveDoc(doc);
    setPageDraft(String(doc.currentPage ?? 1));
    libraryApi.recordOpened(doc.id);
  };

  const handleToggleSave = async (doc: LibraryDocument) => {
    const next = !doc.isSaved;
    setDocuments((prev) =>
      prev.map((d) => (d.id === doc.id ? { ...d, isSaved: next } : d))
    );
    try {
      await libraryApi.toggleSave(doc.id, next);
      showToast(next ? 'Saved to library' : 'Removed from saved', 'success');
    } catch {
      setDocuments((prev) =>
        prev.map((d) => (d.id === doc.id ? { ...d, isSaved: !next } : d))
      );
    }
  };

  const handleSaveProgress = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeDoc) return;
    const pageNum = Math.max(1, Number(pageDraft) || 1);
    const pct =
      activeDoc.pageCount && activeDoc.pageCount > 0
        ? Math.min(100, Math.round((pageNum / activeDoc.pageCount) * 100))
        : Math.min(100, (activeDoc.progressPercent ?? 0) + 10);

    try {
      await libraryApi.updateProgress(activeDoc.id, {
        currentPage: pageNum,
        progressPercent: pct,
      });
      setDocuments((prev) =>
        prev.map((d) =>
          d.id === activeDoc.id
            ? { ...d, currentPage: pageNum, progressPercent: pct }
            : d
        )
      );
      showToast('Reading progress saved.', 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Unable to save progress.', 'error');
    }
  };

  const handleCreateGroup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!groupName.trim()) return;
    const id =
      typeof crypto !== 'undefined' && crypto.randomUUID
        ? crypto.randomUUID()
        : `grp-${Date.now()}`;
    await libraryApi.saveGroup(id, groupName.trim(), []);
    setGroupName('');
    setGroupOpen(false);
    showToast('Reading list created.', 'success');
    loadLibrary();
  };

  const handlePickDeviceFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    const objectUrl = URL.createObjectURL(file);
    window.open(objectUrl, '_blank', 'noopener,noreferrer');
    showToast(`Opened ${file.name}.`, 'info');
  };

  return (
    <MainShell activeTab="library">
      <input
        ref={deviceFileInputRef}
        type="file"
        accept=".pdf,.epub,.txt,application/pdf"
        className="hidden"
        onChange={handlePickDeviceFile}
      />
      {isExpanded ? (
        <DesktopPinnedPageHeader
          title="Library"
          subtitle="Explore vast collections of books"
          actions={
            <>
              <AppCircleIconButton
                size={42}
                label="Refresh library"
                onClick={() => void loadLibrary()}
              >
                <EdumaIcon family="iconsax" name="refresh_copy" size={18} />
              </AppCircleIconButton>
              <div className="flex h-[42px] w-[300px] items-center gap-2 rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 focus-within:border-[var(--eduma-primary)]">
                <EdumaIcon
                  family="huge-stroke"
                  name="search01"
                  size={17}
                  color="var(--eduma-text-muted)"
                />
                <input
                  type="search"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search textbooks & papers…"
                  aria-label="Search library"
                  className="w-full bg-transparent text-[13.5px] font-medium text-[var(--eduma-text-primary)] placeholder:text-[var(--eduma-text-muted)] focus:outline-none"
                />
              </div>
              <DesktopActionButton
                label="New group"
                icon={<EdumaIcon family="huge-stroke" name="folderAdd" size={16} />}
                onClick={() => setGroupOpen(true)}
              />
              <DesktopActionButton
                label="From device"
                variant="filled"
                icon={<EdumaIcon family="huge-stroke" name="fileAdd" size={16} />}
                onClick={() => deviceFileInputRef.current?.click()}
              />
            </>
          }
        />
      ) : null}

      <div className={isExpanded ? 'w-full px-8 pb-10 pt-2' : 'mx-auto w-full max-w-[1100px] px-4 py-5 sm:px-6'}>
        {!isExpanded ? (
          <header className="mb-6 flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="type-display-sm text-[var(--eduma-text-primary)]">
                Library
              </h1>
              <p className="type-body-sm mt-0.5 text-[var(--eduma-text-muted)]">
                Explore vast collections of books
              </p>
            </div>

            <div className="flex items-center gap-2">
              <AppButton
                variant="secondary"
                size="sm"
                onClick={() => setGroupOpen(true)}
                leadingIcon={<EdumaIcon family="huge-stroke" name="folderAdd" size={16} />}
              >
                New group
              </AppButton>
              <AppButton
                size="sm"
                onClick={() => deviceFileInputRef.current?.click()}
                leadingIcon={<EdumaIcon family="huge-stroke" name="fileAdd" size={16} />}
              >
                From device
              </AppButton>
            </div>
          </header>
        ) : null}

        {/* Continue reading strip */}
        {recents.length > 0 && !query ? (
          <section className="mb-7">
            <h2 className="type-title-md mb-3 text-[var(--eduma-text-primary)]">
              Continue reading
            </h2>
            <div className="no-scrollbar flex gap-3 overflow-x-auto pb-2">
              {recents.slice(0, 8).map((doc) => (
                <button
                  key={doc.id}
                  type="button"
                  onClick={() => handleOpenBook(doc)}
                  className="eduma-card-surface flex w-64 shrink-0 cursor-pointer items-center gap-3 rounded-[18px] p-3 text-left transition hover:border-[var(--eduma-primary)]/40"
                >
                  <div className="h-14 w-11 shrink-0 overflow-hidden rounded-[10px] border border-[var(--eduma-border)]">
                    <AdaptiveImage
                      src={doc.coverUrl}
                      alt={doc.title}
                      className="h-full w-full object-cover"
                      fallback={
                        <div className="flex h-full w-full items-center justify-center bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]">
                          <EdumaIcon family="huge-stroke" name="bookOpen01" size={16} />
                        </div>
                      }
                    />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="type-title-sm truncate text-[var(--eduma-text-primary)]">
                      {doc.title}
                    </p>
                    <p className="type-body-sm text-[var(--eduma-text-muted)]">
                      {Math.round(doc.progressPercent ?? 0)}% complete
                    </p>
                  </div>
                </button>
              ))}
            </div>
          </section>
        ) : null}

        {/* Custom reading groups pills */}
        {groups.length > 0 ? (
          <div className="mb-5 flex flex-wrap items-center gap-2">
            {groups.map((grp) => (
              <span
                key={grp.id}
                className="inline-flex items-center gap-2 rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3 py-1 text-[12.5px] font-semibold text-[var(--eduma-text-primary)]"
              >
                <EdumaIcon family="huge-stroke" name="folderLibrary" size={14} color="var(--eduma-primary)" />
                <span>{grp.name}</span>
                <span className="text-[var(--eduma-text-muted)]">
                  ({grp.documentIds.length})
                </span>
              </span>
            ))}
          </div>
        ) : null}

        {/* Search + Filter row */}
        <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
          <AppSegmentedControl
            value={shelf}
            onChange={setShelf}
            options={[
              { value: 'all', label: 'Explore' },
              { value: 'for_you', label: 'For You' },
              { value: 'popular', label: 'Trending' },
              { value: 'saved', label: 'Saved' },
            ]}
          />

          <div className="flex flex-wrap items-center gap-2.5">
            {!isExpanded ? (
              <div className="flex min-w-[210px] items-center gap-2 rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3 py-2 focus-within:border-[var(--eduma-primary)]">
                <EdumaIcon
                  family="huge-stroke"
                  name="search01"
                  size={17}
                  color="var(--eduma-text-muted)"
                />
                <input
                  type="search"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search textbooks & papers…"
                  className="w-full bg-transparent text-[14px] font-medium focus:outline-none"
                />
              </div>
            ) : null}

            <select
              aria-label="Sort library"
              value={sort}
              onChange={(e) => setSort(e.target.value as LibrarySortOption)}
              className="h-10 rounded-[13px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3 text-[13.5px] font-semibold text-[var(--eduma-text-primary)]"
            >
              <option value="popular">Popular</option>
              <option value="recent">Recent</option>
              <option value="title">Title A–Z</option>
            </select>
          </div>
        </div>

        {/* Document Catalog Grid */}
        {loading ? (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {[1, 2, 3, 4, 5, 6, 7, 8].map((n) => (
              <div
                key={n}
                className="h-64 animate-pulse rounded-[22px] bg-[var(--eduma-surface)]"
              />
            ))}
          </div>
        ) : documents.length === 0 ? (
          <AppEmptyState
            iconName="bookOpen01"
            title="No documents found"
            description="Try a different shelf filter or search query."
          />
        ) : (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {documents.map((doc) => (
              <LibraryBookCard
                key={doc.id}
                doc={doc}
                onOpen={handleOpenBook}
                onToggleSave={handleToggleSave}
              />
            ))}
          </div>
        )}
      </div>

      {/* Document Reader & Progress Modal */}
      <AppModalDialog
        open={Boolean(activeDoc)}
        onClose={() => setActiveDoc(null)}
        title={activeDoc?.title || 'Document'}
        subtitle={
          activeDoc
            ? [
                activeDoc.author,
                activeDoc.category,
                activeDoc.updatedAt ? formatRelativeTime(activeDoc.updatedAt) : null,
              ]
                .filter(Boolean)
                .join(' · ')
            : ''
        }
        maxWidth={DesktopWidths.page}
      >
        {activeDoc ? (
          <div className="space-y-4">
            {activeDoc.description ? (
              <p className="type-body-md text-[var(--eduma-text-secondary)]">
                {activeDoc.description}
              </p>
            ) : null}

            {activeDoc.fileUrl ? (
              <div className="overflow-hidden rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)]">
                <iframe
                  title={activeDoc.title}
                  src={normalizeApiUrl(activeDoc.fileUrl)}
                  className="h-[52dvh] w-full"
                />
              </div>
            ) : null}

            <form
              onSubmit={handleSaveProgress}
              className="flex flex-wrap items-end justify-between gap-3 rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)]/60 p-3.5"
            >
              <div className="w-36">
                <AppTextFormField
                  label="Current page"
                  type="number"
                  min={1}
                  max={activeDoc.pageCount || undefined}
                  value={pageDraft}
                  onChange={(e) => setPageDraft(e.target.value)}
                />
              </div>

              <div className="flex flex-wrap items-center gap-2">
                {activeDoc.fileUrl ? (
                  <a
                    href={normalizeApiUrl(activeDoc.fileUrl)}
                    target="_blank"
                    rel="noreferrer"
                  >
                    <AppButton variant="secondary" size="sm">
                      Open PDF tab
                    </AppButton>
                  </a>
                ) : null}
                <AppButton type="submit" size="sm">
                  Save progress
                </AppButton>
              </div>
            </form>
          </div>
        ) : null}
      </AppModalDialog>

      {/* New Reading Shelf Modal */}
      <AppModalDialog
        open={groupOpen}
        onClose={() => setGroupOpen(false)}
        title="New reading shelf"
      >
        <form onSubmit={handleCreateGroup} className="flex flex-col gap-4">
          <AppTextFormField
            label="Shelf name"
            placeholder="e.g. Finals Revision"
            autoFocus
            required
            value={groupName}
            onChange={(e) => setGroupName(e.target.value)}
          />
          <div className="flex justify-end gap-2">
            <AppButton variant="ghost" onClick={() => setGroupOpen(false)}>
              Cancel
            </AppButton>
            <AppButton type="submit" disabled={!groupName.trim()}>
              Create shelf
            </AppButton>
          </div>
        </form>
      </AppModalDialog>
    </MainShell>
  );
}
