import { useState } from 'react';
import { Link } from 'react-router-dom';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { useToast } from '../../../shared/components/AppToast';
import { useAuth } from '../data/AuthContext';
import { authApi } from '../data/authApi';

export function EmailVerificationBanner() {
  const { user } = useAuth();
  const { showToast } = useToast();
  const [sending, setSending] = useState(false);

  if (
    !user ||
    user.isEmailVerified ||
    user.emailVerified ||
    user.isVerified ||
    user.verified
  ) {
    return null;
  }

  const handleResend = async () => {
    setSending(true);
    try {
      await authApi.resendVerification(user.email);
      showToast(`Verification code sent to ${user.email}.`, 'success');
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to send email right now.',
        'error'
      );
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="mb-5 flex flex-wrap items-center justify-between gap-3 rounded-[18px] border border-[var(--eduma-warning)]/35 bg-[var(--eduma-warning)]/10 px-4 py-3">
      <div className="flex min-w-0 items-center gap-3">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-[var(--eduma-warning)]/20 text-[var(--eduma-warning)]">
          <EdumaIcon family="iconsax" name="sms_notification_copy" size={18} />
        </div>
        <div className="min-w-0">
          <p className="type-title-sm text-[var(--eduma-text-primary)]">
            Verify your email address
          </p>
          <p className="type-body-sm truncate text-[var(--eduma-text-secondary)]">
            Confirm {user.email} to unlock invites, backups, and cloud sync.
          </p>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <AppButton
          variant="secondary"
          size="sm"
          loading={sending}
          onClick={handleResend}
        >
          Resend
        </AppButton>
        <Link to={`/verify-email?email=${encodeURIComponent(user.email)}`}>
          <AppButton size="sm">Enter code</AppButton>
        </Link>
      </div>
    </div>
  );
}
