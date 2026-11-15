import { fnv1aHash } from '../../../core/utils/accentHash';
import type {
  PasswordStrengthInfo,
  SignUpStep,
  UsernameCheck,
} from '../models/authModels';

const EMAIL_REGEX = /^[\w.-]+@[\w.-]+\.\w+$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_.]+$/;

const COMMON_PASSWORDS = new Set([
  'password',
  '12345678',
  '123456789',
  '1234567890',
  'qwertyui',
  'qwerty123',
  'password1',
  '11111111',
  'iloveyou',
  'abcd1234',
]);

export const Validator = {
  validateEmail(text?: string | null): string | null {
    const trimmed = (text || '').trim();
    if (!trimmed) return 'Please enter a valid email';
    if (
      trimmed.length < 5 ||
      !trimmed.includes('@') ||
      !trimmed.includes('.') ||
      trimmed.startsWith('@') ||
      trimmed.endsWith('@') ||
      trimmed.startsWith('.') ||
      trimmed.endsWith('.')
    ) {
      return 'almost there...';
    }
    return EMAIL_REGEX.test(trimmed) ? null : 'Invalid email address';
  },

  validateUsername(text?: string | null): string | null {
    const username = (text || '').trim();
    if (!username) return 'Please enter a valid username';
    if (username.length < 2) return 'Username must be at least 2 characters';
    if (username.length > 30) return 'Username must be at most 30 characters';
    if (!USERNAME_REGEX.test(username)) {
      return 'Only letters, numbers, underscores, and dots allowed';
    }
    return null;
  },

  validatePasswordLength(text?: string | null): string | null {
    const trimmed = (text || '').trim();
    if (!trimmed) return 'Please enter a valid password';
    if ((text || '').length < 8) {
      return 'Password must have 8 minimum characters';
    }
    return null;
  },
};

export const SignUpLogic = {
  steps(options: { includePhoto?: boolean } = {}): SignUpStep[] {
    const list: SignUpStep[] = ['name', 'account'];
    if (options.includePhoto !== false) list.push('photo');
    list.push('referral');
    return list;
  },

  firstName(name: string): string {
    const parts = name.trim().split(/\s+/).filter(Boolean);
    return parts[0] || '';
  },

  copyFor(
    step: SignUpStep,
    options: { firstName?: string; invited?: boolean } = {}
  ): { title: string; helper: string } {
    const first = (options.firstName || '').trim();
    switch (step) {
      case 'name':
        return {
          title: "What's your name?",
          helper: 'This is how friends and study groups will see you.',
        };
      case 'account':
        return {
          title: first ? `Nice to meet you, ${first}` : 'Your email and password',
          helper:
            "Add the email and password you'll sign in with. We'll send a code to confirm the email.",
        };
      case 'photo':
        return {
          title: 'Add a profile photo',
          helper: 'It helps friends recognise you. You can change it any time.',
        };
      case 'referral':
        if (options.invited) {
          return {
            title: "You're invited",
            helper:
              "Your invite code is filled in from the link. Create your account when you're ready.",
          };
        }
        return {
          title: 'Were you invited?',
          helper:
            'If a friend shared an invite code, add it here. You can skip this.',
        };
    }
  },

  cleanUsername(input: string): string {
    let s = input
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, '.')
      .replace(/[^a-z0-9._]/g, '')
      .replace(/\.{2,}/g, '.')
      .replace(/^[._]+|[._]+$/g, '');
    if (s.length > 30) {
      s = s.slice(0, 30).replace(/[._]+$/g, '');
    }
    return s;
  },

  usernameCandidates(name: string): string[] {
    const words = name
      .trim()
      .split(/\s+/)
      .map((w) => SignUpLogic.cleanUsername(w))
      .filter(Boolean);
    if (words.length === 0) return [];
    const parts = words.length === 1 ? words : [words[0], words[words.length - 1]];
    const dotted = SignUpLogic.cleanUsername(parts.join('.'));
    if (dotted.length < 3) return [];
    const joined = SignUpLogic.cleanUsername(parts.join(''));
    const suffix = 10 + (fnv1aHash(name.trim().toLowerCase()) % 90);
    const base = dotted.length > 27 ? dotted.slice(0, 27) : dotted;
    const numbered = SignUpLogic.cleanUsername(`${base}${suffix}`);
    return Array.from(new Set([dotted, joined, numbered])).filter(
      (u) => u.length >= 3
    );
  },

  strengthOf(password: string): PasswordStrengthInfo {
    if (!password) {
      return { level: 'empty', segments: 0, label: '', acceptable: false };
    }
    if (password.length < 8) {
      return {
        level: 'tooShort',
        segments: 0,
        label: 'Use at least 8 characters',
        acceptable: false,
      };
    }
    if (COMMON_PASSWORDS.has(password.toLowerCase())) {
      return {
        level: 'weak',
        segments: 1,
        label: 'Weak · add numbers, symbols or length',
        acceptable: true,
      };
    }

    const classes = [/[a-z]/, /[A-Z]/, /\d/, /[^A-Za-z0-9]/].filter((re) =>
      re.test(password)
    ).length;

    let points = 1;
    if (password.length >= 12) points += 1;
    if (classes >= 2) points += 1;
    if (classes >= 3) points += 1;
    if (password.length >= 16 || classes === 4) points += 1;

    if (points <= 1) {
      return {
        level: 'weak',
        segments: 1,
        label: 'Weak · add numbers, symbols or length',
        acceptable: true,
      };
    }
    if (points === 2) {
      return { level: 'fair', segments: 2, label: 'Fair', acceptable: true };
    }
    if (points === 3) {
      return { level: 'good', segments: 3, label: 'Good', acceptable: true };
    }
    return { level: 'strong', segments: 4, label: 'Strong', acceptable: true };
  },

  nameReady(name: string): boolean {
    return name.trim().length >= 2;
  },

  usernameReady(username: string, check: UsernameCheck): boolean {
    return (
      Validator.validateUsername(username) === null &&
      check !== 'taken' &&
      check !== 'invalid'
    );
  },

  emailReady(email: string): boolean {
    return Validator.validateEmail(email.trim()) === null;
  },

  canContinue(
    step: SignUpStep,
    params: {
      name: string;
      username: string;
      usernameCheck: UsernameCheck;
      email: string;
      strength: PasswordStrengthInfo;
    }
  ): boolean {
    switch (step) {
      case 'name':
        return (
          SignUpLogic.nameReady(params.name) &&
          SignUpLogic.usernameReady(params.username, params.usernameCheck)
        );
      case 'account':
        return (
          SignUpLogic.emailReady(params.email) && params.strength.acceptable
        );
      case 'photo':
      case 'referral':
        return true;
    }
  },
};
