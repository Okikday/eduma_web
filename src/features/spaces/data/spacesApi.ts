import { apiClient } from '../../../core/api/apiClient';
import type {
  Space,
  SpaceAsset,
  SpaceInvitePreview,
  SpaceMember,
  SpacePage,
} from '../models/spaceModels';

function asArray(val: unknown): Record<string, unknown>[] {
  if (Array.isArray(val)) return val as Record<string, unknown>[];
  if (val && typeof val === 'object') {
    const o = val as Record<string, unknown>;
    const candidate = o.spaces ?? o.items ?? o.pages ?? o.assets ?? o.members ?? o.users ?? o.results;
    if (Array.isArray(candidate)) return candidate as Record<string, unknown>[];
  }
  return [];
}

function mapMember(raw: Record<string, unknown>): SpaceMember {
  const u =
    raw.user && typeof raw.user === 'object'
      ? (raw.user as Record<string, unknown>)
      : raw;
  return {
    id: String(raw.id || raw._id || u.id || u._id || ''),
    userId: String(u.id || u._id || raw.userId || raw.id || ''),
    name: String(u.name || raw.name || 'Student'),
    username: typeof u.username === 'string' ? u.username : null,
    email: typeof u.email === 'string' ? u.email : null,
    avatarUrl:
      typeof u.profilePic === 'string' && u.profilePic
        ? u.profilePic
        : typeof u.profilePicture === 'string' && u.profilePicture
        ? u.profilePicture
        : typeof u.avatarUrl === 'string'
        ? u.avatarUrl
        : typeof u.avatar === 'string'
        ? u.avatar
        : null,
    role: typeof raw.role === 'string' ? raw.role : 'member',
    joinedAt: typeof raw.joinedAt === 'string' ? raw.joinedAt : null,
  };
}

export function mapSpacePage(
  raw: Record<string, unknown>,
  fallbackSpaceId = ''
): SpacePage {
  const contentObj =
    raw.content && typeof raw.content === 'object'
      ? (raw.content as Record<string, unknown>)
      : null;

  const sections = Array.isArray(raw.sections)
    ? (raw.sections as SpacePage['sections'])
    : Array.isArray(contentObj?.sections)
    ? (contentObj?.sections as SpacePage['sections'])
    : Array.isArray(contentObj?.blocks)
    ? (contentObj?.blocks as SpacePage['sections'])
    : undefined;

  const spaceObj =
    raw.space && typeof raw.space === 'object'
      ? (raw.space as Record<string, unknown>)
      : null;

  return {
    id: String(raw.id || raw._id || raw.pageId || ''),
    spaceId: String(raw.spaceId || spaceObj?.id || fallbackSpaceId),
    spaceTitle:
      typeof raw.spaceTitle === 'string'
        ? raw.spaceTitle
        : typeof spaceObj?.title === 'string'
        ? spaceObj.title
        : undefined,
    title: String(raw.title || raw.name || 'Untitled Page'),
    pageNumber: typeof raw.pageNumber === 'number' ? raw.pageNumber : undefined,
    pageType: typeof raw.pageType === 'string' ? raw.pageType : undefined,
    coverUrl: typeof raw.coverUrl === 'string' ? raw.coverUrl : null,
    thumbnailUrl:
      typeof raw.thumbnailUrl === 'string' ? raw.thumbnailUrl : null,
    isPinned: Boolean(raw.isPinned ?? false),
    isArchived: Boolean(raw.isArchived ?? raw.archivedAt ?? false),
    updatedAt: typeof raw.updatedAt === 'string' ? raw.updatedAt : null,
    createdAt: typeof raw.createdAt === 'string' ? raw.createdAt : null,
    lastOpenedAt: typeof raw.lastOpenedAt === 'string' ? raw.lastOpenedAt : null,
    sections,
    rawContent: contentObj,
  };
}

function mapAsset(raw: Record<string, unknown>, spaceId: string): SpaceAsset {
  return {
    id: String(raw.id || raw._id || ''),
    spaceId: String(raw.spaceId || spaceId),
    title: String(raw.title || raw.name || raw.filename || 'Asset'),
    name: typeof raw.name === 'string' ? raw.name : undefined,
    type: typeof raw.type === 'string' ? raw.type : undefined,
    mimeType: typeof raw.mimeType === 'string' ? raw.mimeType : undefined,
    url: String(raw.url || raw.fileUrl || raw.path || ''),
    sizeBytes: typeof raw.sizeBytes === 'number' ? raw.sizeBytes : undefined,
    pageId: typeof raw.pageId === 'string' ? raw.pageId : null,
    uploadedBy: typeof raw.uploadedBy === 'string' ? raw.uploadedBy : null,
    createdAt: typeof raw.createdAt === 'string' ? raw.createdAt : null,
  };
}

