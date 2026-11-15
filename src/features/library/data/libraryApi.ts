import { apiClient } from '../../../core/api/apiClient';
import type {
  LibraryDocument,
  LibraryGroup,
  LibrarySortOption,
} from '../models/libraryModels';

function asList(val: unknown): Record<string, unknown>[] {
  if (Array.isArray(val)) return val as Record<string, unknown>[];
  if (val && typeof val === 'object') {
    const o = val as Record<string, unknown>;
    const candidate = o.documents ?? o.items ?? o.recents ?? o.collections ?? o.groups;
    if (Array.isArray(candidate)) return candidate as Record<string, unknown>[];
  }
  return [];
}

function mapDoc(raw: Record<string, unknown>): LibraryDocument {
  const doc =
    raw.document && typeof raw.document === 'object'
      ? (raw.document as Record<string, unknown>)
      : raw;

  const progress = Number(
    raw.progressPercent ?? doc.progressPercent ?? raw.progress ?? 0
  );
  const id = String(doc.id || doc._id || raw.documentId || '');

  return {
    id,
    title: String(doc.title || doc.name || 'Untitled Document'),
    author:
      typeof doc.author === 'string'
        ? doc.author
        : typeof doc.authorName === 'string'
        ? doc.authorName
        : null,
    category: String(doc.category || doc.subject || 'General'),
    description: typeof doc.description === 'string' ? doc.description : null,
    coverUrl:
      typeof doc.coverUrl === 'string'
        ? doc.coverUrl
        : typeof doc.thumbnailUrl === 'string'
        ? doc.thumbnailUrl
        : id
        ? `/library/documents/${encodeURIComponent(id)}/thumbnail`
        : null,
    thumbnailUrl:
      typeof doc.thumbnailUrl === 'string' ? doc.thumbnailUrl : null,
    fileUrl:
      typeof doc.fileUrl === 'string'
        ? doc.fileUrl
        : typeof doc.url === 'string'
        ? doc.url
        : id
        ? `/library/documents/${encodeURIComponent(id)}/file.pdf`
        : null,
    pageCount:
      typeof doc.pageCount === 'number'
        ? doc.pageCount
        : typeof doc.pages === 'number'
        ? doc.pages
        : null,
    progressPercent: Number.isFinite(progress) ? Math.min(100, Math.max(0, progress)) : 0,
    currentPage: typeof raw.currentPage === 'number' ? raw.currentPage : undefined,
    isVerified: Boolean(doc.isVerified ?? doc.verified ?? false),
    isPremium: Boolean(doc.isPremium ?? doc.premium ?? false),
    isSaved: Boolean(doc.isSaved ?? raw.isSaved ?? false),
    rating: typeof doc.rating === 'number' ? doc.rating : null,
    reviewsCount: typeof doc.reviewsCount === 'number' ? doc.reviewsCount : undefined,
    updatedAt: typeof doc.updatedAt === 'string' ? doc.updatedAt : null,
  };
}

export const libraryApi = {
  async listDocuments(params: {
    query?: string;
    category?: string;
    shelf?: string;
    sort?: LibrarySortOption;
    limit?: number;
  } = {}): Promise<LibraryDocument[]> {
    const res = await apiClient.get<unknown>('/library/documents', {
      params: {
        q: params.query?.trim() || undefined,
        category: params.category || undefined,
        shelf: params.shelf || undefined,
        sort: params.sort || 'popular',
        limit: params.limit ?? 36,
      },
    });
    return asList(res).map(mapDoc);
  },

  async listRecents(): Promise<LibraryDocument[]> {
    const res = await apiClient.get<unknown>('/library/recents');
    return asList(res).map(mapDoc);
  },

  async recordOpened(documentId: string): Promise<void> {
    await apiClient
      .put(`/library/recents/${encodeURIComponent(documentId)}`, {})
      .catch(() => null);
  },

  async updateProgress(
    documentId: string,
    input: { currentPage?: number; progressPercent?: number }
  ): Promise<void> {
    await apiClient.put(
      `/library/progress/${encodeURIComponent(documentId)}`,
      input
    );
  },

  async listSaved(): Promise<LibraryDocument[]> {
    const res = await apiClient.get<unknown>('/library/collections/saved');
    return asList(res).map(mapDoc);
  },

  async toggleSave(documentId: string, saved: boolean): Promise<void> {
    await apiClient.put(
      `/library/collections/${encodeURIComponent(documentId)}/save`,
      { saved }
    );
  },

  async listGroups(): Promise<LibraryGroup[]> {
    const res = await apiClient.get<unknown>('/library/groups');
    return asList(res).map((g) => ({
      id: String(g.id || g._id || ''),
      name: String(g.name || g.title || 'Reading List'),
      documentIds: Array.isArray(g.documentIds)
        ? (g.documentIds as unknown[]).map(String)
        : [],
      color: typeof g.color === 'string' ? g.color : null,
    }));
  },

  async saveGroup(id: string, name: string, documentIds: string[]): Promise<void> {
    await apiClient.put(`/library/groups/${encodeURIComponent(id)}`, {
      name,
      documentIds,
    });
  },

  async deleteGroup(id: string): Promise<void> {
    await apiClient.delete(`/library/groups/${encodeURIComponent(id)}`);
  },
};
