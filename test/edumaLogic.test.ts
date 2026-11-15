import { describe, expect, it } from 'vitest';
import { extractErrorDetails } from '../src/core/api/apiClient';
import { buildFlutterCanvasUrl, normalizeApiUrl } from '../src/core/config/appConfig';
import { memoryCache, SessionReset } from '../src/core/cache/memoryCache';
import { fnv1aHash, getInitials, pickAccentForId } from '../src/core/utils/accentHash';
import {
  buildSundayFirstMonthGrid,
  getGreetingForHour,
  layoutTimelineEvents,
} from '../src/core/utils/dateFormatters';
import { normalizeUser } from '../src/features/auth/data/authApi';
import { AuthLinkLogic, ReferralLogic } from '../src/features/auth/logic/authLinkLogic';
import { SignUpLogic, Validator } from '../src/features/auth/logic/authLogic';
import { edgeLayersOfBook, pickLibraryBookTints } from '../src/features/library/logic/libraryLogic';
import {
  extractSpaceJoinCode,
  filterSpaces,
  pickSpaceGridTints,
  searchCachedPageContent,
  sortSpaces,
} from '../src/features/spaces/logic/spaceLogic';
import type { Space, SpacePage } from '../src/features/spaces/models/spaceModels';

describe('AppConfig URL normalization & handoff', () => {
  it('rewrites legacy API origins to active apiBaseUrl', () => {
    expect(
      normalizeApiUrl('https://eduma.com.ng/api/v1/spaces/123')
    ).toBe('https://eduma-backend1.onrender.com/api/v1/spaces/123');
    expect(
      normalizeApiUrl('https://app.eduma.com.ng/api/v1/library/documents/1/file.pdf')
    ).toBe(
      'https://eduma-backend1.onrender.com/api/v1/library/documents/1/file.pdf'
    );
    expect(normalizeApiUrl('/assets/logo/logo.png')).toBe('/assets/logo/logo.png');
  });

  it('constructs Flutter canvas handoff URL with encoded IDs', () => {
    expect(
      buildFlutterCanvasUrl({ pageId: 'page_1', spaceId: 'space_2' })
    ).toBe('https://app.eduma.com.ng/spacePageCanvas?id=page_1&spaceId=space_2');
  });
});

describe('AuthLinkLogic & ReferralLogic', () => {
  it('parses verify-email and reset-password links including hash URLs', () => {
    expect(
      AuthLinkLogic.parseUrl('https://app.eduma.com.ng/#/verify-email?token=abc12345')
    ).toEqual({ kind: 'verify-email', token: 'abc12345' });

    expect(
      AuthLinkLogic.parseUrl('eduma://reset-password?token=tok_xyz_789')
    ).toEqual({ kind: 'reset-password', token: 'tok_xyz_789' });

    expect(AuthLinkLogic.tokenFrom('token=secret_token_99&foo=bar')).toBe(
      'secret_token_99'
    );
    expect(
      AuthLinkLogic.tokenFrom(
        'https://eduma.com.ng/verify-email?token=onlyVerifyToken',
        'reset-password'
      )
    ).toBeNull();
  });

  it('extracts referral codes from invite paths and query parameters', () => {
    expect(
      ReferralLogic.fromUrlOrInput('https://eduma.com.ng/invite/ada.obi_99')
    ).toBe('ada.obi_99');
    expect(
      ReferralLogic.fromUrlOrInput('https://app.eduma.com.ng/?ref=CHEM201')
    ).toBe('CHEM201');
    expect(ReferralLogic.cleanCode(' ab 12 ')).toBe('ab12');
    expect(ReferralLogic.cleanCode('x')).toBeNull();
  });
});

describe('Validator & SignUpLogic', () => {
  it('validates email, username, and password length rules', () => {
    expect(Validator.validateEmail('ada@university.edu')).toBeNull();
    expect(Validator.validateEmail('bad-email')).not.toBeNull();
    expect(Validator.validateUsername('ada.obi_1')).toBeNull();
    expect(Validator.validateUsername('a')).not.toBeNull();
    expect(Validator.validatePasswordLength('1234567')).not.toBeNull();
  });

  it('generates stable username candidates and accurate password strength', () => {
    const candidates = SignUpLogic.usernameCandidates('Adaeze Obi');
    expect(candidates[0]).toBe('adaeze.obi');
    expect(candidates[1]).toBe('adaezeobi');
    expect(candidates.length).toBe(3);

    expect(SignUpLogic.strengthOf('').level).toBe('empty');
    expect(SignUpLogic.strengthOf('short').level).toBe('tooShort');
    expect(SignUpLogic.strengthOf('password').level).toBe('weak');
    expect(SignUpLogic.strengthOf('Tr0ub4dor&3!LongPass').level).toBe('strong');
  });
});

describe('FNV-1a Accents, Space Tints & Library Book Edges', () => {
  it('computes deterministic FNV-1a hashes and initial monograms', () => {
    expect(fnv1aHash('chemistry')).toBe(fnv1aHash('chemistry'));
    expect(pickAccentForId('biology-101')).toEqual(pickAccentForId('biology-101'));
    expect(getInitials('Adaeze Obi')).toBe('AO');
    expect(getInitials('Eduma')).toBe('ED');
  });

  it('derives distinct three-sheet tints and page-thickness edge counts', () => {
    const tints = pickSpaceGridTints('space-abc');
    expect(tints.main).not.toBe(tints.left);
    expect(tints.left).not.toBe(tints.right);

    expect(edgeLayersOfBook(null)).toBe(1);
    expect(edgeLayersOfBook(119)).toBe(1);
    expect(edgeLayersOfBook(120)).toBe(2);
    expect(edgeLayersOfBook(400)).toBe(3);

    const bioA = pickLibraryBookTints({ id: '1', title: 'Cell Bio', category: 'Biology' });
    const bioB = pickLibraryBookTints({ id: '2', title: 'Genetics', category: 'biology' });
    expect(bioA).toEqual(bioB);
  });
});

