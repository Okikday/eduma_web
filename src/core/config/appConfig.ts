export const APP_CONFIG = {
  apiBaseUrl:
    import.meta.env.VITE_EDUMA_API_BASE_URL ||
    'https://eduma-backend1.onrender.com/api/v1',
  flutterAppUrl:
    import.meta.env.VITE_EDUMA_FLUTTER_APP_URL || 'https://app.eduma.com.ng',
  googleWebClientId:
    import.meta.env.VITE_EDUMA_GOOGLE_WEB_CLIENT_ID || '',
  requestTimeoutMs: 25_000,
} as const;

/**
 * Normalizes backend URLs rewritten from legacy hosts (`eduma.com.ng`,
 * `app.eduma.com.ng`) and relative API paths into full URLs targeting the
 * configured API origin. Matches `AppConfig.normalizeApiUrl` in `../eduma`.
 */
export function normalizeApiUrl(rawUrl?: string | null): string {
  if (!rawUrl) return '';
  const trimmed = rawUrl.trim();
  if (!trimmed) return '';

  const base = APP_CONFIG.apiBaseUrl.replace(/\/+$/, '');
  const origin = base.replace(/\/api\/v1$/, '');

  const legacyPrefixes = [
    'https://eduma.com.ng/api/v1',
    'http://eduma.com.ng/api/v1',
    'https://www.eduma.com.ng/api/v1',
    'https://app.eduma.com.ng/api/v1',
    'http://app.eduma.com.ng/api/v1',
  ];

  for (const prefix of legacyPrefixes) {
    if (trimmed.startsWith(prefix)) {
      return `${base}${trimmed.slice(prefix.length)}`;
    }
  }

  if (trimmed.startsWith('/api/v1')) {
    return `${base}${trimmed.slice('/api/v1'.length)}`;
  }

  if (trimmed.startsWith('/uploads/') || trimmed.startsWith('/assets/')) {
    if (trimmed.startsWith('/assets/')) return trimmed;
    return `${origin}${trimmed}`;
  }

  if (trimmed.startsWith('/')) {
    return `${base}${trimmed}`;
  }

  return trimmed;
}

/**
 * Constructs a deep link into the full Flutter Canvas app for interactive
 * freehand / Apple Pencil / node canvas editing of a specific space page.
 */
export function buildFlutterCanvasUrl(params: {
  pageId: string;
  spaceId: string;
}): string {
  const host = APP_CONFIG.flutterAppUrl.replace(/\/+$/, '');
  const search = new URLSearchParams({
    id: params.pageId,
    spaceId: params.spaceId,
  });
  return `${host}/spacePageCanvas?${search.toString()}`;
}
