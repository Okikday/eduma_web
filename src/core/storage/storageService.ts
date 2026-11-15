export const STORAGE_KEYS = {
  // Shared Hive kickin_box keys from ../eduma
  accessToken: 'accessToken',
  refreshToken: 'refreshToken',
  profile: 'profile',
  userId: 'userId',
  userRole: 'userRole',
  isUserSignedIn: 'isUserSignedIn',
  seenOnboardingScreens: 'seenOnboardingScreens',
  signedInHereFlag: 'auth_signed_in_here_v1',

  // UI preference keys matching source_parity.md
  spaceCardStyle: 'eduma_pref_space_card_style',
  spaceSort: 'eduma_pref_space_sort',
  spaceContentStyle: 'eduma_pref_space_content_style',
  spaceAssetStyle: 'eduma_pref_space_asset_style',

  // Appearance preferences
  themeMode: 'eduma_theme_mode',
  fontFamily: 'eduma_font_family',
  reduceBlur: 'eduma_reduce_blur',

  // Calendar local flags
  calendarViewMode: 'eduma_pref_calendar_view',
} as const;

export function getStorageItem(key: string): string | null {
  try {
    return window.localStorage.getItem(key);
  } catch {
    return null;
  }
}

export function setStorageItem(key: string, value: string): void {
  try {
    window.localStorage.setItem(key, value);
  } catch {
    // Ignore storage quota or private-mode restrictions.
  }
}

export function removeStorageItem(key: string): void {
  try {
    window.localStorage.removeItem(key);
  } catch {
    // Ignore storage errors.
  }
}

export function readStorageJson<T>(key: string): T | null {
  const raw = getStorageItem(key);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function writeStorageJson(key: string, value: unknown): void {
  try {
    setStorageItem(key, JSON.stringify(value));
  } catch {
    // Ignore serialization errors.
  }
}

export function clearAuthStorage(): void {
  removeStorageItem(STORAGE_KEYS.accessToken);
  removeStorageItem(STORAGE_KEYS.refreshToken);
  removeStorageItem(STORAGE_KEYS.profile);
  removeStorageItem(STORAGE_KEYS.userId);
  removeStorageItem(STORAGE_KEYS.userRole);
  removeStorageItem(STORAGE_KEYS.isUserSignedIn);
  removeStorageItem(STORAGE_KEYS.signedInHereFlag);
}
