import type { AuthLink, AuthLinkKind } from '../models/authModels';

const TOKEN_PATTERN = /^[A-Za-z0-9\-_.~+/=%]+$/;
const REFERRAL_ALLOWED = /^[A-Za-z0-9._-]{3,40}$/;

function tryParseUrl(raw: string): URL | null {
  try {
    return new URL(raw, 'https://app.eduma.com.ng');
  } catch {
    return null;
  }
}

function getCandidateUrls(rawUrl: string): URL[] {
  const parsed = tryParseUrl(rawUrl);
  if (!parsed) return [];
  const list = [parsed];
  const hash = parsed.hash.replace(/^#/, '');
  if (hash) {
    const hashUrl = tryParseUrl(hash.startsWith('/') ? hash : `/${hash}`);
    if (hashUrl) list.push(hashUrl);
  }
  return list;
}

export const AuthLinkLogic = {
  cleanToken(raw?: string | null): string | null {
    const t = raw?.trim();
    if (!t || t.length < 6 || t.length > 2048) return null;
    return TOKEN_PATTERN.test(t) ? t : null;
  },

  parseUrl(rawUrl: string): AuthLink | null {
    for (const u of getCandidateUrls(rawUrl)) {
      const segments = u.pathname.split('/').filter(Boolean);
      if (u.protocol === 'eduma:' && u.hostname) {
        segments.unshift(u.hostname);
      }
      if (segments.length === 0) continue;
      const last = segments[segments.length - 1];
      const kind: AuthLinkKind | null =
        last === 'verify-email' || last === 'reset-password' ? last : null;
      const token = AuthLinkLogic.cleanToken(u.searchParams.get('token'));
      if (kind && token) return { kind, token };
    }
    return null;
  },

  tokenFrom(input: string, expect?: AuthLinkKind): string | null {
    let text = input.trim();
    if (!text) return null;
    if (text.startsWith('?')) text = text.slice(1);
    if (text.startsWith('token=')) {
      try {
        const raw = decodeURIComponent(text.slice(6).split('&')[0] || '');
        return AuthLinkLogic.cleanToken(raw);
      } catch {
        return null;
      }
    }

    const looksLikeLink =
      text.includes('://') ||
      text.includes('token=') ||
      text.startsWith('/') ||
      /^[\w-]+(\.[\w-]+)+\//.test(text);

    if (!looksLikeLink) {
      return AuthLinkLogic.cleanToken(text);
    }

    const link = AuthLinkLogic.parseUrl(
      text.startsWith('/') || text.includes('://') ? text : `https://${text}`
    );
    if (link) {
      return !expect || link.kind === expect ? link.token : null;
    }

    const u = tryParseUrl(
      text.startsWith('/') || text.includes('://') ? text : `https://${text}`
    );
    if (!u) return null;
    return AuthLinkLogic.cleanToken(u.searchParams.get('token'));
  },
};

export const ReferralLogic = {
  cleanCode(raw?: string | null): string | null {
    const cleaned = raw?.trim().replace(/\s+/g, '');
    if (!cleaned) return null;
    return REFERRAL_ALLOWED.test(cleaned) ? cleaned : null;
  },

  fromUrlOrInput(rawInput: string): string | null {
    const trimmed = rawInput.trim();
    if (!trimmed) return null;
    if (!trimmed.includes('/') && !trimmed.includes('?')) {
      return ReferralLogic.cleanCode(trimmed);
    }
    for (const u of getCandidateUrls(
      trimmed.startsWith('/') || trimmed.includes('://')
        ? trimmed
        : `https://${trimmed}`
    )) {
      const segments = u.pathname.split('/').filter(Boolean);
      const idx = segments.findIndex((s) => s === 'invite' || s === 'join');
      if (idx >= 0 && idx + 1 < segments.length) {
        try {
          const decoded = decodeURIComponent(segments[idx + 1]);
          const code = ReferralLogic.cleanCode(decoded);
          if (code) return code;
        } catch {
          // Ignore malformed URI components.
        }
      }
      for (const key of ['ref', 'referral']) {
        const val = u.searchParams.get(key);
        const code = ReferralLogic.cleanCode(val);
        if (code) return code;
      }
    }
    return ReferralLogic.cleanCode(trimmed);
  },
};