export function mapSpace(raw: Record<string, unknown>): Space {
  const spaceObj =
    raw.space && typeof raw.space === 'object'
      ? (raw.space as Record<string, unknown>)
      : raw;

  const members = asArray(spaceObj.members).map(mapMember);
  const pages = Array.isArray(spaceObj.pages)
    ? (spaceObj.pages as Record<string, unknown>[]).map((p) =>
        mapSpacePage(p, String(spaceObj.id || spaceObj._id || ''))
      )
    : undefined;

  const countObj =
    spaceObj._count && typeof spaceObj._count === 'object'
      ? (spaceObj._count as Record<string, unknown>)
      : null;

  return {
    id: String(spaceObj.id || spaceObj._id || ''),
    title: String(spaceObj.title || spaceObj.name || 'Untitled Space'),
    description:
      typeof spaceObj.description === 'string' ? spaceObj.description : null,
    subject: typeof spaceObj.subject === 'string' ? spaceObj.subject : null,
    coverUrl: typeof spaceObj.coverUrl === 'string' ? spaceObj.coverUrl : null,
    inviteCode:
      typeof spaceObj.inviteCode === 'string' ? spaceObj.inviteCode : null,
    isPinned: Boolean(spaceObj.isPinned ?? false),
    isPersonal: Boolean(spaceObj.isPersonal ?? false),
    isPublic: Boolean(spaceObj.isPublic ?? false),
    isVerified: Boolean(spaceObj.isVerified ?? false),
    onlineNow: Array.isArray(spaceObj.onlineNow)
      ? (spaceObj.onlineNow as unknown[]).map(String)
      : [],
    role: typeof spaceObj.role === 'string' ? spaceObj.role : null,
    pagesCount: Number(
      spaceObj.pagesCount ?? countObj?.pages ?? pages?.length ?? 0
    ),
    membersCount: Number(
      spaceObj.membersCount ?? countObj?.members ?? members.length
    ),
    members,
    pages,
    updatedAt: typeof spaceObj.updatedAt === 'string' ? spaceObj.updatedAt : null,
    createdAt: typeof spaceObj.createdAt === 'string' ? spaceObj.createdAt : null,
  };
}

