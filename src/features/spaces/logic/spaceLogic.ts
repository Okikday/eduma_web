import { fnv1aHash } from '../../../core/utils/accentHash';
import type {
  Space,
  SpaceContentHit,
  SpacePage,
  SpaceSortOrder,
} from '../models/spaceModels';

const PALETTE = [
  'var(--accent-violet)',
  'var(--accent-sky)',
  'var(--accent-teal)',
  'var(--accent-amber)',
  'var(--accent-rose)',
  'var(--accent-green)',
] as const;

export function pickSpaceGridTints(id: string): {
  main: string;
  left: string;
  right: string;
} {
  const index = fnv1aHash(id.trim() || 'space') % PALETTE.length;
  return {
    main: PALETTE[index],
    left: PALETTE[(index + 2) % PALETTE.length],
    right: PALETTE[(index + 4) % PALETTE.length],
  };
}

export function sortSpaces(
  spaces: readonly Space[],
  sortOrder: SpaceSortOrder
): Space[] {
  const list = [...spaces];
  switch (sortOrder) {
    case 'name':
      return list.sort((a, b) => a.title.localeCompare(b.title));
    case 'pages':
      return list.sort(
        (a, b) => b.pagesCount - a.pagesCount || a.title.localeCompare(b.title)
      );
    case 'recent':
    default:
      return list.sort((a, b) => {
        const da = Date.parse(a.updatedAt || a.createdAt || '') || 0;
        const db = Date.parse(b.updatedAt || b.createdAt || '') || 0;
        return db - da;
      });
  }
}

export function filterSpaces(
  spaces: readonly Space[],
  query: string
): Space[] {
  const q = query.trim().toLowerCase();
  if (!q) return [...spaces];
  return spaces.filter(
    (s) =>
      s.title.toLowerCase().includes(q) ||
      (s.description || '').toLowerCase().includes(q) ||
      (s.subject || '').toLowerCase().includes(q)
  );
}

/**
 * Mirrors `SpaceContentHitsSliver` from `../eduma`: matches cached pages by
 * page title and section/element text inside cached spaces.
 */
export function searchCachedPageContent(
  pages: readonly SpacePage[],
  spacesById: Record<string, Space>,
  query: string
): SpaceContentHit[] {
  const q = query.trim().toLowerCase();
  if (q.length < 2) return [];

  const hits: SpaceContentHit[] = [];
  for (const page of pages) {
    const spaceTitle =
      page.spaceTitle || spacesById[page.spaceId]?.title || 'Study Space';
    if (page.title.toLowerCase().includes(q)) {
      hits.push({
        page,
        spaceTitle,
        matchedSnippet: `Page in ${spaceTitle}`,
      });
      continue;
    }

    const bodyText = extractPagePlainText(page);
    const idx = bodyText.toLowerCase().indexOf(q);
    if (idx >= 0) {
      const start = Math.max(0, idx - 28);
      const end = Math.min(bodyText.length, idx + q.length + 52);
      const snippet = `${start > 0 ? '…' : ''}${bodyText
        .slice(start, end)
        .trim()}${end < bodyText.length ? '…' : ''}`;
      hits.push({ page, spaceTitle, matchedSnippet: snippet });
    }
  }
  return hits;
}

export function extractPagePlainText(page: SpacePage): string {
  const chunks: string[] = [];
  if (Array.isArray(page.sections)) {
    for (const sec of page.sections) {
      if (sec.title) chunks.push(sec.title);
      if (sec.text) chunks.push(sec.text);
      if (sec.content) chunks.push(sec.content);
      if (Array.isArray(sec.items)) chunks.push(...sec.items);
    }
  }
  if (page.rawContent) {
    collectStrings(page.rawContent, chunks, 0);
  }
  return chunks.join(' ');
}

function collectStrings(node: unknown, out: string[], depth: number): void {
  if (depth > 5 || out.length > 60 || node == null) return;
  if (typeof node === 'string') {
    const trimmed = node.trim();
    if (trimmed.length >= 2 && !trimmed.startsWith('http')) {
      out.push(trimmed);
    }
    return;
  }
  if (Array.isArray(node)) {
    for (const item of node) collectStrings(item, out, depth + 1);
    return;
  }
  if (typeof node === 'object') {
    for (const [k, v] of Object.entries(node as Record<string, unknown>)) {
      if (k === 'id' || k === 'color' || k === 'type') continue;
      collectStrings(v, out, depth + 1);
    }
  }
}

export function extractSpaceJoinCode(input: string): string {
  const trimmed = input.trim();
  if (!trimmed) return '';
  try {
    const url = new URL(
      trimmed.startsWith('http') || trimmed.startsWith('/')
        ? trimmed
        : `https://${trimmed}`,
      'https://app.eduma.com.ng'
    );
    const segments = url.pathname.split('/').filter(Boolean);
    const idx = segments.findIndex((s) => s === 'join' || s === 'invite');
    if (idx >= 0 && segments[idx + 1]) {
      return decodeURIComponent(segments[idx + 1]).trim();
    }
    const q = url.searchParams.get('code');
    if (q) return q.trim();
  } catch {
    // Not a URL — treat as raw code.
  }
  return trimmed.replace(/\s+/g, '');
}