describe('Date Formatters, Month Grid & Timeline Layout', () => {
  it('picks greetings by hour of day', () => {
    expect(getGreetingForHour(8)).toBe('Good morning');
    expect(getGreetingForHour(13)).toBe('Good afternoon');
    expect(getGreetingForHour(20)).toBe('Good evening');
  });

  it('generates 42-cell Sunday-first month matrix', () => {
    const cells = buildSundayFirstMonthGrid(2026, 10); // November 2026
    expect(cells).toHaveLength(42);
    expect(cells[0].date.getDay()).toBe(0);
    expect(cells.filter((c) => c.inCurrentMonth)).toHaveLength(30);
  });

  it('assigns non-overlapping columns to overlapping timeline events', () => {
    const layout = layoutTimelineEvents([
      { id: 'a', startMinutes: 540, endMinutes: 660 },
      { id: 'b', startMinutes: 570, endMinutes: 630 },
      { id: 'c', startMinutes: 720, endMinutes: 780 },
    ]);
    const a = layout.find((x) => x.item.id === 'a')!;
    const b = layout.find((x) => x.item.id === 'b')!;
    const c = layout.find((x) => x.item.id === 'c')!;

    expect(a.columnCount).toBe(2);
    expect(b.columnCount).toBe(2);
    expect(a.column).not.toBe(b.column);
    expect(c.columnCount).toBe(1);
    expect(c.column).toBe(0);
  });
});

describe('Space Filtering, Content Search & Cache Reset', () => {
  const sampleSpaces: Space[] = [
    {
      id: 's1',
      title: 'Organic Chemistry',
      isPinned: true,
      pagesCount: 12,
      membersCount: 4,
      members: [],
      updatedAt: '2026-10-01T10:00:00Z',
    },
    {
      id: 's2',
      title: 'Algorithms',
      isPinned: false,
      pagesCount: 25,
      membersCount: 2,
      members: [],
      updatedAt: '2026-11-01T10:00:00Z',
    },
  ];

  it('sorts and filters spaces and searches nested page text', () => {
    expect(sortSpaces(sampleSpaces, 'name').map((s) => s.title)).toEqual([
      'Algorithms',
      'Organic Chemistry',
    ]);
    expect(sortSpaces(sampleSpaces, 'pages')[0].id).toBe('s2');
    expect(filterSpaces(sampleSpaces, 'chem').map((s) => s.id)).toEqual(['s1']);

    const pages: SpacePage[] = [
      {
        id: 'p1',
        spaceId: 's1',
        title: 'Carbonyl Reactions',
        sections: [
          { id: 'sec1', text: 'Nucleophilic addition of Grignard reagents' },
        ],
      },
    ];
    const hits = searchCachedPageContent(pages, { s1: sampleSpaces[0] }, 'grignard');
    expect(hits).toHaveLength(1);
    expect(hits[0].matchedSnippet).toContain('Grignard');
    expect(extractSpaceJoinCode('https://app.eduma.com.ng/join/XYZ789')).toBe('XYZ789');
  });

  it('resets cache cleanly on SessionReset.resetAll()', () => {
    memoryCache.set('k', 'v');
    let hookCalled = false;
    const unsub = SessionReset.register(() => {
      hookCalled = true;
    });
    SessionReset.resetAll();
    expect(memoryCache.get('k')).toBeNull();
    expect(hookCalled).toBe(true);
    unsub();
  });
});

describe('API Error Extraction & User Normalization', () => {
  it('parses nested backend error envelopes with EMAIL_NOT_VERIFIED and fieldErrors', () => {
    const details = extractErrorDetails(
      {
        error: {
          code: 'EMAIL_NOT_VERIFIED',
          message: 'Please verify your email address before continuing.',
          details: {
            retryAfter: 45,
            fieldErrors: {
              email: ['Email is not verified yet'],
            },
          },
        },
      },
      403
    );

    expect(details.code).toBe('EMAIL_NOT_VERIFIED');
    expect(details.message).toBe('Please verify your email address before continuing.');
    expect(details.retryAfter).toBe(45);
    expect(details.fieldErrors).toEqual({
      email: 'Email is not verified yet',
    });

    const validationDetails = extractErrorDetails(
      {
        error: {
          message: 'Validation failed',
          details: {
            fieldErrors: {
              password: 'Password must include a symbol',
            },
          },
        },
      },
      422
    );
    expect(validationDetails.message).toBe('Password must include a symbol');
  });

  it('normalizes user objects across isEmailVerified and profilePic fields', () => {
    const user = normalizeUser({
      user: {
        id: 'u-42',
        name: 'Chidi Okeke',
        email: 'chidi@eduma.com.ng',
        isEmailVerified: true,
        isVerified: false,
        profilePic: '/uploads/avatars/chidi.png',
      },
    });

    expect(user).not.toBeNull();
    expect(user?.isEmailVerified).toBe(true);
    expect(user?.isVerified).toBe(true);
    expect(user?.hasVerifiedBadge).toBe(false);
    expect(user?.avatarUrl).toBe('/uploads/avatars/chidi.png');
  });
});
