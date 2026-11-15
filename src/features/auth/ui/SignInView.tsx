import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useAuth } from '../data/AuthContext';
import { Validator } from '../logic/authLogic';
import { AuthDesktopFrame } from './AuthDesktopFrame';
import { GoogleSignInButton } from './GoogleSignInButton';
import { LegalConsentCheckbox } from './LegalConsentCheckbox';

export function SignInView() {
  const navigate = useNavigate();
  const location = useLocation();
  const { signIn, signInWithGoogle, hasSignedInBefore, error, clearError } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [termsAccepted, setTermsAccepted] = useState(true);
  const [localError, setLocalError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const redirectTo =
    ((location.state as { from?: string } | null)?.from &&
    typeof (location.state as { from?: string }).from === 'string'
      ? (location.state as { from?: string }).from
      : null) || '/main';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    setLocalError(null);

    if (!termsAccepted) {
      setLocalError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }

    const emailErr = Validator.validateEmail(email);
    if (emailErr) {
      setLocalError(emailErr);
      return;
    }
    if (!password) {
      setLocalError('Enter your password.');
      return;
    }

    setSubmitting(true);
    const res = await signIn(email.trim(), password, { termsAccepted });
    setSubmitting(false);

    if (res.ok) {
      if (res.needsVerification) {
        const targetEmail = encodeURIComponent(res.email || email.trim());
        navigate(`/verify-email?email=${targetEmail}`, { replace: true });
      } else {
        navigate(redirectTo, { replace: true });
      }
    }
  };

  const handleGoogle = async (idToken: string) => {
    if (!termsAccepted) {
      setLocalError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    setSubmitting(true);
    const res = await signInWithGoogle(idToken, undefined, termsAccepted);
    setSubmitting(false);
    if (res.ok) {
      if (res.needsVerification) {
        const targetEmail = encodeURIComponent(res.email || '');
        navigate(`/verify-email?email=${targetEmail}`, { replace: true });
      } else {
        navigate(redirectTo, { replace: true });
      }
    }
  };

  const shownError = localError || error;

  return (
    <AuthDesktopFrame>
      <div className="flex flex-col">
        <h1 className="text-[28px] leading-[1.15] font-bold tracking-[-0.02em] text-[var(--eduma-text-primary)]">
          {hasSignedInBefore ? 'Welcome back' : 'Welcome to Eduma'}
        </h1>
        <p className="mt-1.5 text-[15px] leading-[1.45] text-[var(--eduma-text-secondary)]">
          Enter your email and password to continue.
        </p>

        {shownError ? (
          <div
            role="alert"
            className="mt-5 flex items-start gap-2.5 rounded-[14px] border border-[var(--eduma-error)]/30 bg-[var(--eduma-error)]/10 px-4 py-3 text-[13.5px] font-semibold text-[var(--eduma-error)]"
          >
            <EdumaIcon family="huge-stroke" name="informationCircle" size={18} />
            <span>{shownError}</span>
          </div>
        ) : null}

        <form
          onSubmit={handleSubmit}
          method="POST"
          className="mt-6 flex flex-col gap-4"
          noValidate
        >
          <AppTextFormField
            id="email"
            name="email"
            type="email"
            label="Email"
            placeholder="you@example.com"
            autoComplete="username"
            spellCheck={false}
            autoCapitalize="none"
            autoCorrect="off"
            enterKeyHint="next"
            required
            value={email}
            onChange={(e) => {
              clearError();
              setLocalError(null);
              setEmail(e.target.value);
            }}
            leadingIcon={<EdumaIcon family="iconsax" name="sms_copy" size={18} />}
          />

          <AppTextFormField
            id="password"
            name="password"
            type="password"
            label="Password"
            placeholder="Enter your password"
            autoComplete="current-password"
            enterKeyHint="done"
            required
            showPasswordToggle
            value={password}
            onChange={(e) => {
              clearError();
              setLocalError(null);
              setPassword(e.target.value);
            }}
            leadingIcon={<EdumaIcon family="iconsax" name="lock_1_copy" size={18} />}
          />

          <div className="flex items-center justify-end">
            <Link
              to="/forgot-password"
              className="text-[14px] font-semibold text-[var(--eduma-primary)] hover:underline"
            >
              Forgot password?
            </Link>
          </div>

          <div className="flex flex-col gap-4 pt-2">
            <LegalConsentCheckbox
              id="signin-terms"
              checked={termsAccepted}
              onChange={(next) => {
                setTermsAccepted(next);
                setLocalError(null);
              }}
            />

            <AppButton
              type="submit"
              size="lg"
              fullWidth
              disabled={!termsAccepted}
              loading={submitting}
            >
              Sign In
            </AppButton>

            <div className="flex items-center gap-3 py-1">
              <div className="h-[0.5px] flex-1 bg-[var(--eduma-border)]" />
              <span className="text-[12px] font-semibold uppercase tracking-wider text-[var(--eduma-text-muted)]">
                OR
              </span>
              <div className="h-[0.5px] flex-1 bg-[var(--eduma-border)]" />
            </div>

            <GoogleSignInButton
              onCredential={handleGoogle}
              disabled={!termsAccepted || submitting}
            />

            <p className="pt-1 text-center text-[14px] font-medium text-[var(--eduma-text-secondary)]">
              Don&apos;t have an account?{' '}
              <Link
                to="/sign-up"
                className="font-bold text-[var(--eduma-primary)] hover:underline"
              >
                Sign Up
              </Link>
            </p>
          </div>
        </form>
      </div>
    </AuthDesktopFrame>
  );
}
