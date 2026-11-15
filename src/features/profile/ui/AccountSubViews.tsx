import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { apiClient } from '../../../core/api/apiClient';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { AppSegmentedControl } from '../../../shared/components/AppSegmentedControl';
import { useToast } from '../../../shared/components/AppToast';
import { DesktopPageHeader } from '../../../shared/components/DesktopPageHeader';
import { DesktopPopupFrame } from '../../../shared/components/DesktopPopupFrame';
import { useFormFactor } from '../../../shared/components/formFactor';
import { PureAppBar } from '../../../shared/components/PureAppBar';

export function PremiumView() {
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();
  const [overview, setOverview] = useState<Record<string, unknown> | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    apiClient
      .get<Record<string, unknown>>('/billing/overview')
      .then(setOverview)
      .catch(() => null);
  }, []);

  const handleCheckout = async (planId: string) => {
    setBusy(true);
    try {
      const res = await apiClient.post<{ url?: string; checkoutUrl?: string }>(
        '/billing/checkout',
        { planId }
      );
      const target = res?.checkoutUrl || res?.url;
      if (target) window.location.assign(target);
      else showToast('Checkout session initialized.', 'info');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Unable to start checkout.', 'error');
    } finally {
      setBusy(false);
    }
  };

  const handlePortal = async () => {
    try {
      const res = await apiClient.post<{ url?: string }>('/billing/portal', {});
      if (res?.url) window.location.assign(res.url);
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Billing portal unavailable.', 'error');
    }
  };

  const body = (
    <>
      {!isExpanded ? <PureAppBar title="Plan & Billing" backTo="/profile" /> : null}
      <div className={isExpanded ? 'px-7 pb-8 pt-2' : 'mx-auto max-w-[860px] px-4 py-6 sm:px-6'}>
        {isExpanded ? (
          <DesktopPageHeader
            title="Eduma Plan & Billing"
            subtitle="Unlock unlimited AI study sets, uploads, and shared spaces"
            backTo="/profile"
          />
        ) : null}

        <div className="eduma-card-surface rounded-[24px] p-6">
          <div className="flex items-center gap-3">
            <EdumaIcon family="huge-solid" name="crown" size={28} color="var(--eduma-gold)" />
            <div>
              <h2 className="type-headline-sm">
                Current plan: {String(overview?.planName || overview?.plan || 'Free')}
              </h2>
              <p className="type-body-sm text-[var(--eduma-text-muted)]">
                Manage your Eduma subscription or upgrade for higher AI &amp; upload quotas.
              </p>
            </div>
          </div>

          <div className="mt-6 flex flex-wrap gap-3">
            <AppButton loading={busy} onClick={() => handleCheckout('pro_monthly')}>
              Upgrade to Eduma Pro
            </AppButton>
            <AppButton variant="secondary" onClick={handlePortal}>
              Manage billing portal
            </AppButton>
          </div>
        </div>
      </div>
    </>
  );

  if (isExpanded) {
    return (
      <DesktopPopupFrame maxWidth={640} backTo="/profile">
        {body}
      </DesktopPopupFrame>
    );
  }

  return <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">{body}</div>;
}

