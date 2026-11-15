import { useEffect, useState } from 'react';

/**
 * Exact responsive breakpoints ported from `../eduma/lib/shared/components/desktop/form_factor.dart`.
 */
export const MEDIUM_MIN_WIDTH = 600;
export const EXPANDED_MIN_WIDTH = 1024;

export const DesktopWidths = {
  page: 880,
  narrow: 640,
  sheet: 560,
  dialog: 440,
  form: 480,
} as const;

export type FormFactor = 'compact' | 'medium' | 'expanded';

export function getFormFactorForWidth(width: number): FormFactor {
  if (width >= EXPANDED_MIN_WIDTH) return 'expanded';
  if (width >= MEDIUM_MIN_WIDTH) return 'medium';
  return 'compact';
}

export function useViewportWidth(): number {
  const [width, setWidth] = useState<number>(() =>
    typeof window !== 'undefined' ? window.innerWidth : 1280
  );

  useEffect(() => {
    const onResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', onResize, { passive: true });
    return () => window.removeEventListener('resize', onResize);
  }, []);

  return width;
}

export function useFormFactor(): {
  width: number;
  formFactor: FormFactor;
  isCompact: boolean;
  isMedium: boolean;
  isExpanded: boolean;
  isDesktop: boolean;
} {
  const width = useViewportWidth();
  const formFactor = getFormFactorForWidth(width);
  return {
    width,
    formFactor,
    isCompact: formFactor === 'compact',
    isMedium: formFactor === 'medium',
    isExpanded: formFactor === 'expanded',
    isDesktop: formFactor !== 'compact',
  };
}
