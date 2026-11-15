import React, { useEffect, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useAuth } from '../data/AuthContext';
import { authApi } from '../data/authApi';
import { ReferralLogic } from '../logic/authLinkLogic';
import { SignUpLogic, Validator } from '../logic/authLogic';
import type { SignUpStep, UsernameCheck } from '../models/authModels';
import { AuthDesktopFrame } from './AuthDesktopFrame';
import { GoogleSignInButton } from './GoogleSignInButton';
import { LegalConsentCheckbox } from './LegalConsentCheckbox';

const STEPS = SignUpLogic.steps({ includePhoto: true });

export function SignUpView() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { signUp, signInWithGoogle, error, clearError } = useAuth();

  const initialReferral =
    ReferralLogic.cleanCode(
      searchParams.get('ref') || searchParams.get('referral')
    ) || '';

  const [step, setStep] = useState<SignUpStep>('name');
  const [name, setName] = useState('');
  const [username, setUsername] = useState('');
  const [usernameEdited, setUsernameEdited] = useState(false);
  const [usernameCheck, setUsernameCheck] = useState<UsernameCheck>('idle');
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreviewUrl, setAvatarPreviewUrl] = useState<string | null>(null);
  const [referralInput, setReferralInput] = useState(initialReferral);
  const [referrerName, setReferrerName] = useState<string | null>(null);
  const [termsAccepted, setTermsAccepted] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const stepIndex = STEPS.indexOf(step);
  const firstName = SignUpLogic.firstName(name);
  const copy = SignUpLogic.copyFor(step, {
    firstName,
    invited: Boolean(initialReferral),
  });
  const strength = SignUpLogic.strengthOf(password);

  // Suggest a username automatically until the user edits the field manually.
  useEffect(() => {
    if (usernameEdited) return;
    const candidates = SignUpLogic.usernameCandidates(name);
    if (candidates[0]) {
      setUsername(candidates[0]);
    } else if (!name.trim()) {
      setUsername('');
      setUsernameCheck('idle');
    }
  }, [name, usernameEdited]);

  // Debounced live username availability check.
  useEffect(() => {
    const clean = username.trim();
    if (!clean) {
      setUsernameCheck('idle');
      return;
    }
    if (Validator.validateUsername(clean) !== null) {
      setUsernameCheck('invalid');
      return;
    }

    let cancelled = false;
    setUsernameCheck('checking');
    const timer = window.setTimeout(async () => {
      try {
        const res = await authApi.checkUsername(clean);
        if (cancelled) return;
        setUsernameCheck(res.available ? 'available' : 'taken');
        setSuggestions(res.suggestions || []);
      } catch {
        if (!cancelled) setUsernameCheck('unknown');
      }
    }, 380);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [username]);

  // Softly verify referral code if present.
  useEffect(() => {
    const code = ReferralLogic.fromUrlOrInput(referralInput);
    if (!code) {
      setReferrerName(null);
      return;
    }
    let cancelled = false;
    const timer = window.setTimeout(async () => {
      const info = await authApi.lookupReferral(code);
      if (!cancelled && info?.valid && info.referrerName) {
        setReferrerName(info.referrerName);
      } else if (!cancelled) {
        setReferrerName(null);
      }
    }, 400);
    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [referralInput]);

  useEffect(() => {
    return () => {
      if (avatarPreviewUrl) URL.revokeObjectURL(avatarPreviewUrl);
    };
  }, [avatarPreviewUrl]);

  const canProceed =
    SignUpLogic.canContinue(step, {
      name,
      username,
      usernameCheck,
      email,
      strength,
    }) && (step !== 'referral' || termsAccepted);

  const handleNextOrSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canProceed) return;

    if (stepIndex < STEPS.length - 1) {
      setStep(STEPS[stepIndex + 1]);
      return;
    }

    setSubmitting(true);
    const code = ReferralLogic.fromUrlOrInput(referralInput) || undefined;
    const res = await signUp({
      name,
      username,
      email,
      password,
      referralCode: code,
      avatarFile,
      termsAccepted,
    });
    setSubmitting(false);

    if (res.ok) {
      if (res.needsVerification) {
        const targetEmail = encodeURIComponent(res.email || email.trim());
        navigate(`/verify-email?email=${targetEmail}`, {
          replace: true,
        });
      } else {
        navigate('/main', { replace: true });
      }
    }
  };

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (avatarPreviewUrl) URL.revokeObjectURL(avatarPreviewUrl);
    setAvatarFile(file);
    setAvatarPreviewUrl(URL.createObjectURL(file));
  };

  const handleGoogle = async (idToken: string) => {
    setSubmitting(true);
    const code = ReferralLogic.fromUrlOrInput(referralInput) || undefined;
    const res = await signInWithGoogle(idToken, code, termsAccepted);
    setSubmitting(false);
    if (res.ok) {
      if (res.needsVerification) {
        const targetEmail = encodeURIComponent(res.email || '');
        navigate(`/verify-email?email=${targetEmail}`, { replace: true });
      } else {
        navigate('/main', { replace: true });
      }
    }
  };

  const strengthColor =
    strength.level === 'tooShort' || strength.level === 'weak'
      ? 'var(--eduma-error)'
      : strength.level === 'fair'
      ? 'var(--eduma-warning)'
      : strength.level === 'good' || strength.level === 'strong'
      ? 'var(--eduma-success)'
      : 'var(--eduma-text-muted)';

  return (
    <AuthDesktopFrame maxBodyHeight={720}>
      <div className="flex flex-col">
        {/* SignUpTopBar matching ../eduma SignUpTopBar */}
        <div className="mb-6 flex items-center justify-between gap-3">
          {stepIndex > 0 ? (
            <button
              type="button"
              onClick={() => setStep(STEPS[stepIndex - 1])}
              className="inline-flex h-9 w-9 cursor-pointer items-center justify-center rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)] transition hover:bg-[var(--eduma-card)]"
              aria-label="Back"
            >
              <EdumaIcon family="huge-stroke" name="arrowLeft01" size={16} />
            </button>
          ) : (
            <button
              type="button"
              onClick={() => navigate('/sign-in')}
              className="inline-flex h-9 w-9 cursor-pointer items-center justify-center rounded-full border border-[var(--eduma-border)] bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)] transition hover:bg-[var(--eduma-card)]"
              aria-label="Close"
            >
              <EdumaIcon family="huge-stroke" name="cancel01" size={16} />
            </button>
          )}

          <div
            className="flex flex-1 items-center gap-1.5 px-2"
            aria-label={`Step ${stepIndex + 1} of ${STEPS.length}`}
          >
            {STEPS.map((s, idx) => (
              <span
                key={s}
                className="h-1 flex-1 rounded-full transition-colors"
                style={{
                  backgroundColor:
                    idx <= stepIndex
                      ? 'var(--eduma-primary)'
                      : 'var(--eduma-border)',
                }}
              />
            ))}
          </div>

          {step === 'photo' ? (
            <button
              type="button"
              onClick={() => setStep(STEPS[stepIndex + 1])}
              className="cursor-pointer px-2 py-1 text-[13.5px] font-semibold text-[var(--eduma-text-secondary)] hover:text-[var(--eduma-primary)]"
            >
              Skip
            </button>
          ) : (
            <span className="w-9 text-right text-[12px] font-semibold text-[var(--eduma-text-muted)]">
              {stepIndex + 1}/{STEPS.length}
            </span>
          )}
        </div>

        <h1 className="type-display-sm text-[var(--eduma-text-primary)]">
          {copy.title}
        </h1>
        <p className="type-body-md mt-1.5 text-[var(--eduma-text-muted)]">
          {copy.helper}
        </p>

        {error ? (
          <div
            role="alert"
            className="mt-5 flex items-start gap-2.5 rounded-[14px] border border-[var(--eduma-error)]/30 bg-[var(--eduma-error)]/10 px-4 py-3 text-[13.5px] font-semibold text-[var(--eduma-error)]"
          >
            <EdumaIcon family="huge-stroke" name="informationCircle" size={18} />
            <span>{error}</span>
          </div>
        ) : null}

        <form onSubmit={handleNextOrSubmit} className="mt-6 flex flex-col gap-4" noValidate>
          {step === 'name' ? (
            <>
              <AppTextFormField
                id="full-name"
                name="fullname"
                label="Full name"
                placeholder="Your first and last name"
                autoComplete="name"
                enterKeyHint="next"
                required
                autoFocus
                value={name}
                onChange={(e) => {
                  clearError();
                  setName(e.target.value);
                }}
                leadingIcon={<EdumaIcon family="iconsax" name="user_copy" size={18} />}
              />

              <div>
                <AppTextFormField
                  id="username"
                  name="username"
                  label="Username"
                  placeholder="e.g. ada.obi"
                  autoComplete="username"
                  spellCheck={false}
                  autoCapitalize="none"
                  autoCorrect="off"
                  enterKeyHint="next"
                  required
                  value={username}
                  onChange={(e) => {
                    setUsernameEdited(true);
                    setUsername(SignUpLogic.cleanUsername(e.target.value));
                  }}
                  leadingIcon={<span className="text-[14px] font-bold">@</span>}
                  trailingElement={
                    usernameCheck === 'checking' ? (
                      <span className="text-[12px] text-[var(--eduma-text-muted)]">
                        Checking…
                      </span>
                    ) : usernameCheck === 'available' ? (
                      <span className="text-[12px] font-bold text-[var(--eduma-success)]">
                        Available
                      </span>
                    ) : usernameCheck === 'taken' ? (
                      <span className="text-[12px] font-bold text-[var(--eduma-error)]">
                        Taken
                      </span>
                    ) : null
                  }
                  error={
                    username && Validator.validateUsername(username)
                      ? Validator.validateUsername(username)
                      : usernameCheck === 'taken'
                      ? 'That username is already taken.'
                      : null
                  }
                />

                {usernameCheck === 'taken' && suggestions.length > 0 ? (
                  <div className="mt-2 flex flex-wrap items-center gap-1.5">
                    <span className="text-[12px] text-[var(--eduma-text-muted)]">
                      Try:
                    </span>
                    {suggestions.slice(0, 3).map((sug) => (
                      <button
                        key={sug}
                        type="button"
                        onClick={() => {
                          setUsernameEdited(true);
                          setUsername(sug);
                        }}
                        className="cursor-pointer rounded-full bg-[var(--eduma-nav-pill)] px-2.5 py-0.5 text-[12px] font-semibold text-[var(--eduma-primary)]"
                      >
                        @{sug}
                      </button>
                    ))}
                  </div>
                ) : null}
              </div>
            </>
          ) : null}

          {step === 'account' ? (
            <>
              <AppTextFormField
                id="signup-email"
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
                autoFocus
                value={email}
                onChange={(e) => {
                  clearError();
                  setEmail(e.target.value);
                }}
                error={
                  email.trim() ? Validator.validateEmail(email) : null
                }
                leadingIcon={<EdumaIcon family="iconsax" name="sms_copy" size={18} />}
              />

              <AppTextFormField
                id="new-password"
                name="new-password"
                type="password"
                label="Password"
                placeholder="At least 8 characters"
                autoComplete="new-password"
                enterKeyHint="next"
                required
                showPasswordToggle
                value={password}
                onChange={(e) => {
                  clearError();
                  setPassword(e.target.value);
                }}
                leadingIcon={<EdumaIcon family="iconsax" name="lock_copy" size={18} />}
              />

              <div className="px-1">
                <div className="grid grid-cols-4 gap-1.5" aria-hidden="true">
                  {[1, 2, 3, 4].map((seg) => (
                    <div
                      key={seg}
                      className="h-1.5 rounded-full transition-colors"
                      style={{
                        backgroundColor:
                          seg <= strength.segments
                            ? strengthColor
                            : 'var(--eduma-border)',
                      }}
                    />
                  ))}
                </div>
                <p
                  className="mt-2 text-[13px] font-medium"
                  style={{ color: strengthColor }}
                >
                  {strength.label ||
                    'Mix letters, numbers and symbols for a stronger password.'}
                </p>
              </div>
            </>
          ) : null}

          {step === 'photo' ? (
            <div className="flex flex-col items-center py-4">
              <div className="flex h-28 w-28 items-center justify-center overflow-hidden rounded-full border-2 border-[var(--eduma-border)] bg-[var(--eduma-nav-pill)] text-3xl font-bold text-[var(--eduma-primary)]">
                {avatarPreviewUrl ? (
                  <img
                    src={avatarPreviewUrl}
                    alt="Profile preview"
                    className="h-full w-full object-cover"
                  />
                ) : (
                  <span>{firstName ? firstName.charAt(0).toUpperCase() : 'E'}</span>
                )}
              </div>

              <label className="mt-5 inline-flex cursor-pointer items-center gap-2 rounded-[13px] border border-[var(--eduma-border)] bg-[var(--eduma-card)] px-4 py-2.5 text-[14px] font-semibold text-[var(--eduma-text-primary)] hover:brightness-95">
                <EdumaIcon family="iconsax" name="gallery_add_copy" size={18} />
                <span>{avatarFile ? 'Choose another photo' : 'Choose a photo'}</span>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handlePhotoChange}
                  className="sr-only"
                />
              </label>

              {avatarFile ? (
                <button
                  type="button"
                  onClick={() => {
                    if (avatarPreviewUrl) URL.revokeObjectURL(avatarPreviewUrl);
                    setAvatarFile(null);
                    setAvatarPreviewUrl(null);
                  }}
                  className="mt-2 cursor-pointer text-[13.5px] font-semibold text-[var(--eduma-text-muted)] hover:text-[var(--eduma-error)]"
                >
                  Remove photo
                </button>
              ) : null}

              <p className="type-body-sm mt-4 text-center text-[var(--eduma-text-muted)]">
                It&apos;s added to your profile after you confirm your email.
              </p>
            </div>
          ) : null}

          {step === 'referral' ? (
            <>
              <AppTextFormField
                id="referral-code"
                name="referral"
                label="Invite code"
                placeholder="Paste a code or invite link"
                spellCheck={false}
                autoCapitalize="none"
                autoCorrect="off"
                enterKeyHint="done"
                value={referralInput}
                onChange={(e) => setReferralInput(e.target.value)}
                leadingIcon={<EdumaIcon family="iconsax" name="ticket_copy" size={18} />}
              />
              {referrerName ? (
                <p className="text-[13px] font-semibold text-[var(--eduma-success)]">
                  Invited by {referrerName}
                </p>
              ) : null}

              <div className="mt-2">
                <LegalConsentCheckbox
                  id="signup-terms"
                  checked={termsAccepted}
                  onChange={setTermsAccepted}
                />
              </div>
            </>
          ) : null}

          <AppButton
            type="submit"
            size="lg"
            fullWidth
            disabled={!canProceed}
            loading={submitting}
            className="mt-2"
          >
            {stepIndex < STEPS.length - 1
              ? step === 'photo' && !avatarFile
                ? 'Skip for now'
                : 'Continue'
              : 'Create account'}
          </AppButton>
        </form>

        {step === 'name' ? (
          <>
            <div className="my-6 flex items-center gap-3">
              <div className="h-px flex-1 bg-[var(--eduma-border)]" />
              <span className="text-[12.5px] font-semibold text-[var(--eduma-text-muted)]">
                Or
              </span>
              <div className="h-px flex-1 bg-[var(--eduma-border)]" />
            </div>

            <GoogleSignInButton onCredential={handleGoogle} disabled={submitting} />

            <p className="mt-7 text-center text-[14px] font-medium text-[var(--eduma-text-secondary)]">
              Already have an account?{' '}
              <Link
                to="/sign-in"
                className="font-bold text-[var(--eduma-primary)] hover:underline"
              >
                Sign in
              </Link>
            </p>
          </>
        ) : null}
      </div>
    </AuthDesktopFrame>
  );
}
