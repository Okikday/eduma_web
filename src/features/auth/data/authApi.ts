import { apiClient, persistRefreshTokensPayload } from '../../../core/api/apiClient';
import { normalizeApiUrl } from '../../../core/config/appConfig';
import { getStorageItem, STORAGE_KEYS } from '../../../core/storage/storageService';
import type { AuthTokens, AuthUser } from '../models/authModels';

function asRecord(val: unknown): Record<string, unknown> | null {
  return val && typeof val === 'object' && !Array.isArray(val)
    ? (val as Record<string, unknown>)
    : null;
}

function readAvatar(userObj: Record<string, unknown>): string | null {
  const raw =
    userObj.profilePic ??
    userObj.profilePicture ??
    userObj.avatarUrl ??
    userObj.avatar ??
    userObj.photoUrl;
  if (typeof raw !== 'string' || !raw.trim()) return null;
  const trimmed = raw.trim();
  return trimmed.startsWith('http') || trimmed.startsWith('blob:') || trimmed.startsWith('data:')
    ? normalizeApiUrl(trimmed)
    : trimmed;
}

export function normalizeUser(raw: unknown): AuthUser | null {
  const rec = asRecord(raw);
  if (!rec) return null;

  const userObj = asRecord(rec.user) ?? rec;
  const id = String(userObj.id || userObj._id || userObj.userId || '').trim();
  const email = String(userObj.email || '').trim();
  if (!id && !email) return null;

  const learner = asRecord(userObj.learner);
  const emailVerified = Boolean(
    userObj.isEmailVerified ??
      userObj.emailVerified ??
      userObj.isVerified ??
      userObj.verified ??
      false
  );
  const badgeVerified = Boolean(userObj.isVerified ?? false);

  return {
    id,
    name: String(userObj.name || userObj.fullName || 'Student'),
    username: typeof userObj.username === 'string' ? userObj.username : null,
    email,
    role: typeof userObj.role === 'string' ? userObj.role : 'student',
    avatarUrl: readAvatar(userObj),
    bio: typeof userObj.bio === 'string' ? userObj.bio : null,
    studyGoal:
      typeof userObj.studyGoal === 'string'
        ? userObj.studyGoal
        : typeof learner?.studyGoal === 'string'
        ? learner.studyGoal
        : null,
    school:
      typeof userObj.school === 'string'
        ? userObj.school
        : typeof learner?.school === 'string'
        ? learner.school
        : null,
    fieldOfStudy:
      typeof userObj.fieldOfStudy === 'string'
        ? userObj.fieldOfStudy
        : typeof learner?.fieldOfStudy === 'string'
        ? learner.fieldOfStudy
        : null,
    isEmailVerified: emailVerified,
    isVerified: Boolean(
      userObj.isEmailVerified ??
        userObj.isVerified ??
        userObj.emailVerified ??
        userObj.verified ??
        false
    ),
    hasVerifiedBadge: badgeVerified,
    emailVerified,
    verified: Boolean(userObj.verified ?? emailVerified),
    referralCode:
      typeof userObj.referralCode === 'string' ? userObj.referralCode : null,
    plan: typeof userObj.plan === 'string' ? userObj.plan : null,
    tier: typeof userObj.tier === 'string' ? userObj.tier : null,
    isPremium: Boolean(
      userObj.isPremium ||
        userObj.plan === 'pro' ||
        userObj.plan === 'premium' ||
        userObj.tier === 'pro'
    ),
    whatsappLinked: Boolean(userObj.whatsappLinked ?? false),
    createdAt: typeof userObj.createdAt === 'string' ? userObj.createdAt : null,
  };
}

export function extractAuthTokens(payload: unknown): AuthTokens {
  const rec = asRecord(payload);
  if (!rec) return {};

  const session = asRecord(rec.session);
  const tokens = asRecord(rec.tokens);

  const accessToken =
    (typeof rec.accessToken === 'string' && rec.accessToken) ||
    (typeof rec.token === 'string' && rec.token) ||
    (typeof session?.accessToken === 'string' && session.accessToken) ||
    (typeof tokens?.accessToken === 'string' && tokens.accessToken) ||
    null;

  const refreshToken =
    (typeof rec.refreshToken === 'string' && rec.refreshToken) ||
    (typeof session?.refreshToken === 'string' && session.refreshToken) ||
    (typeof tokens?.refreshToken === 'string' && tokens.refreshToken) ||
    null;

  const user =
    normalizeUser(rec.user) ??
    normalizeUser(session?.user) ??
    normalizeUser(rec);

  return { accessToken, refreshToken, user };
}

