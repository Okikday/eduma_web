export interface LibraryDocument {
  id: string;
  title: string;
  author?: string | null;
  category: string;
  description?: string | null;
  coverUrl?: string | null;
  thumbnailUrl?: string | null;
  fileUrl?: string | null;
  pageCount?: number | null;
  progressPercent?: number;
  currentPage?: number;
  isVerified?: boolean;
  isPremium?: boolean;
  isSaved?: boolean;
  rating?: number | null;
  reviewsCount?: number;
  updatedAt?: string | null;
}

export interface LibraryGroup {
  id: string;
  name: string;
  documentIds: string[];
  color?: string | null;
}

export type LibraryShelfFilter = 'all' | 'for_you' | 'popular' | 'saved';
export type LibrarySortOption = 'popular' | 'recent' | 'title';
