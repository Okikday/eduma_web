export interface AuthUser {
  id: string;
  name: string;
  username?: string | null;
  email: string;
  role?: string | null;
  avatarUrl?: string | null;
  bio?: string | null;
  studyGoal?: string | null;
  school?: string | null;
  fieldOfStudy?: string | null;
  isEmailVerified?: boolean;
  isVerified?: boolean;
  hasVerifiedBadge?: boolean;
  emailVerified?: boolean;
  verified?: boolean;
  referralCode?: string | null;
  plan?: string | null;
  tier?: string | null;
  isPremium?: boolean;
  whatsappLinked?: boolean;
  createdAt?: string | null;
}

export interface AuthTokens {
  accessToken?: string | null;
  refreshToken?: string | null;
  user?: AuthUser | null;
}

export type SignUpStep = 'name' | 'account' | 'photo' | 'referral';

export interface PasswordStrengthInfo {
  level: 'empty' | 'tooShort' | 'weak' | 'fair' | 'good' | 'strong';
  segments: 0 | 1 | 2 | 3 | 4;
  label: string;
  acceptable: boolean;
}

export type UsernameCheck =
  | 'idle'
  | 'checking'
  | 'available'
  | 'taken'
  | 'invalid'
  | 'unknown';

export type AuthLinkKind = 'verify-email' | 'reset-password';

export interface AuthLink {
  kind: AuthLinkKind;
  token: string;
}
