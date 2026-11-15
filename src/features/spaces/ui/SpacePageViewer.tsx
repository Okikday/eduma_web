import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { buildFlutterCanvasUrl } from '../../../core/config/appConfig';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { useToast } from '../../../shared/components/AppToast';
import { DesktopPageHeader } from '../../../shared/components/DesktopPageHeader';
import { useFormFactor } from '../../../shared/components/formFactor';
import { PureAppBar } from '../../../shared/components/PureAppBar';
import { spacesApi } from '../data/spacesApi';
import { extractPagePlainText } from '../logic/spaceLogic';
import type { SpacePage } from '../models/spaceModels';

export function SpacePageViewer() {
  const [searchParams] = useSearchParams();
  const pageId = searchParams.get('id') || '';
  const spaceId = searchParams.get('spaceId') || '';
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();

  const [page, setPage] = useState<SpacePage | null>(null);
  const [titleDraft, setTitleDraft] = useState('');
  const [notesDraft, setNotesDraft] = useState('');
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!spaceId || !pageId) {
      setLoading(false);
      return;
    }
    spacesApi.recordPageOpened(spaceId, pageId);
    spacesApi
      .getPageDetail(spaceId, pageId)
      .then((res) => {
        setPage(res);
        setTitleDraft(res.title);
        setNotesDraft(extractPagePlainText(res));
      })
      .catch((err) => {
        showToast(
          err instanceof Error ? err.message : 'Unable to load page.',
          'error'
        );
      })
      .finally(() => setLoading(false));
  }, [spaceId, pageId, showToast]);

  const handleSave = async () => {
    if (!spaceId || !pageId) return;
    setSaving(true);
    try {
      if (titleDraft.trim() && titleDraft.trim() !== page?.title) {
        await spacesApi.updatePageMeta(spaceId, pageId, {
          title: titleDraft.trim(),
        });
      }
      const nextRaw = {
        ...(page?.rawContent || {}),
        sections: [
          {
            id: 'web-notes',
            title: titleDraft.trim() || 'Notes',
            text: notesDraft,
          },
        ],
      };
      const updated = await spacesApi.updatePageContent(
        spaceId,
        pageId,
        nextRaw
      );
      setPage(updated);
      showToast('Saved page notes to Eduma Cloud.', 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Save failed.', 'error');
    } finally {
      setSaving(false);
    }
  };

  const flutterCanvasUrl = buildFlutterCanvasUrl({ pageId, spaceId });
  const backPath = spaceId
    ? `/spaceDetail?id=${encodeURIComponent(spaceId)}`
    : '/main';

  const headerActions = (
    <div className="flex flex-wrap items-center gap-2">
      <a href={flutterCanvasUrl} target="_blank" rel="noreferrer">
        <AppButton
          variant="secondary"
          size="sm"
          leadingIcon={<EdumaIcon family="huge-stroke" name="canvas" size={16} />}
        >
          Open in Flutter Canvas
        </AppButton>
      </a>
      <AppButton size="sm" loading={saving} onClick={handleSave}>
        Save changes
      </AppButton>
    </div>
  );

  return (
    <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">
      {!isExpanded ? (
        <PureAppBar
          title={page?.title || 'Page viewer'}
          backTo={backPath}
          trailing={headerActions}
        />
      ) : null}

      <div className="mx-auto w-full max-w-[920px] px-4 py-6 sm:px-6">
        {isExpanded ? (
          <DesktopPageHeader
            title={page?.title || 'Study Page'}
            subtitle={page?.spaceTitle || 'Structured note view & Flutter Canvas handoff'}
            backTo={backPath}
            trailing={headerActions}
          />
        ) : null}

        {loading ? (
          <div className="h-64 animate-pulse rounded-[22px] bg-[var(--eduma-surface)]" />
        ) : (
          <div className="eduma-card-surface space-y-5 rounded-[24px] p-6">
            <div>
              <label
                htmlFor="page-title-input"
                className="type-label-md text-[var(--eduma-text-muted)]"
              >
                Page Title
              </label>
              <input
                id="page-title-input"
                value={titleDraft}
                onChange={(e) => setTitleDraft(e.target.value)}
                className="type-headline-md mt-1 w-full bg-transparent text-[var(--eduma-text-primary)] outline-none focus:text-[var(--eduma-primary)]"
              />
            </div>

            {page?.sections && page.sections.length > 0 ? (
              <div className="space-y-3 border-t border-[var(--eduma-border-subtle)] pt-4">
                <p className="type-label-md text-[var(--eduma-text-muted)]">
                  Page sections
                </p>
                {page.sections.map((sec, idx) => (
                  <div
                    key={sec.id || idx}
                    className="rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)]/50 p-4"
                  >
                    {sec.title ? (
                      <h3 className="type-title-md text-[var(--eduma-text-primary)]">
                        {sec.title}
                      </h3>
                    ) : null}
                    {sec.text || sec.content ? (
                      <p className="type-body-md mt-1 whitespace-pre-wrap text-[var(--eduma-text-secondary)]">
                        {sec.text || sec.content}
                      </p>
                    ) : null}
                  </div>
                ))}
              </div>
            ) : null}

            <div className="border-t border-[var(--eduma-border-subtle)] pt-4">
              <label
                htmlFor="page-notes-textarea"
                className="type-label-md text-[var(--eduma-text-muted)]"
              >
                Quick Web Notes Editor
              </label>
              <textarea
                id="page-notes-textarea"
                rows={12}
                value={notesDraft}
                onChange={(e) => setNotesDraft(e.target.value)}
                placeholder="Write or refine your structured study notes here, or open this page in the Flutter Canvas for spatial sketching and PDF annotations."
                className="mt-2 w-full rounded-[16px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] p-4 text-[15px] leading-relaxed text-[var(--eduma-text-primary)] outline-none focus:border-[var(--eduma-primary)]"
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