export function WhatsAppView() {
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();
  const [status, setStatus] = useState<Record<string, unknown> | null>(null);
  const [pairCode, setPairCode] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    apiClient
      .get<Record<string, unknown>>('/auth/whatsapp/status')
      .then(setStatus)
      .catch(() => null);
  }, []);

  const handleGenerateCode = async () => {
    setBusy(true);
    try {
      const res = await apiClient.post<{ code?: string; pairCode?: string }>(
        '/auth/whatsapp/pair-code',
        {}
      );
      setPairCode(String(res?.code || res?.pairCode || ''));
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Unable to generate code.', 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleUnlink = async () => {
    await apiClient.post('/auth/whatsapp/unlink', {});
    setStatus({ linked: false });
    setPairCode(null);
    showToast('WhatsApp unlinked.', 'success');
  };

  const isLinked = Boolean(status?.linked ?? status?.isLinked ?? false);

  const body = (
    <>
      {!isExpanded ? <PureAppBar title="WhatsApp Companion" backTo="/profile" /> : null}
      <div className={isExpanded ? 'px-7 pb-8 pt-2' : 'mx-auto max-w-[780px] px-4 py-6 sm:px-6'}>
        {isExpanded ? (
          <DesktopPageHeader
            title="WhatsApp Study Companion"
            subtitle="Send notes, voice memos, and reminders directly into your spaces"
            backTo="/profile"
          />
        ) : null}

        <div className="eduma-card-surface rounded-[24px] p-6">
          <div className="flex items-center gap-3">
            <EdumaIcon family="iconsax" name="whatsapp_copy" size={28} color="var(--eduma-whatsapp)" />
            <div>
              <h2 className="type-title-lg">
                {isLinked ? 'Connected to WhatsApp' : 'Pair your WhatsApp'}
              </h2>
              <p className="type-body-sm text-[var(--eduma-text-muted)]">
                {isLinked
                  ? 'Forward course materials to save them into your default space.'
                  : 'Generate a temporary pairing code to send to Eduma on WhatsApp.'}
              </p>
            </div>
          </div>

          {pairCode ? (
            <div className="mt-5 rounded-2xl bg-[var(--eduma-bg)] p-4 text-center font-mono text-2xl font-bold tracking-widest text-[var(--eduma-primary)]">
              {pairCode}
            </div>
          ) : null}

          <div className="mt-6 flex flex-wrap gap-3">
            <AppButton loading={busy} onClick={handleGenerateCode}>
              Generate pairing code
            </AppButton>
            {isLinked ? (
              <AppButton variant="danger" onClick={handleUnlink}>
                Unlink WhatsApp
              </AppButton>
            ) : null}
          </div>
        </div>
      </div>
    </>
  );

  if (isExpanded) {
    return (
      <DesktopPopupFrame maxWidth={640} backTo="/profile">
        {body}
      </DesktopPopupFrame>
    );
  }

  return <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">{body}</div>;
}

type LegalDocId = 'privacy' | 'terms' | 'refund';

const LEGAL_FILES: Record<LegalDocId, { title: string; path: string }> = {
  privacy: { title: 'Privacy Policy', path: '/assets/legal/privacy_policy.md' },
  terms: { title: 'Terms of Service', path: '/assets/legal/terms_of_service.md' },
  refund: { title: 'Refund Policy', path: '/assets/legal/refund_policy.md' },
};

export function LegalDocumentView() {
  const [searchParams, setSearchParams] = useSearchParams();
  const docId = (searchParams.get('id') as LegalDocId) || 'privacy';
  const current = LEGAL_FILES[docId] || LEGAL_FILES.privacy;
  const { isExpanded } = useFormFactor();
  const [markdown, setMarkdown] = useState('');

  useEffect(() => {
    fetch(current.path)
      .then((r) => r.text())
      .then(setMarkdown)
      .catch(() => setMarkdown('Unable to load legal document.'));
  }, [current.path]);

  const body = (
    <>
      {!isExpanded ? <PureAppBar title={current.title} backTo="/profile" /> : null}
      <div className={isExpanded ? 'px-7 pb-8 pt-2' : 'mx-auto max-w-[820px] px-4 py-6 sm:px-6'}>
        {isExpanded ? (
          <DesktopPageHeader
            title={current.title}
            backTo="/profile"
            trailing={
              <Link to="/sign-in" className="text-[13px] font-semibold text-[var(--eduma-primary)]">
                Sign In
              </Link>
            }
          />
        ) : null}

        <div className="mb-5">
          <AppSegmentedControl
            value={docId}
            onChange={(next) => setSearchParams({ id: next })}
            options={[
              { value: 'privacy', label: 'Privacy Policy' },
              { value: 'terms', label: 'Terms of Service' },
              { value: 'refund', label: 'Refund Policy' },
            ]}
          />
        </div>

        <article className="eduma-card-surface rounded-[22px] p-6">
          <pre className="whitespace-pre-wrap font-sans text-[14.5px] leading-relaxed text-[var(--eduma-text-secondary)]">
            {markdown || 'Loading document…'}
          </pre>
        </article>
      </div>
    </>
  );

  if (isExpanded) {
    return (
      <DesktopPopupFrame maxWidth={880} backTo="/profile">
        {body}
      </DesktopPopupFrame>
    );
  }

  return <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">{body}</div>;
}
