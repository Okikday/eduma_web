import React, { useEffect, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { AppOtpField } from '../../../shared/components/AppOtpField';
import { AppSegmentedControl } from '../../../shared/components/AppSegmentedControl';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useToast } from '../../../shared/components/AppToast';
import { useAuth } from '../data/AuthContext';
import { authApi } from '../data/authApi';
import { AuthLinkLogic } from '../logic/authLinkLogic';
import { AuthDesktopFrame } from './AuthDesktopFrame';

export function VerifyEmailView() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { showToast } = useToast();
  const { user, pendingVerificationEmail, verifyEmail, error, clearError } = useAuth();

  const urlToken = AuthLinkLogic.cleanToken(searchParams.get('token')) || '';
  const initialEmail =
    searchParams.get('email') || pendingVerificationEmail || user?.email || '';

  const [mode, setMode] = useState<'code' | 'link'>(urlToken ? 'link' : 'code');
  const [code, setCode] = useState('');
  const [linkInput, setLinkInput] = useState(urlToken);
  const [busy, setBusy] = useState(false);
  const [cooldown, setCooldown] = useState(0);

  // Auto-verify when opened from an email link `?token=...`.
  useEffect(() => {
    if (!urlToken) return;
    let cancelled = false;
    (async () => {
      setBusy(true);
      const ok = await verifyEmail({ token: urlToken });
      if (!cancelled) {
        setBusy(false);
        if (ok) {
          showToast('Email verified!', 'success');
          navigate('/main', { replace: true });
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [urlToken, verifyEmail, navigate, showToast]);

  useEffect(() => {
    if (cooldown <= 0) return;
    const t = window.setTimeout(() => setCooldown((c) => c - 1), 1000);
    return () => window.clearTimeout(t);
  }, [cooldown]);

  const submitCode = async (targetCode: string) => {
    if (targetCode.length !== 6) return;
    setBusy(true);
    const ok = await verifyEmail({
      code: targetCode,
      email: initialEmail || undefined,
    });
    setBusy(false);
    if (ok) {
      showToast('Email confirmed. Welcome to Eduma!', 'success');
      navigate('/main', { replace: true });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    if (mode === 'code') {
      await submitCode(code);
      return;
    }
    const token = AuthLinkLogic.tokenFrom(linkInput, 'verify-email');
    if (!token) {
      showToast('Paste a valid verification link or token.', 'error');
      return;
    }
    setBusy(true);
    const ok = await verifyEmail({ token });
    setBusy(false);
    if (ok) {
      showToast('Email verified!', 'success');
      navigate('/main', { replace: true });
    }
  };

  const handleResend = async () => {
    if (cooldown > 0) return;
    try {
      await authApi.resendVerification(initialEmail || undefined);
      setCooldown(60);
      showToast('Verification code sent. Check your inbox.', 'success');
    } catch (ex) {
      showToast(
        ex instanceof Error ? ex.message : 'Unable to resend code right now.',
        'error'
      );
    }
  };

  return (
    <AuthDesktopFrame>
      <div>
        <Link
          to={user ? '/main' : '/sign-in'}
          className="inline-flex items-center gap-1.5 text-[13.5px] font-semibold text-[var(--eduma-text-secondary)] hover:text-[var(--eduma-text-primary)]"
        >
          <EdumaIcon family="huge-stroke" name="arrowLeft01" size={16} />
          <span>{user ? 'Back to Eduma' : 'Back to Sign In'}</span>
        </Link>

        <h1 className="type-display-sm mt-5 text-[var(--eduma-text-primary)]">
          Confirm your email
        </h1>
        <p className="type-body-md mt-1.5 text-[var(--eduma-text-muted)]">
          {initialEmail
            ? `We sent a 6-digit confirmation code and link to ${initialEmail}.`
            : 'Enter your 6-digit verification code or paste the link from your email.'}
        </p>

        <div className="mt-5">
          <AppSegmentedControl
            fullWidth
            value={mode}
            onChange={(v) => {
              clearError();
              setMode(v);
            }}
            options={[
              { value: 'code', label: '6-digit code' },
              { value: 'link', label: 'Paste link' },
            ]}
          />
        </div>

        {error ? (
          <div
            role="alert"
            className="mt-4 rounded-[14px] border border-[var(--eduma-error)]/30 bg-[var(--eduma-error)]/10 px-4 py-3 text-[13.5px] font-semibold text-[var(--eduma-error)]"
          >
            {error}
          </div>
        ) : null}

        <form onSubmit={handleSubmit} method="POST" className="mt-5 flex flex-col gap-5">
          {mode === 'code' ? (
            <AppOtpField
              value={code}
              onChange={(digits) => {
                clearError();
                setCode(digits);
              }}
              onComplete={submitCode}
              disabled={busy}
            />
          ) : (
            <AppTextFormField
              id="verify-token-link"
              name="token"
              label="Verification link or token"
              placeholder="Paste the email link or token"
              spellCheck={false}
              autoCapitalize="none"
              required
              value={linkInput}
              onChange={(e) => {
                clearError();
                setLinkInput(e.target.value);
              }}
            />
          )}

          <AppButton type="submit" size="lg" fullWidth loading={busy}>
            Verify email
          </AppButton>
        </form>

        <div className="mt-5 flex items-center justify-between text-[13.5px]">
          <button
            type="button"
            disabled={cooldown > 0}
            onClick={handleResend}
            className="cursor-pointer font-semibold text-[var(--eduma-primary)] disabled:cursor-not-allowed disabled:opacity-55"
          >
            {cooldown > 0 ? `Resend in ${cooldown}s` : 'Resend verification email'}
          </button>

          {user ? (
            <Link
              to="/main"
              className="font-semibold text-[var(--eduma-text-muted)] hover:underline"
            >
              Skip for now
            </Link>
          ) : null}
        </div>
      </div>
    </AuthDesktopFrame>
  );
}
