export type AccentKey = 'violet' | 'sky' | 'teal' | 'amber' | 'rose' | 'green';

export interface AccentColors {
  key: AccentKey;
  cssVar: string;
  solidHexLight: string;
  solidHexDark: string;
}

const ACCENTS: readonly AccentColors[] = [
  { key: 'violet', cssVar: 'var(--accent-violet)', solidHexLight: '#7c3aed', solidHexDark: '#b4a0fb' },
  { key: 'sky', cssVar: 'var(--accent-sky)', solidHexLight: '#0284c7', solidHexDark: '#7dd3fc' },
  { key: 'teal', cssVar: 'var(--accent-teal)', solidHexLight: '#0f9488', solidHexDark: '#5eead4' },
  { key: 'amber', cssVar: 'var(--accent-amber)', solidHexLight: '#d97706', solidHexDark: '#fcd34d' },
  { key: 'rose', cssVar: 'var(--accent-rose)', solidHexLight: '#e11d48', solidHexDark: '#fda4af' },
  { key: 'green', cssVar: 'var(--accent-green)', solidHexLight: '#16a34a', solidHexDark: '#86efac' },
];

const FNV_OFFSET_BASIS = 0x811c9dc5;
const FNV_PRIME = 0x01000193;

/**
 * Deterministic 32-bit FNV-1a hash matching PureAccents hashing in `../eduma`.
 */
export function fnv1aHash(input: string): number {
  let hash = FNV_OFFSET_BASIS;
  for (let i = 0; i < input.length; i += 1) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, FNV_PRIME) >>> 0;
  }
  return hash >>> 0;
}

export function pickAccentForId(idOrSeed: string): AccentColors {
  const seed = idOrSeed.trim() || 'eduma';
  const index = fnv1aHash(seed) % ACCENTS.length;
  return ACCENTS[index];
}

export function getInitials(name?: string | null): string {
  const cleaned = (name || '').trim();
  if (!cleaned) return 'E';
  const parts = cleaned.split(/\s+/).filter(Boolean);
  if (parts.length === 1) {
    return parts[0].slice(0, 2).toUpperCase();
  }
  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
}
