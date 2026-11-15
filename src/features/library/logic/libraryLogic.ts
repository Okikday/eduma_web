import { fnv1aHash } from '../../../core/utils/accentHash';
import type { LibraryDocument } from '../models/libraryModels';

const PALETTE = [
  'var(--accent-violet)',
  'var(--accent-sky)',
  'var(--accent-teal)',
  'var(--accent-amber)',
  'var(--accent-rose)',
  'var(--accent-green)',
] as const;

export function pickLibraryBookTints(doc: Pick<LibraryDocument, 'id' | 'title' | 'category'>): {
  main: string;
  end: string;
} {
  const category = (doc.category || '').trim().toLowerCase();
  const key = category || doc.id || doc.title || 'book';
  const index = fnv1aHash(key) % PALETTE.length;
  return {
    main: PALETTE[index],
    end: PALETTE[(index + 2) % PALETTE.length],
  };
}

/**
 * Matches `LibraryBookStage.edgeLayersOf(pages)` in `../eduma`:
 * < 120 -> 1 edge, 120..399 -> 2 edges, 400+ -> 3 edges.
 */
export function edgeLayersOfBook(pageCount?: number | null): 1 | 2 | 3 {
  if (!pageCount || pageCount < 120) return 1;
  if (pageCount < 400) return 2;
  return 3;
}
