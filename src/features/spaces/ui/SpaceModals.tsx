import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { AppModalDialog } from '../../../shared/components/AppModalDialog';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useToast } from '../../../shared/components/AppToast';
import { spacesApi } from '../data/spacesApi';
import { extractSpaceJoinCode } from '../logic/spaceLogic';
import type { Space, SpaceInvitePreview } from '../models/spaceModels';

export function CreateSpaceDialog({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated?: (space: Space) => void;
}) {
  const { showToast } = useToast();
  const navigate = useNavigate();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [subject, setSubject] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    try {
      const space = await spacesApi.createSpace({
        title: title.trim(),
        description: description.trim() || undefined,
        subject: subject.trim() || undefined,
      });
      showToast(`Created "${space.title}"`, 'success');
      setTitle('');
      setDescription('');
      setSubject('');
      AppSyncBus.emit('spaces:changed');
      onClose();
      onCreated?.(space);
      navigate(`/spaceDetail?id=${encodeURIComponent(space.id)}`);
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to create space.',
        'error'
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <AppModalDialog
      open={open}
      onClose={onClose}
      title="Create study space"
      subtitle="Keep related pages, PDFs, events, and classmates together."
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        <AppTextFormField
          label="Space name"
          placeholder="e.g. Organic Chemistry 201"
          autoFocus
          required
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />

        <AppTextFormField
          label="Subject or course code (optional)"
          placeholder="e.g. CHEM 201"
          value={subject}
          onChange={(e) => setSubject(e.target.value)}
        />

        <div className="flex flex-col gap-1.5">
          <label
            htmlFor="create-space-desc"
            className="type-label-md text-[var(--eduma-text-secondary)]"
          >
            Description (optional)
          </label>
          <textarea
            id="create-space-desc"
            rows={3}
            placeholder="What are you studying in this space?"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 py-2.5 text-[14.5px] font-medium text-[var(--eduma-text-primary)] outline-none focus:border-[var(--eduma-primary)]"
          />
        </div>

        <div className="mt-2 flex justify-end gap-2">
          <AppButton variant="ghost" onClick={onClose}>
            Cancel
          </AppButton>
          <AppButton type="submit" loading={saving} disabled={!title.trim()}>
            Create space
          </AppButton>
        </div>
      </form>
    </AppModalDialog>
  );
}

export function JoinSpaceDialog({
  open,
  onClose,
  initialCode = '',
}: {
  open: boolean;
  onClose: () => void;
  initialCode?: string;
}) {
  const { showToast } = useToast();
  const navigate = useNavigate();
  const [input, setInput] = useState(initialCode);
  const [preview, setPreview] = useState<SpaceInvitePreview | null>(null);
  const [checking, setChecking] = useState(false);
  const [joining, setJoining] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (initialCode) setInput(initialCode);
  }, [initialCode]);

  const code = extractSpaceJoinCode(input);

  useEffect(() => {
    if (!open || code.length < 4) {
      setPreview(null);
      setError(null);
      return;
    }
    let cancelled = false;
    setChecking(true);
    setError(null);
    const timer = window.setTimeout(async () => {
      try {
        const res = await spacesApi.previewInviteCode(code);
        if (!cancelled) setPreview(res);
      } catch {
        if (!cancelled) {
          setPreview(null);
          setError('No space matches that invite code.');
        }
      } finally {
        if (!cancelled) setChecking(false);
      }
    }, 380);
    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [code, open]);

  const handleJoin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!code) return;
    setJoining(true);
    try {
      const space = await spacesApi.joinByCode(code);
      showToast(`Joined "${space.title}"`, 'success');
      AppSyncBus.emit('spaces:changed');
      onClose();
      navigate(`/spaceDetail?id=${encodeURIComponent(space.id)}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to join space.');
    } finally {
      setJoining(false);
    }
  };

  return (
    <AppModalDialog
      open={open}
      onClose={onClose}
      title="Join a study space"
      subtitle="Enter an invite code or paste an Eduma space invite link."
    >
      <form onSubmit={handleJoin} className="flex flex-col gap-4">
        <AppTextFormField
          label="Invite code or link"
          placeholder="Paste code or https://app.eduma.com.ng/join/..."
          autoFocus
          required
          value={input}
          onChange={(e) => setInput(e.target.value)}
          leadingIcon={<EdumaIcon family="huge-stroke" name="link01" size={18} />}
        />

        {checking ? (
          <p className="type-body-sm text-[var(--eduma-text-muted)]">
            Looking up invite…
          </p>
        ) : preview ? (
          <div className="rounded-[16px] border border-[var(--eduma-primary)]/35 bg-[var(--eduma-nav-pill)] p-3.5">
            <p className="type-title-md text-[var(--eduma-text-primary)]">
              {preview.title}
            </p>
            {preview.description ? (
              <p className="type-body-sm mt-1 text-[var(--eduma-text-secondary)]">
                {preview.description}
              </p>
            ) : null}
            <p className="type-label-sm mt-2 text-[var(--eduma-primary)]">
              {preview.membersCount ?? 0} members · {preview.pagesCount ?? 0} pages
            </p>
          </div>
        ) : error ? (
          <p className="type-body-sm text-[var(--eduma-error)]">{error}</p>
        ) : null}

        <div className="mt-2 flex justify-end gap-2">
          <AppButton variant="ghost" onClick={onClose}>
            Cancel
          </AppButton>
          <AppButton type="submit" loading={joining} disabled={!code}>
            Join space
          </AppButton>
        </div>
      </form>
    </AppModalDialog>
  );
}
