import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import {
  getStorageItem,
  removeStorageItem,
  setStorageItem,
  STORAGE_KEYS,
} from '../storage/storageService';

export type ThemeMode = 'light' | 'dark' | 'system';
export type AppFontKey =
  | 'raleway'
  | 'abeezee'
  | 'agbalumo'
  | 'bellota'
  | 'calsans'
  | 'cause';

export interface FontOption {
  id: AppFontKey;
  label: string;
  preview: string;
}

export const APP_FONT_OPTIONS: readonly FontOption[] = [
  { id: 'raleway', label: 'Raleway', preview: 'Default geometric sans' },
  { id: 'abeezee', label: 'ABeeZee', preview: 'Warm learning sans' },
  { id: 'agbalumo', label: 'Agbalumo', preview: 'Expressive display' },
  { id: 'bellota', label: 'Bellota', preview: 'Rounded literary' },
  { id: 'calsans', label: 'Cal Sans', preview: 'Bold editorial UI' },
  { id: 'cause', label: 'Plus Jakarta', preview: 'Clean humanist' },
];

interface ThemeContextValue {
  themeMode: ThemeMode;
  resolvedTheme: 'light' | 'dark';
  systemScheme: 'light' | 'dark';
  fontFamily: AppFontKey;
  reduceBlur: boolean;
  setThemeMode: (mode: ThemeMode) => void;
  toggleQuickTheme: () => void;
  setFontFamily: (font: AppFontKey) => void;
  setReduceBlur: (reduce: boolean) => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

function readStoredThemeMode(): ThemeMode {
  const raw = getStorageItem(STORAGE_KEYS.themeMode);
  if (raw === 'light' || raw === 'dark') return raw;
  return 'system';
}

function readStoredFont(): AppFontKey {
  const raw = getStorageItem(STORAGE_KEYS.fontFamily);
  if (
    raw === 'raleway' ||
    raw === 'abeezee' ||
    raw === 'agbalumo' ||
    raw === 'bellota' ||
    raw === 'calsans' ||
    raw === 'cause'
  ) {
    return raw;
  }
  return 'raleway';
}

function readSystemDark(): boolean {
  if (typeof window === 'undefined' || !window.matchMedia) return false;
  return window.matchMedia('(prefers-color-scheme: dark)').matches;
}

function applyThemeToDom(mode: ThemeMode, font: AppFontKey, reduceBlur: boolean): void {
  if (typeof document === 'undefined') return;
  const meta = document.querySelector<HTMLMetaElement>('meta[name="color-scheme"]');
  const content = mode === 'system' ? 'light dark' : mode;
  if (meta) {
    meta.setAttribute('content', content);
  }
  document.documentElement.dataset.themeMode = mode;
  document.documentElement.dataset.font = font;
  if (reduceBlur) {
    document.documentElement.dataset.reduceBlur = 'true';
  } else {
    delete document.documentElement.dataset.reduceBlur;
  }
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [themeMode, setThemeModeState] = useState<ThemeMode>(readStoredThemeMode);
  const [systemScheme, setSystemScheme] = useState<'light' | 'dark'>(() =>
    readSystemDark() ? 'dark' : 'light'
  );
  const [fontFamily, setFontFamilyState] = useState<AppFontKey>(readStoredFont);
  const [reduceBlur, setReduceBlurState] = useState<boolean>(
    () => getStorageItem(STORAGE_KEYS.reduceBlur) === 'true'
  );

  // Track OS scheme without erasing a user's stored override when they happen to match.
  useEffect(() => {
    if (!window.matchMedia) return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const onChange = (event: MediaQueryListEvent) => {
      setSystemScheme(event.matches ? 'dark' : 'light');
    };
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);

  // Keep tabs synchronized via the Window storage event.
  useEffect(() => {
    const onStorage = (event: StorageEvent) => {
      if (event.key === STORAGE_KEYS.themeMode) {
        const next =
          event.newValue === 'light' || event.newValue === 'dark'
            ? event.newValue
            : 'system';
        setThemeModeState(next);
      } else if (event.key === STORAGE_KEYS.fontFamily) {
        setFontFamilyState(readStoredFont());
      } else if (event.key === STORAGE_KEYS.reduceBlur) {
        setReduceBlurState(event.newValue === 'true');
      }
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  useEffect(() => {
    applyThemeToDom(themeMode, fontFamily, reduceBlur);
  }, [themeMode, fontFamily, reduceBlur]);

  const resolvedTheme: 'light' | 'dark' =
    themeMode === 'system' ? systemScheme : themeMode;

  const setThemeMode = useCallback((mode: ThemeMode) => {
    setThemeModeState(mode);
    if (mode === 'system') {
      removeStorageItem(STORAGE_KEYS.themeMode);
    } else {
      setStorageItem(STORAGE_KEYS.themeMode, mode);
    }
  }, []);

  const toggleQuickTheme = useCallback(() => {
    const target: 'light' | 'dark' = resolvedTheme === 'dark' ? 'light' : 'dark';
    // Returning to what matches the OS reverts back to system instead of invisibly pinning.
    if (target === systemScheme) {
      setThemeMode('system');
    } else {
      setThemeMode(target);
    }
  }, [resolvedTheme, systemScheme, setThemeMode]);

  const setFontFamily = useCallback((font: AppFontKey) => {
    setFontFamilyState(font);
    setStorageItem(STORAGE_KEYS.fontFamily, font);
  }, []);

  const setReduceBlur = useCallback((reduce: boolean) => {
    setReduceBlurState(reduce);
    setStorageItem(STORAGE_KEYS.reduceBlur, reduce ? 'true' : 'false');
  }, []);

  const value = useMemo<ThemeContextValue>(
    () => ({
      themeMode,
      resolvedTheme,
      systemScheme,
      fontFamily,
      reduceBlur,
      setThemeMode,
      toggleQuickTheme,
      setFontFamily,
      setReduceBlur,
    }),
    [
      themeMode,
      resolvedTheme,
      systemScheme,
      fontFamily,
      reduceBlur,
      setThemeMode,
      toggleQuickTheme,
      setFontFamily,
      setReduceBlur,
    ]
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) {
    throw new Error('useTheme must be used inside ThemeProvider');
  }
  return ctx;
}
