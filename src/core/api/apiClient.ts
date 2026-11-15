import { APP_CONFIG } from '../config/appConfig';
import { AppSyncBus } from '../cache/memoryCache';
import {
  clearAuthStorage,
  getStorageItem,
  removeStorageItem,
  setStorageItem,
  STORAGE_KEYS,
  writeStorageJson,
} from '../storage/storageService';

export const UserMessage = {
  from(err: unknown, fallback = 'Something went wrong. Please try again.'): string {
    if (err instanceof ApiError) return err.message || fallback;
    if (err instanceof Error) return err.message || fallback;
    if (typeof err === 'string' && err.trim()) return err.trim();
    return fallback;
  },
};

export interface ExtractedErrorDetails {
  message: string;
  code?: string;
  details?: Record<string, unknown>;
  fieldErrors?: Record<string, string>;
  retryAfter?: number;
}

export class ApiError extends Error {
  readonly status: number;
  readonly code?: string;
  readonly details?: Record<string, unknown>;
  readonly fieldErrors?: Record<string, string>;
  readonly retryAfter?: number;
  readonly payload?: unknown;

  constructor(
    message: string,
    status: number,
    options?: {
      code?: string;
      details?: Record<string, unknown>;
      fieldErrors?: Record<string, string>;
      retryAfter?: number;
      payload?: unknown;
    }
  ) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = options?.code;
    this.details = options?.details;
    this.fieldErrors = options?.fieldErrors;
    this.retryAfter = options?.retryAfter;
    this.payload = options?.payload;
  }
}

function asRecord(val: unknown): Record<string, unknown> | null {
  return val && typeof val === 'object' && !Array.isArray(val)
    ? (val as Record<string, unknown>)
    : null;
}

