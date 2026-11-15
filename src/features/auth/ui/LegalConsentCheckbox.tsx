import { Link } from 'react-router-dom';

interface LegalConsentCheckboxProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  id?: string;
}

export function LegalConsentCheckbox({
  checked,
  onChange,
  id = 'terms-consent',
}: LegalConsentCheckboxProps) {
  return (
    <label
      htmlFor={id}
      className="flex cursor-pointer items-start gap-2.5 text-[13px] leading-[1.4] text-[var(--eduma-text-secondary)] select-none"
    >
      <input
        id={id}
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer rounded accent-[var(--eduma-primary)]"
      />
      <span>
        I agree to Eduma&apos;s{' '}
        <Link
          to="/legalDocument?id=terms"
          className="font-semibold text-[var(--eduma-primary)] hover:underline"
        >
          Terms of Service
        </Link>{' '}
        and{' '}
        <Link
          to="/legalDocument?id=privacy"
          className="font-semibold text-[var(--eduma-primary)] hover:underline"
        >
          Privacy Policy
        </Link>
        .
      </span>
    </label>
  );
}
