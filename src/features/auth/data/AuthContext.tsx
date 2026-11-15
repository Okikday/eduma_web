import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { ApiError } from '../../../core/api/apiClient';
import { AppSyncBus, SessionReset } from '../../../core/cache/memoryCache';
import {
  clearAuthStorage,
  getStorageItem,
  readStorageJson,
  setStorageItem,
  STORAGE_KEYS,
  writeStorageJson,
} from '../../../core/storage/storageService';
import type { AuthTokens, AuthUser } from '../models/authModels';
import { authApi, extractAuthTokens, normalizeUser } from './authApi';

export interface AuthActionResult {
  ok: boolean;
  needsVerification?: boolean;
  email?: string;
}

interface AuthContextValue {
  user: AuthUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  pendingVerificationEmail: string | null;
  hasSignedInBefore: boolean;
  clearError: () => void;
  signIn: (
    email: string,
    password: string,
    options?: { termsAccepted?: boolean }
  ) => Promise<AuthActionResult>;
  signUp: (input: {
    name: string;
    username: string;
    email: string;
    password: string;
    referralCode?: string;
    avatarFile?: File | null;
    termsAccepted?: boolean;
  }) => Promise<AuthActionResult>;
  signInWithGoogle: (
    idToken: string,
    referralCode?: string,
    termsAccepted?: boolean
  ) => Promise<AuthActionResult>;
  verifyEmail: (input: {
    code?: string;
    email?: string;
    token?: string;
  }) => Promise<boolean>;
  refreshProfile: () => Promise<AuthUser | null>;
  updateLocalUser: (next: AuthUser) => void;
  logout: () => Promise<void>;
  logoutAll: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function isUserEmailVerified(user: AuthUser | null): boolean {
  if (!user) return false;
  return Boolean(
    user.isEmailVerified ?? user.emailVerified ?? user.isVerified ?? user.verified
  );
}

function persistSession(tokens: AuthTokens): AuthUser | null {
  if (tokens.accessToken) {
    setStorageItem(STORAGE_KEYS.accessToken, tokens.accessToken);
  }
  if (tokens.refreshToken) {
    setStorageItem(STORAGE_KEYS.refreshToken, tokens.refreshToken);
  }
  setStorageItem(STORAGE_KEYS.isUserSignedIn, 'true');
  setStorageItem(STORAGE_KEYS.signedInHereFlag, '1');

  if (tokens.user) {
    setStorageItem(STORAGE_KEYS.userId, tokens.user.id);
    if (tokens.user.role) {
      setStorageItem(STORAGE_KEYS.userRole, tokens.user.role);
    }
    writeStorageJson(STORAGE_KEYS.profile, tokens.user);
    return tokens.user;
  }
  return null;
}

function extractPendingVerification(
  err: unknown,
  fallbackEmail?: string
): { email: string; session: AuthTokens } | null {
  if (!(err instanceof ApiError)) return null;
  const isUnverified =
    err.status === 403 &&
    (err.code?.toUpperCase() === 'EMAIL_NOT_VERIFIED' ||
      /verify/i.test(err.message));
  if (!isUnverified) return null;

  const details = err.details ?? {};
  const session = extractAuthTokens(details);
  const pendingUser = session.user ?? normalizeUser(details.user) ?? normalizeUser(details);
  const email = (pendingUser?.email || fallbackEmail || '').trim();

  return {
    email,
    session: {
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: pendingUser,
    },
  };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() => {
    const hasSessionHint =
      Boolean(getStorageItem(STORAGE_KEYS.accessToken)) ||
      getStorageItem(STORAGE_KEYS.isUserSignedIn) === 'true';
    if (!hasSessionHint) return null;
    const raw = readStorageJson<Record<string, unknown>>(STORAGE_KEYS.profile);
    return normalizeUser(raw);
  });
  const [isLoading, setIsLoading] = useState<boolean>(() => {
    return (
      Boolean(getStorageItem(STORAGE_KEYS.accessToken)) ||
      Boolean(getStorageItem(STORAGE_KEYS.refreshToken)) ||
      getStorageItem(STORAGE_KEYS.isUserSignedIn) === 'true' ||
      getStorageItem(STORAGE_KEYS.signedInHereFlag) === '1'
    );
  });
  const [error, setError] = useState<string | null>(null);
  const [pendingVerificationEmail, setPendingVerificationEmail] = useState<string | null>(
    null
  );

  const clearError = useCallback(() => setError(null), []);

