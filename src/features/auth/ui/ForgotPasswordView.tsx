import React, { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useToast } from '../../../shared/components/AppToast';
import { authApi } from '../data/authApi';
import { AuthLinkLogic } from '../logic/authLinkLogic';
import { SignUpLogic, Validator } from '../logic/authLogic';
import { AuthDesktopFrame } from './AuthDesktopFrame';

export function ForgotPasswordView() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { showToast } = useToast();

  const initialToken = AuthLinkLogic.cleanToken(searchParams.get('token')) || '';
  const [phase, setPhase] = useState<'request' | 'reset'>(
    initialToken ? 'reset' : 'request'
  );
  const [email, setEmail] = useState('');
  const [codeOrLink, setCodeOrLink] = useState(initialToken);
  const [newPassword, setNewPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const strength = SignUpLogic.strengthOf(newPassword);

  const handleRequestCode = async (e: React.FormEvent) => {
    e.preventDefault();
    const err = Validator.validateEmail(email);
    if (err) {
      setErrorMsg(err);
      return;
    }
    setBusy(true);
    setErrorMsg(null);
    try {
      await authApi.forgotPassword(email.trim());
      showToast('If an account exists for that email, a reset link or code was sent.', 'success');
      setPhase('reset');
    } catch (ex) {
      setErrorMsg(ex instanceof Error ? ex.message : 'Unable to send reset code.');
    } finally {
      setBusy(false);
    }
  };

  const handleReset = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!strength.acceptable) {
      setErrorMsg('Use at least 8 characters for your new password.');
      return;
    }
    const raw = codeOrLink.trim();
    if (!raw) {
      setErrorMsg('Paste your reset token or enter the 6-digit code.');
      return;
    }

    const token = AuthLinkLogic.tokenFrom(raw, 'reset-password');
    const isShortCode = /^\d{6}$/.test(raw);

    setBusy(true);
    setErrorMsg(null);
    try {
      await authApi.resetPassword({
        email: email.trim() || undefined,
        code: isShortCode ? raw : undefined,
        token: !isShortCode ? token || raw : undefined,
        newPassword,
      });
      showToast('Password updated. You can sign in with your new password.', 'success');
      navigate('/sign-in', { replace: true });
    } catch (ex) {
      setErrorMsg(
        ex instanceof Error
          ? ex.message
          : 'That reset link or code is invalid or expired.'
      );
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthDesktopFrame>
      <div>
        <Link
          to="/sign-in"
          className="inline-flex items-center gap-1.5 text-[13.5px] font-semibold text-[var(--eduma-text-secondary)] hover:text-[var(--eduma-text-primary)]"
        >
          <EdumaIcon family="huge-stroke" name="arrowLeft01" size={16} />
          <span>Back to Sign In</span>
        </Link>

        <h1 className="type-display-sm mt-5 text-[var(--eduma-text-primary)]">
          {phase === 'request' ? 'Reset your password' : 'Choose a new password'}
        </h1>
        <p className="type-body-md mt-1.5 text-[var(--eduma-text-muted)]">
          {phase === 'request'
            ? "Enter your account email and we'll send instructions to reset your password."
            : 'Paste the reset link or code from your email along with a new password.'}
        </p>

        {errorMsg ? (
          <div
            role="alert"
            className="mt-5 rounded-[14px] border border-[var(--eduma-error)]/30 bg-[var(--eduma-error)]/10 px-4 py-3 text-[13.5px] font-semibold text-[var(--eduma-error)]"
          >
            {errorMsg}
          </div>
        ) : null}

        {phase === 'request' ? (
          <form onSubmit={handleRequestCode} className="mt-6 flex flex-col gap-4" noValidate>
            <AppTextFormField
              id="forgot-email"
              name="email"
              type="email"
              label="Account email"
              placeholder="you@example.com"
              autoComplete="username"
              spellCheck={false}
              autoCapitalize="none"
              autoCorrect="off"
              enterKeyHint="done"
              required
              autoFocus
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              leadingIcon={<EdumaIcon family="iconsax" name="sms_copy" size={18} />}
            />

            <AppButton type="submit" size="lg" fullWidth loading={busy}>
              Send reset link
            </AppButton>

            <button
              type="button"
              onClick={() => setPhase('reset')}
              className="mt-2 cursor-pointer text-center text-[13.5px] font-semibold text-[var(--eduma-primary)] hover:underline"
            >
              Already have a reset code or link?
            </button>
          </form>
        ) : (
          <form onSubmit={handleReset} className="mt-6 flex flex-col gap-4" noValidate>
            {!initialToken ? (
              <AppTextFormField
                id="reset-email"
                name="email"
                type="email"
                label="Email (optional for link token)"
                placeholder="you@example.com"
                autoComplete="username"
                spellCheck={false}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            ) : null}

            <AppTextFormField
              id="reset-token"
              name="token"
              label="Reset code or pasted link"
              placeholder="Paste the reset link or 6-digit code"
              spellCheck={false}
              autoCapitalize="none"
              required
              value={codeOrLink}
              onChange={(e) => setCodeOrLink(e.target.value)}
              leadingIcon={<EdumaIcon family="iconsax" name="key_copy" size={18} />}
            />

            <AppTextFormField
              id="reset-new-password"
              name="new-password"
              type="password"
              label="New password"
              placeholder="At least 8 characters"
              autoComplete="new-password"
              enterKeyHint="done"
              required
              showPasswordToggle
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              leadingIcon={<EdumaIcon family="iconsax" name="lock_copy" size={18} />}
            />

            <AppButton type="submit" size="lg" fullWidth loading={busy}>
              Reset password
            </AppButton>
          </form>
        )}
      </div>
    </AuthDesktopFrame>
  );
}