function parseFieldErrorsMap(raw: unknown): Record<string, string> | undefined {
  const map = asRecord(raw);
  if (!map) return undefined;
  const out: Record<string, string> = {};
  for (const [key, val] of Object.entries(map)) {
    if (typeof val === 'string' && val.trim()) {
      out[key] = val.trim();
    } else if (Array.isArray(val)) {
      const first = val.find((item) => typeof item === 'string' && item.trim());
      if (typeof first === 'string') out[key] = first.trim();
    }
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

function firstArrayError(raw: unknown): string | null {
  if (!Array.isArray(raw)) return null;
  for (const item of raw) {
    if (typeof item === 'string' && item.trim()) return item.trim();
    const rec = asRecord(item);
    if (rec && typeof rec.message === 'string' && rec.message.trim()) {
      return rec.message.trim();
    }
  }
  return null;
}

function parseRetryAfter(val: unknown): number | undefined {
  if (typeof val === 'number' && Number.isFinite(val) && val > 0) {
    return Math.round(val);
  }
  if (typeof val === 'string' && val.trim()) {
    const n = Number(val.trim());
    if (Number.isFinite(n) && n > 0) return Math.round(n);
  }
  return undefined;
}

function defaultStatusMessage(statusCode: number): string {
  if (statusCode === 0) return 'Unable to connect right now. Check your internet connection.';
  if (statusCode === 401) return 'Your session has expired. Please sign in again.';
  if (statusCode === 403) return 'You do not have permission for this action.';
  if (statusCode === 404) return 'That resource could not be found.';
  if (statusCode === 429) return 'Too many requests. Please wait a moment and try again.';
  if (statusCode >= 500) return 'Server error. Please try again in a moment.';
  return `Request failed (${statusCode}).`;
}

export function extractErrorDetails(
  payload: unknown,
  statusCode: number
): ExtractedErrorDetails {
  if (typeof payload === 'string' && payload.trim()) {
    return { message: payload.trim() };
  }

  const root = asRecord(payload);
  if (!root) {
    return { message: defaultStatusMessage(statusCode) };
  }

  const nestedError = asRecord(root.error);
  const details =
    asRecord(nestedError?.details) ??
    asRecord(root.details) ??
    undefined;

  const codeRaw = nestedError?.code ?? root.code;
  const code =
    typeof codeRaw === 'string' && codeRaw.trim()
      ? codeRaw.trim()
      : undefined;

  const fieldErrors =
    parseFieldErrorsMap(details?.fieldErrors) ??
    parseFieldErrorsMap(nestedError?.fieldErrors) ??
    parseFieldErrorsMap(root.fieldErrors);

  const firstFieldMsg = fieldErrors ? Object.values(fieldErrors)[0] : undefined;

  const rawMsgCandidates = [
    nestedError?.message,
    typeof root.error === 'string' ? root.error : undefined,
    root.message,
    firstArrayError(nestedError?.errors),
    firstArrayError(root.errors),
  ];

  let message = '';
  for (const cand of rawMsgCandidates) {
    if (typeof cand === 'string' && cand.trim()) {
      message = cand.trim();
      break;
    }
  }

  const isGenericValidationMsg =
    !message || /^(validation failed|invalid input|bad request)$/i.test(message);

  if (isGenericValidationMsg && firstFieldMsg) {
    message = firstFieldMsg;
  }

  if (!message) {
    message = defaultStatusMessage(statusCode);
  }

  const retryAfter =
    parseRetryAfter(details?.retryAfter) ??
    parseRetryAfter(nestedError?.retryAfter) ??
    parseRetryAfter(root.retryAfter);

  return {
    message,
    code,
    details,
    fieldErrors,
    retryAfter,
  };
}

export function extractErrorMessage(payload: unknown, statusCode: number): string {
  return extractErrorDetails(payload, statusCode).message;
}

export function unwrapData<T>(payload: unknown): T {
  const rec = asRecord(payload);
  if (rec && 'data' in rec && rec.data !== undefined) {
    return rec.data as T;
  }
  return payload as T;
}

export interface RequestOptions {
  params?: Record<string, string | number | boolean | undefined | null>;
  headers?: Record<string, string>;
  skipAuth?: boolean;
  skipAuthRefresh?: boolean;
  unwrap?: boolean;
  timeoutMs?: number;
}

function buildUrl(
  path: string,
  params?: Record<string, string | number | boolean | undefined | null>
): string {
  const base = path.startsWith('http')
    ? path
    : `${APP_CONFIG.apiBaseUrl}${path.startsWith('/') ? path : `/${path}`}`;

  if (!params) return base;
  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') {
      qs.set(k, String(v));
    }
  }
  const queryStr = qs.toString();
  if (!queryStr) return base;
  return `${base}${base.includes('?') ? '&' : '?'}${queryStr}`;
}

async function parseResponseBody(response: Response): Promise<unknown> {
  const contentType = response.headers.get('content-type') || '';
  if (response.status === 204) return null;
  if (contentType.includes('application/json')) {
    return response.json().catch(() => null);
  }
  const text = await response.text().catch(() => '');
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

let inFlightRefresh: Promise<boolean> | null = null;

export function persistRefreshTokensPayload(payload: unknown): {
  accessToken: string;
  refreshToken: string;
  user?: Record<string, unknown>;
} | null {
  const unwrapped = asRecord(unwrapData<unknown>(payload)) ?? asRecord(payload);
  if (!unwrapped) return null;

  const sessionObj = asRecord(unwrapped.session);
  const tokensObj = asRecord(unwrapped.tokens);
  const accessToken = String(
    sessionObj?.accessToken ??
      tokensObj?.accessToken ??
      unwrapped.accessToken ??
      ''
  ).trim();
  const refreshToken = String(
    sessionObj?.refreshToken ??
      tokensObj?.refreshToken ??
      unwrapped.refreshToken ??
      ''
  ).trim();
  const user = asRecord(unwrapped.user) ?? asRecord(sessionObj?.user) ?? undefined;

  if (!accessToken) return null;

  setStorageItem(STORAGE_KEYS.accessToken, accessToken);
  if (refreshToken) {
    setStorageItem(STORAGE_KEYS.refreshToken, refreshToken);
  }
  if (user) {
    writeStorageJson(STORAGE_KEYS.profile, user);
  }

  return { accessToken, refreshToken, user };
}

export async function refreshAccessToken(): Promise<boolean> {
  if (inFlightRefresh) return inFlightRefresh;

  inFlightRefresh = (async () => {
    const refreshToken = getStorageItem(STORAGE_KEYS.refreshToken);
    try {
      const res = await fetch(buildUrl('/auth/refresh'), {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify(refreshToken ? { refreshToken } : {}),
      });

      const parsed = await parseResponseBody(res);
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          removeStorageItem(STORAGE_KEYS.accessToken);
          removeStorageItem(STORAGE_KEYS.refreshToken);
        }
        return false;
      }

      const saved = persistRefreshTokensPayload(parsed);
      return Boolean(saved?.accessToken);
    } catch {
      return false;
    } finally {
      inFlightRefresh = null;
    }
  })();

  return inFlightRefresh;
}