export const spacesApi = {
  async listSpaces(): Promise<Space[]> {
    const res = await apiClient.get<unknown>('/spaces');
    return asArray(res).map(mapSpace);
  },

  async createSpace(input: {
    title: string;
    description?: string;
    subject?: string;
  }): Promise<Space> {
    const res = await apiClient.post<Record<string, unknown>>('/spaces', input);
    return mapSpace(res);
  },

  async ensurePersonalSpace(): Promise<Space> {
    const res = await apiClient.post<Record<string, unknown>>(
      '/spaces/personal',
      {}
    );
    return mapSpace(res);
  },

  async getSpaceDetail(spaceId: string): Promise<Space> {
    const res = await apiClient.get<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}`
    );
    return mapSpace(res);
  },

  async updateSpace(
    spaceId: string,
    input: { title?: string; description?: string; isPublic?: boolean }
  ): Promise<Space> {
    const res = await apiClient.patch<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}`,
      input
    );
    return mapSpace(res);
  },

  async deleteSpace(spaceId: string): Promise<void> {
    await apiClient.delete(`/spaces/${encodeURIComponent(spaceId)}`);
  },

  async togglePinSpace(spaceId: string, pin: boolean): Promise<void> {
    const path = `/spaces/${encodeURIComponent(spaceId)}/pin`;
    if (pin) {
      await apiClient.post(path, {});
    } else {
      await apiClient.delete(path);
    }
  },

  async uploadSpaceCover(spaceId: string, file: File): Promise<Space> {
    const fd = new FormData();
    fd.append('cover', file);
    const res = await apiClient.post<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/cover`,
      fd
    );
    return mapSpace(res);
  },

  async regenerateInviteCode(spaceId: string): Promise<string> {
    const res = await apiClient.post<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/invite-code`,
      {}
    );
    return String(res?.inviteCode || res?.code || '');
  },

  async previewInviteCode(code: string): Promise<SpaceInvitePreview> {
    const res = await apiClient.get<Record<string, unknown>>(
      `/spaces/invite/${encodeURIComponent(code)}`
    );
    const s = mapSpace(res);
    return {
      id: s.id,
      title: s.title,
      description: s.description,
      coverUrl: s.coverUrl,
      membersCount: s.membersCount,
      pagesCount: s.pagesCount,
      inviteCode: code,
    };
  },

  async joinByCode(code: string): Promise<Space> {
    const res = await apiClient.post<Record<string, unknown>>('/spaces/join', {
      code,
      inviteCode: code,
    });
    return mapSpace(res);
  },

  async listRecentPages(limit = 12): Promise<SpacePage[]> {
    const res = await apiClient.get<unknown>('/spaces/pages/recent', {
      params: { limit },
    });
    return asArray(res).map((p) => mapSpacePage(p));
  },

  async listSpacePages(
    spaceId: string,
    includeArchived = true
  ): Promise<SpacePage[]> {
    const res = await apiClient.get<unknown>(
      `/spaces/${encodeURIComponent(spaceId)}/pages`,
      {
        params: includeArchived ? { includeArchived: 'true' } : undefined,
      }
    );
    return asArray(res).map((p) => mapSpacePage(p, spaceId));
  },

  async getPageDetail(spaceId: string, pageId: string): Promise<SpacePage> {
    const res = await apiClient.get<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/pages/${encodeURIComponent(pageId)}`
    );
    return mapSpacePage(res, spaceId);
  },

  async createPage(spaceId: string, title: string): Promise<SpacePage> {
    const res = await apiClient.post<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/pages`,
      { title }
    );
    return mapSpacePage(res, spaceId);
  },

  async updatePageMeta(
    spaceId: string,
    pageId: string,
    input: { title?: string }
  ): Promise<SpacePage> {
    const res = await apiClient.patch<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/pages/${encodeURIComponent(pageId)}`,
      input
    );
    return mapSpacePage(res, spaceId);
  },

  async updatePageContent(
    spaceId: string,
    pageId: string,
    content: Record<string, unknown>
  ): Promise<SpacePage> {
    const res = await apiClient.put<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/pages/${encodeURIComponent(
        pageId
      )}/content`,
      content
    );
    return mapSpacePage(res, spaceId);
  },

  async duplicatePage(spaceId: string, pageId: string): Promise<SpacePage> {
    const res = await apiClient.post<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/pages/${encodeURIComponent(
        pageId
      )}/duplicate`,
      {}
    );
    return mapSpacePage(res, spaceId);
  },

  async deletePage(spaceId: string, pageId: string): Promise<void> {
    await apiClient.delete(
      `/spaces/${encodeURIComponent(spaceId)}/pages/${encodeURIComponent(pageId)}`
    );
  },

  async recordPageOpened(spaceId: string, pageId: string): Promise<void> {
    await apiClient
      .post(
        `/spaces/${encodeURIComponent(spaceId)}/pages/${encodeURIComponent(
          pageId
        )}/opened`,
        {}
      )
      .catch(() => null);
  },

  async savePinnedPages(spaceId: string, pageIds: string[]): Promise<void> {
    await apiClient.put(
      `/spaces/${encodeURIComponent(spaceId)}/pages/pins`,
      { pageIds }
    );
  },

  async listSpaceAssets(spaceId: string): Promise<SpaceAsset[]> {
    const res = await apiClient.get<unknown>(
      `/spaces/${encodeURIComponent(spaceId)}/pages/assets`
    );
    return asArray(res).map((a) => mapAsset(a, spaceId));
  },

  async uploadAndAttachAsset(
    spaceId: string,
    file: File
  ): Promise<SpaceAsset> {
    const fd = new FormData();
    fd.append('file', file);
    const uploaded = await apiClient.post<Record<string, unknown>>(
      '/uploads',
      fd
    );
    const res = await apiClient.post<Record<string, unknown>>(
      `/spaces/${encodeURIComponent(spaceId)}/pages/assets`,
      {
        title: file.name,
        url: uploaded?.url || uploaded?.fileUrl || '',
        mimeType: file.type,
        sizeBytes: file.size,
      }
    );
    return mapAsset(res, spaceId);
  },

  async deleteSpaceAsset(spaceId: string, assetId: string): Promise<void> {
    await apiClient.delete(
      `/spaces/${encodeURIComponent(spaceId)}/pages/assets/${encodeURIComponent(
        assetId
      )}`
    );
  },

  async searchUsers(
    query: string,
    spaceId?: string
  ): Promise<SpaceMember[]> {
    const res = await apiClient.get<unknown>('/users/search', {
      params: { q: query, limit: 12, spaceId },
    });
    return asArray(res).map(mapMember);
  },

  async inviteUsersToSpace(spaceId: string, userIds: string[]): Promise<void> {
    await apiClient.post(`/spaces/${encodeURIComponent(spaceId)}/invites`, {
      userIds,
    });
  },

  async removeMember(spaceId: string, userId: string): Promise<void> {
    await apiClient.delete(
      `/spaces/${encodeURIComponent(spaceId)}/members/${encodeURIComponent(
        userId
      )}`
    );
  },

  async setMemberAdmin(
    spaceId: string,
    userId: string,
    isAdmin: boolean
  ): Promise<void> {
    const path = `/spaces/${encodeURIComponent(
      spaceId
    )}/admins/${encodeURIComponent(userId)}`;
    if (isAdmin) {
      await apiClient.post(path, {});
    } else {
      await apiClient.delete(path);
    }
  },
};
