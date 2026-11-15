import React, { useCallback, useEffect, useState } from 'react';
import { apiClient } from '../../../core/api/apiClient';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { formatRelativeTime } from '../../../core/utils/dateFormatters';
import { AppButton } from '../../../shared/components/AppButton';
import { AppCircleIconButton } from '../../../shared/components/AppCircleIconButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { AppModalDialog } from '../../../shared/components/AppModalDialog';
import { useToast } from '../../../shared/components/AppToast';
import { DesktopPageHeader } from '../../../shared/components/DesktopPageHeader';
import { DesktopPopupFrame } from '../../../shared/components/DesktopPopupFrame';
import { DesktopWidths, useFormFactor } from '../../../shared/components/formFactor';
import { PureAppBar } from '../../../shared/components/PureAppBar';

interface AiSessionSummary {
  id: string;
  title: string;
  preview?: string;
  updatedAt?: string | null;
}

interface AiMessage {
  role: 'user' | 'assistant';
  content: string;
}

export function AssistantHistoryView() {
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();

  const [sessions, setSessions] = useState<AiSessionSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [promptInput, setPromptInput] = useState('');
  const [asking, setAsking] = useState(false);
  const [activeMessages, setActiveMessages] = useState<AiMessage[]>([]);
  const [activeTitle, setActiveTitle] = useState<string | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);

  const loadHistory = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiClient.get<{ items?: Record<string, unknown>[]; history?: Record<string, unknown>[] }>(
        '/ai/history'
      );
      const raw = Array.isArray(res)
        ? res
        : Array.isArray(res?.history)
        ? res.history
        : Array.isArray(res?.items)
        ? res.items
        : [];
      setSessions(
        raw.map((s) => ({
          id: String(s.id || s._id || ''),
          title: String(s.title || s.prompt || 'Study Session'),
          preview:
            typeof s.preview === 'string'
              ? s.preview
              : typeof s.summary === 'string'
              ? s.summary
              : undefined,
          updatedAt: typeof s.updatedAt === 'string' ? s.updatedAt : null,
        }))
      );
    } catch {
      setSessions([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadHistory();
  }, [loadHistory]);

  const handleOpenSession = async (session: AiSessionSummary) => {
    setActiveTitle(session.title);
    setDetailOpen(true);
    try {
      const res = await apiClient.get<{ messages?: Record<string, unknown>[] }>(
        `/ai/history/${encodeURIComponent(session.id)}`
      );
      const raw = Array.isArray(res?.messages) ? res.messages : [];
      setActiveMessages(
        raw.map((m) => ({
          role: m.role === 'user' ? 'user' : 'assistant',
          content: String(m.content || m.text || ''),
        }))
      );
    } catch {
      setActiveMessages([
        { role: 'assistant', content: session.preview || 'No messages cached.' },
      ]);
    }
  };

  const handleRename = async (session: AiSessionSummary) => {
    const next = window.prompt('Rename conversation:', session.title);
    if (!next?.trim()) return;
    await apiClient.put(`/ai/history/${encodeURIComponent(session.id)}`, {
      title: next.trim(),
    });
    setSessions((prev) =>
      prev.map((s) => (s.id === session.id ? { ...s, title: next.trim() } : s))
    );
  };

  const handleDelete = async (id: string) => {
    await apiClient.delete(`/ai/history/${encodeURIComponent(id)}`);
    setSessions((prev) => prev.filter((s) => s.id !== id));
    showToast('Conversation removed.', 'success');
  };

  const handleAsk = async (e: React.FormEvent) => {
    e.preventDefault();
    const q = promptInput.trim();
    if (!q) return;
    setAsking(true);
    setActiveTitle('Study Assistant');
    setActiveMessages([{ role: 'user', content: q }]);
    setDetailOpen(true);
    setPromptInput('');

    try {
      const res = await apiClient.post<Record<string, unknown>>('/ai/study-chat', {
        message: q,
        prompt: q,
      });
      const reply = String(
        res?.reply || res?.answer || res?.content || 'Response saved.'
      );
      setActiveMessages([
        { role: 'user', content: q },
        { role: 'assistant', content: reply },
      ]);
      loadHistory();
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to reach AI assistant.',
        'error'
      );
    } finally {
      setAsking(false);
    }
  };

  const historyContent = (
    <>
      {!isExpanded ? (
        <PureAppBar title="AI Assistant History" backTo="/main" />
      ) : null}

      <div className={isExpanded ? 'px-7 pb-8 pt-2' : 'mx-auto w-full max-w-[880px] px-4 py-6 sm:px-6'}>
        {isExpanded ? (
          <DesktopPageHeader
            title="AI Study Assistant"
            subtitle="Ask a quick study question or revisit past explanations"
            backTo="/main"
          />
        ) : null}

        <form
          onSubmit={handleAsk}
          className="eduma-card-surface mb-6 flex items-center gap-2 rounded-[18px] p-2.5"
        >
          <EdumaIcon
            family="huge-stroke"
            name="sparkles"
            size={20}
            color="var(--eduma-primary)"
            className="ml-2"
          />
          <input
            type="text"
            value={promptInput}
            onChange={(e) => setPromptInput(e.target.value)}
            placeholder="Ask Eduma AI to explain a concept or quiz you…"
            className="flex-1 bg-transparent px-2 py-2 text-[14.5px] font-medium focus:outline-none"
          />
          <AppButton type="submit" size="sm" loading={asking} disabled={!promptInput.trim()}>
            Ask AI
          </AppButton>
        </form>

        {loading ? (
          <p className="type-body-md text-[var(--eduma-text-muted)]">Loading…</p>
        ) : sessions.length === 0 ? (
          <AppEmptyState
            iconName="sparkles"
            title="No AI conversations yet"
            description="Ask a question above to start your first AI study conversation."
          />
        ) : (
          <div className="space-y-2.5">
            {sessions.map((s) => (
              <div
                key={s.id}
                className="eduma-card-surface flex items-center justify-between gap-3 rounded-[18px] p-4"
              >
                <button
                  type="button"
                  onClick={() => handleOpenSession(s)}
                  className="min-w-0 flex-1 cursor-pointer text-left"
                >
                  <h3 className="type-title-md truncate text-[var(--eduma-text-primary)]">
                    {s.title}
                  </h3>
                  <p className="type-body-sm mt-0.5 truncate text-[var(--eduma-text-muted)]">
                    {s.preview || formatRelativeTime(s.updatedAt)}
                  </p>
                </button>

                <div className="flex items-center gap-1">
                  <AppCircleIconButton
                    label="Rename"
                    size={34}
                    onClick={() => handleRename(s)}
                  >
                    <EdumaIcon family="huge-stroke" name="edit02" size={15} />
                  </AppCircleIconButton>
                  <AppCircleIconButton
                    label="Delete"
                    size={34}
                    onClick={() => handleDelete(s.id)}
                  >
                    <EdumaIcon family="huge-stroke" name="delete02" size={15} color="var(--eduma-error)" />
                  </AppCircleIconButton>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );

  const modalDialog = (
    <AppModalDialog
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        title={activeTitle || 'Conversation'}
        maxWidth={DesktopWidths.narrow}
      >
        <div className="space-y-3">
          {activeMessages.map((m, idx) => (
            <div
              key={idx}
              className={`rounded-[16px] p-3.5 text-[14px] leading-relaxed ${
                m.role === 'user'
                  ? 'ml-8 bg-[var(--eduma-primary)] text-white'
                  : 'mr-8 border border-[var(--eduma-border)] bg-[var(--eduma-bg)] text-[var(--eduma-text-primary)]'
              }`}
            >
              <p className="whitespace-pre-wrap">{m.content}</p>
            </div>
          ))}
          {asking ? (
            <p className="type-body-sm text-[var(--eduma-text-muted)]">Thinking…</p>
          ) : null}
        </div>
      </AppModalDialog>
  );

  return isExpanded ? (
    <>
      <DesktopPopupFrame maxWidth={880} backTo="/main">
        {historyContent}
      </DesktopPopupFrame>
      {modalDialog}
    </>
  ) : (
    <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">
      {historyContent}
      {modalDialog}
    </div>
  );
}
