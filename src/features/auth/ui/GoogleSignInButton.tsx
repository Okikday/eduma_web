import { useEffect, useRef } from 'react';
import { APP_CONFIG } from '../../../core/config/appConfig';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { useToast } from '../../../shared/components/AppToast';

interface GoogleSignInButtonProps {
  onCredential: (idToken: string) => void;
  disabled?: boolean;
}

/**
 * Integrates Google Identity Services via `/google-sign-in.js` when a Google
 * Web Client ID is configured, otherwise explains cleanly on tap.
 */
export function GoogleSignInButton({
  onCredential,
  disabled = false,
}: GoogleSignInButtonProps) {
  const { showToast } = useToast();
  const tokenInputRef = useRef<HTMLInputElement | null>(null);
  const onCredentialRef = useRef(onCredential);
  onCredentialRef.current = onCredential;

  const clientId = APP_CONFIG.googleWebClientId;

  useEffect(() => {
    const input = tokenInputRef.current;
    if (!input || !clientId) return;

    const handleTokenChange = () => {
      const token = input.value.trim();
      if (token) {
        input.value = '';
        onCredentialRef.current(token);
      }
    };

    input.addEventListener('input', handleTokenChange);
    input.addEventListener('change', handleTokenChange);
    return () => {
      input.removeEventListener('input', handleTokenChange);
      input.removeEventListener('change', handleTokenChange);
    };
  }, [clientId]);

  if (clientId) {
    return (
      <div className="relative flex flex-col items-center">
        <input
          ref={tokenInputRef}
          id="google-id-token"
          type="hidden"
          aria-hidden="true"
        />
        <div
          id="google-sign-in-button"
          data-google-client-id={clientId}
          className={`flex min-h-[44px] w-full items-center justify-center ${
            disabled ? 'pointer-events-none opacity-60' : ''
          }`}
        />
      </div>
    );
  }

  return (
    <AppButton
      variant="secondary"
      fullWidth
      size="lg"
      disabled={disabled}
      leadingIcon={<EdumaIcon family="iconsax" name="google_1" size={18} />}
      onClick={() =>
        showToast(
          'Set VITE_EDUMA_GOOGLE_WEB_CLIENT_ID to enable Google Sign-In in this environment.',
          'info'
        )
      }
    >
      Continue with Google
    </AppButton>
  );
}