  const refreshProfile = useCallback(async (): Promise<AuthUser | null> => {
    try {
      const fresh = await authApi.me();
      if (fresh) {
        setUser(fresh);
        setStorageItem(STORAGE_KEYS.userId, fresh.id);
        setStorageItem(STORAGE_KEYS.isUserSignedIn, 'true');
        writeStorageJson(STORAGE_KEYS.profile, fresh);
        return fresh;
      }
      return null;
    } catch (err) {
      if (err instanceof ApiError && (err.status === 401 || err.status === 403)) {
        clearAuthStorage();
        setUser(null);
      }
      return null;
    }
  }, []);

  useEffect(() => {
    const token = getStorageItem(STORAGE_KEYS.accessToken);
    const refreshToken = getStorageItem(STORAGE_KEYS.refreshToken);
    const signedInHint =
      getStorageItem(STORAGE_KEYS.isUserSignedIn) === 'true' ||
      getStorageItem(STORAGE_KEYS.signedInHereFlag) === '1';

    if (!token && !refreshToken && !signedInHint) {
      setIsLoading(false);
      return;
    }

    let cancelled = false;
    (async () => {
      try {
        let restoredUser: AuthUser | null = null;
        if (token) {
          restoredUser = await authApi.me().catch((err) => {
            if (err instanceof ApiError && err.status === 401) return null;
            throw err;
          });
        }

        if (!restoredUser) {
          const refreshed = await authApi.refreshSession().catch(() => null);
          if (refreshed?.accessToken) {
            restoredUser = persistSession(refreshed);
            if (!restoredUser) {
              restoredUser = await authApi.me().catch(() => null);
            }
          }
        }

        if (cancelled) return;
        if (restoredUser) {
          setUser(restoredUser);
          setStorageItem(STORAGE_KEYS.userId, restoredUser.id);
          setStorageItem(STORAGE_KEYS.isUserSignedIn, 'true');
          writeStorageJson(STORAGE_KEYS.profile, restoredUser);
        } else {
          // If server affirmatively rejected session, clear stored tokens
          clearAuthStorage();
          setUser(null);
        }
      } catch (err) {
        if (!cancelled && err instanceof ApiError && (err.status === 401 || err.status === 403)) {
          clearAuthStorage();
          setUser(null);
        }
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    })();

    const unsub = AppSyncBus.subscribe('auth:expired', () => {
      SessionReset.resetAll();
      clearAuthStorage();
      setUser(null);
    });

    return () => {
      cancelled = true;
      unsub();
    };
  }, []);

  const signIn = useCallback(
    async (
      email: string,
      password: string,
      options?: { termsAccepted?: boolean }
    ): Promise<AuthActionResult> => {
      setError(null);
      try {
        const session = await authApi.login({
          email,
          password,
          termsAccepted: options?.termsAccepted ?? true,
        });
        let currentUser = persistSession(session);
        if (!currentUser) {
          currentUser = await refreshProfile();
        } else {
          setUser(currentUser);
        }
        AppSyncBus.emit('auth:changed', currentUser);
        const needsVerification = currentUser
          ? !isUserEmailVerified(currentUser)
          : false;
        if (needsVerification) {
          setPendingVerificationEmail(currentUser?.email || email.trim());
        } else {
          setPendingVerificationEmail(null);
        }
        return {
          ok: true,
          needsVerification,
          email: currentUser?.email || email.trim(),
        };
      } catch (err) {
        const pending = extractPendingVerification(err, email);
        if (pending) {
          if (pending.session.accessToken || pending.session.user) {
            const u = persistSession(pending.session);
            if (u) setUser(u);
          }
          setPendingVerificationEmail(pending.email);
          setError(null);
          return {
            ok: true,
            needsVerification: true,
            email: pending.email,
          };
        }

        setError(
          err instanceof Error
            ? err.message
            : 'Unable to sign in. Please check your credentials.'
        );
        return { ok: false };
      }
    },
    [refreshProfile]
  );

  const signUp = useCallback(
    async (input: {
      name: string;
      username: string;
      email: string;
      password: string;
      referralCode?: string;
      avatarFile?: File | null;
      termsAccepted?: boolean;
    }): Promise<AuthActionResult> => {
      setError(null);
      try {
        const session = await authApi.register({
          name: input.name,
          username: input.username,
          email: input.email,
          password: input.password,
          referralCode: input.referralCode,
          termsAccepted: input.termsAccepted ?? true,
        });
        let currentUser = persistSession(session);

        if (input.avatarFile && session.accessToken) {
          const updated = await authApi.uploadAvatar(input.avatarFile).catch(() => null);
          if (updated) {
            currentUser = updated;
            writeStorageJson(STORAGE_KEYS.profile, updated);
          }
        }

        if (!currentUser && session.accessToken) {
          currentUser = await refreshProfile();
        } else if (currentUser) {
          setUser(currentUser);
        }

        AppSyncBus.emit('auth:changed', currentUser);
        const needsVerification = currentUser
          ? !isUserEmailVerified(currentUser)
          : true;
        if (needsVerification) {
          setPendingVerificationEmail(currentUser?.email || input.email.trim());
        } else {
          setPendingVerificationEmail(null);
        }
        return {
          ok: true,
          needsVerification,
          email: currentUser?.email || input.email.trim(),
        };
      } catch (err) {
        const pending = extractPendingVerification(err, input.email);
        if (pending) {
          if (pending.session.accessToken || pending.session.user) {
            const u = persistSession(pending.session);
            if (u) setUser(u);
          }
          setPendingVerificationEmail(pending.email);
          setError(null);
          return {
            ok: true,
            needsVerification: true,
            email: pending.email,
          };
        }

        setError(
          err instanceof Error
            ? err.message
            : 'Could not create your account right now.'
        );
        return { ok: false };
      }
    },
    [refreshProfile]
  );

  const signInWithGoogle = useCallback(
    async (
      idToken: string,
      referralCode?: string,
      termsAccepted = true
    ): Promise<AuthActionResult> => {
      setError(null);
      try {
        const session = await authApi.googleSignIn({
          idToken,
          referralCode,
          termsAccepted,
        });
        let currentUser = persistSession(session);
        if (!currentUser) {
          currentUser = await refreshProfile();
        } else {
          setUser(currentUser);
        }
        AppSyncBus.emit('auth:changed', currentUser);
        const needsVerification = currentUser
          ? !isUserEmailVerified(currentUser)
          : false;
        if (needsVerification) {
          setPendingVerificationEmail(currentUser?.email || null);
        }
        return {
          ok: true,
          needsVerification,
          email: currentUser?.email,
        };
      } catch (err) {
        const pending = extractPendingVerification(err);
        if (pending) {
          if (pending.session.accessToken || pending.session.user) {
            const u = persistSession(pending.session);
            if (u) setUser(u);
          }
          setPendingVerificationEmail(pending.email);
          setError(null);
          return { ok: true, needsVerification: true, email: pending.email };
        }
        setError(
          err instanceof Error
            ? err.message
            : 'Google sign-in could not be completed.'
        );
        return { ok: false };
      }
    },
    [refreshProfile]
  );

  const verifyEmail = useCallback(
    async (input: {
      code?: string;
      email?: string;
      token?: string;
    }): Promise<boolean> => {
      setError(null);
      try {
        const session = await authApi.verifyEmail(input);
        let currentUser = persistSession(session);
        if (!currentUser && getStorageItem(STORAGE_KEYS.accessToken)) {
          currentUser = await refreshProfile();
        } else if (currentUser) {
          setUser({
            ...currentUser,
            isEmailVerified: true,
            emailVerified: true,
            isVerified: currentUser.isVerified ?? true,
          });
        }
        setPendingVerificationEmail(null);
        AppSyncBus.emit('auth:changed', currentUser);
        return true;
      } catch (err) {
        setError(
          err instanceof Error
            ? err.message
            : 'That verification code is invalid or expired.'
        );
        return false;
      }
    },
    [refreshProfile]
  );

  const updateLocalUser = useCallback((next: AuthUser) => {
    setUser(next);
    writeStorageJson(STORAGE_KEYS.profile, next);
  }, []);

  const logout = useCallback(async () => {
    await authApi.logout();
    SessionReset.resetAll();
    clearAuthStorage();
    setPendingVerificationEmail(null);
    setUser(null);
    AppSyncBus.emit('auth:changed', null);
  }, []);

  const logoutAll = useCallback(async () => {
    await authApi.logoutAll();
    SessionReset.resetAll();
    clearAuthStorage();
    setPendingVerificationEmail(null);
    setUser(null);
    AppSyncBus.emit('auth:changed', null);
  }, []);

  const hasSignedInBefore =
    getStorageItem(STORAGE_KEYS.signedInHereFlag) === '1' ||
    getStorageItem(STORAGE_KEYS.isUserSignedIn) === 'true';

  const isAuthenticated = Boolean(
    user ||
      getStorageItem(STORAGE_KEYS.accessToken) ||
      getStorageItem(STORAGE_KEYS.isUserSignedIn) === 'true'
  );

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated,
      isLoading,
      error,
      pendingVerificationEmail,
      hasSignedInBefore,
      clearError,
      signIn,
      signUp,
      signInWithGoogle,
      verifyEmail,
      refreshProfile,
      updateLocalUser,
      logout,
      logoutAll,
    }),
    [
      user,
      isAuthenticated,
      isLoading,
      error,
      pendingVerificationEmail,
      hasSignedInBefore,
      clearError,
      signIn,
      signUp,
      signInWithGoogle,
      verifyEmail,
      refreshProfile,
      updateLocalUser,
      logout,
      logoutAll,
    ]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
