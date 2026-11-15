export interface SpaceMember {
  id: string;
  userId?: string;
  name: string;
  username?: string | null;
  email?: string | null;
  avatarUrl?: string | null;
  role?: 'owner' | 'admin' | 'member' | string;
  joinedAt?: string | null;
}

export interface SpacePageSection {
  id: string;
  title?: string;
  type?: string;
  text?: string;
  content?: string;
  items?: string[];
}

export interface SpacePage {
  id: string;
  spaceId: string;
  spaceTitle?: string;
  title: string;
  pageNumber?: number;
  pageType?: string;
  coverUrl?: string | null;
  thumbnailUrl?: string | null;
  isPinned?: boolean;
  isArchived?: boolean;
  updatedAt?: string | null;
  createdAt?: string | null;
  lastOpenedAt?: string | null;
  sections?: SpacePageSection[];
  rawContent?: Record<string, unknown> | null;
}

export interface SpaceAsset {
  id: string;
  spaceId: string;
  title: string;
  name?: string;
  type?: string;
  mimeType?: string;
  url: string;
  sizeBytes?: number;
  pageId?: string | null;
  uploadedBy?: string | null;
  createdAt?: string | null;
}

export interface Space {
  id: string;
  title: string;
  description?: string | null;
  subject?: string | null;
  coverUrl?: string | null;
  inviteCode?: string | null;
  isPinned: boolean;
  isPersonal?: boolean;
  isPublic?: boolean;
  isVerified?: boolean;
  onlineNow?: string[];
  role?: string | null;
  pagesCount: number;
  membersCount: number;
  members: SpaceMember[];
  pages?: SpacePage[];
  updatedAt?: string | null;
  createdAt?: string | null;
}

export interface SpaceInvitePreview {
  id?: string;
  title: string;
  description?: string | null;
  coverUrl?: string | null;
  membersCount?: number;
  pagesCount?: number;
  inviteCode: string;
}

export interface SpaceContentHit {
  page: SpacePage;
  spaceTitle: string;
  matchedSnippet: string;
}

export type SpaceSortOrder = 'recent' | 'name' | 'pages';
export type SpaceCardStyle = 'list' | 'grid';