async function executeRequest<T>(
  method: string,
  path: string,
  body?: unknown,
  options: RequestOptions = {},
  attempt = 0
): Promise<T> {
  const controller = new AbortController();
  const timeoutId = window.setTimeout(
    () => controller.abort(),
    options.timeoutMs ?? APP_CONFIG.requestTimeoutMs
  );

  const isFormData = typeof FormData !== 'undefined' && body instanceof FormData;
  const headers: Record<string, string> = {
    Accept: 'application/json',
    ...(!isFormData && body !== undefined ? { 'Content-Type': 'application/json' } : {}),
    ...(options.headers || {}),
  };

  if (!options.skipAuth) {
    const token = getStorageItem(STORAGE_KEYS.accessToken);
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }
  }

  let response: Response;
  try {
    response = await fetch(buildUrl(path, options.params), {
      method,
      headers,
      credentials: 'include',
      signal: controller.signal,
      body:
        body === undefined
          ? undefined
          : isFormData
          ? (body as FormData)
          : JSON.stringify(body),
    });
  } catch (err) {
    window.clearTimeout(timeoutId);
    if (err instanceof DOMException && err.name === 'AbortError') {
      throw new ApiError('Request timed out. Please try again.', 408);
    }
    throw new ApiError(
      'Unable to reach Eduma servers. Check your internet connection.',
      0
    );
  }
  window.clearTimeout(timeoutId);

  if (
    response.status === 401 &&
    attempt === 0 &&
    !options.skipAuth &&
    !options.skipAuthRefresh &&
    !path.includes('/auth/login') &&
    !path.includes('/auth/register') &&
    !path.includes('/auth/refresh') &&
    !path.includes('/auth/google')
  ) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      return executeRequest<T>(method, path, body, options, 1);
    }
    clearAuthStorage();
    AppSyncBus.emit('auth:expired');
  }

  const parsed = await parseResponseBody(response);

  if (!response.ok) {
    const extracted = extractErrorDetails(parsed, response.status);
    const retryHeader = response.headers.get('retry-after');
    const retryAfter =
      extracted.retryAfter ??
      (retryHeader ? parseRetryAfter(retryHeader) : undefined);

    throw new ApiError(extracted.message, response.status, {
      code: extracted.code,
      details: extracted.details,
      fieldErrors: extracted.fieldErrors,
      retryAfter,
      payload: parsed,
    });
  }

  return options.unwrap === false ? (parsed as T) : unwrapData<T>(parsed);
}

export const apiClient = {
  get: <T>(path: string, options?: RequestOptions) =>
    executeRequest<T>('GET', path, undefined, options),

  post: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    executeRequest<T>('POST', path, body, options),

  put: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    executeRequest<T>('PUT', path, body, options),

  patch: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    executeRequest<T>('PATCH', path, body, options),

  delete: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    executeRequest<T>('DELETE', path, body, options),

  buildUrl,
};