export const authApi = {
  async login(input: {
    email: string;
    password: string;
    termsAccepted?: boolean;
  }): Promise<AuthTokens> {
    const res = await apiClient.post<unknown>(
      '/auth/login',
      {
        email: input.email.trim(),
        password: input.password,
        termsAccepted: input.termsAccepted ?? true,
      },
      { skipAuth: true, skipAuthRefresh: true }
    );
    return extractAuthTokens(res);
  },

  async register(input: {
    name: string;
    username: string;
    email: string;
    password: string;
    referralCode?: string;
    termsAccepted?: boolean;
  }): Promise<AuthTokens> {
    const payload: Record<string, unknown> = {
      name: input.name.trim(),
      email: input.email.trim(),
      password: input.password,
      termsAccepted: input.termsAccepted ?? true,
    };
    if (input.username.trim()) payload.username = input.username.trim();
    if (input.referralCode?.trim()) {
      payload.referralCode = input.referralCode.trim();
    }

    const res = await apiClient.post<unknown>('/auth/register', payload, {
      skipAuth: true,
      skipAuthRefresh: true,
    });
    return extractAuthTokens(res);
  },

  async googleSignIn(input: {
    idToken?: string;
    accessToken?: string;
    referralCode?: string;
    termsAccepted?: boolean;
  }): Promise<AuthTokens> {
    const payload: Record<string, unknown> = {
      termsAccepted: input.termsAccepted ?? true,
    };
    if (input.idToken) {
      payload.idToken = input.idToken;
      payload.token = input.idToken;
    }
    if (input.accessToken) {
      payload.accessToken = input.accessToken;
    }
    if (input.referralCode?.trim()) {
      payload.referralCode = input.referralCode.trim();
    }
    const res = await apiClient.post<unknown>('/auth/google', payload, {
      skipAuth: true,
      skipAuthRefresh: true,
    });
    return extractAuthTokens(res);
  },

  async refreshSession(): Promise<AuthTokens | null> {
    const refreshToken = getStorageItem(STORAGE_KEYS.refreshToken);
    const res = await apiClient.post<unknown>(
      '/auth/refresh',
      refreshToken ? { refreshToken } : {},
      { skipAuth: true, skipAuthRefresh: true }
    );
    persistRefreshTokensPayload(res);
    return extractAuthTokens(res);
  },

  async me(): Promise<AuthUser | null> {
    const res = await apiClient.get<unknown>('/auth/me');
    return normalizeUser(res);
  },

  async logout(): Promise<void> {
    const refreshToken = getStorageItem(STORAGE_KEYS.refreshToken);
    await apiClient
      .post('/auth/logout', refreshToken ? { refreshToken } : {})
      .catch(() => null);
  },

  async logoutAll(): Promise<void> {
    await apiClient.post('/auth/logout-all', {});
  },

  async forgotPassword(email: string): Promise<void> {
    await apiClient.post(
      '/auth/forgot-password',
      { email: email.trim() },
      { skipAuth: true }
    );
  },

  async resetPassword(input: {
    token?: string;
    code?: string;
    email?: string;
    newPassword: string;
  }): Promise<void> {
    await apiClient.post(
      '/auth/reset-password',
      {
        ...(input.token ? { token: input.token } : {}),
        ...(input.code ? { code: input.code } : {}),
        ...(input.email ? { email: input.email.trim() } : {}),
        password: input.newPassword,
        newPassword: input.newPassword,
      },
      { skipAuth: true }
    );
  },

  async verifyEmail(input: {
    code?: string;
    token?: string;
    email?: string;
  }): Promise<AuthTokens> {
    const body = input.token
      ? { token: input.token }
      : {
          code: input.code,
          ...(input.email?.trim() ? { email: input.email.trim() } : {}),
        };
    const res = await apiClient.post<unknown>('/auth/verify-email', body);
    return extractAuthTokens(res);
  },

  async resendVerification(email?: string): Promise<void> {
    const trimmed = email?.trim();
    if (trimmed) {
      await apiClient.post('/auth/verify-email/resend-by-email', {
        email: trimmed,
      });
    } else {
      await apiClient.post('/auth/verify-email/resend', {});
    }
  },

  async checkUsername(
    username: string
  ): Promise<{ available: boolean; suggestions: string[] }> {
    const res = await apiClient.get<{
      available?: boolean;
      suggestions?: string[];
    }>('/users/username-available', {
      params: { username },
      skipAuth: true,
    });
    return {
      available: Boolean(res?.available),
      suggestions: Array.isArray(res?.suggestions) ? res.suggestions : [],
    };
  },

  async lookupReferral(
    code: string
  ): Promise<{ valid: boolean; referrerName?: string | null } | null> {
    try {
      const res = await apiClient.get<Record<string, unknown>>(
        `/referrals/${encodeURIComponent(code)}`,
        { skipAuth: true }
      );
      const referrer =
        res.referrer && typeof res.referrer === 'object'
          ? (res.referrer as Record<string, unknown>)
          : null;
      return {
        valid: Boolean(res.valid ?? referrer ?? res.referrerName ?? true),
        referrerName:
          typeof res.referrerName === 'string'
            ? res.referrerName
            : typeof referrer?.name === 'string'
            ? referrer.name
            : null,
      };
    } catch {
      return null;
    }
  },

  async uploadAvatar(file: File): Promise<AuthUser | null> {
    const fd = new FormData();
    fd.append('avatar', file);
    const res = await apiClient.post<unknown>('/users/me/avatar', fd);
    return normalizeUser(res);
  },
};
