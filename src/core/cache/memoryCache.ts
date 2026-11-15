interface CacheEntry<T> {
  value: T;
  expiresAt: number | null;
}

class MemoryCacheStore {
  private readonly store = new Map<string, CacheEntry<unknown>>();

  get<T>(key: string): T | null {
    const entry = this.store.get(key);
    if (!entry) return null;
    if (entry.expiresAt !== null && Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return entry.value as T;
  }

  set<T>(key: string, value: T, ttlMs?: number): void {
    const expiresAt =
      typeof ttlMs === 'number' && ttlMs > 0 ? Date.now() + ttlMs : null;
    this.store.set(key, { value, expiresAt });
  }

  invalidate(key: string): void {
    this.store.delete(key);
  }

  invalidatePrefix(prefix: string): void {
    for (const key of this.store.keys()) {
      if (key.startsWith(prefix)) {
        this.store.delete(key);
      }
    }
  }

  clear(): void {
    this.store.clear();
  }
}

export const memoryCache = new MemoryCacheStore();

type ResetHook = () => void;

class SessionResetRegistry {
  private readonly hooks = new Set<ResetHook>();

  register(hook: ResetHook): () => void {
    this.hooks.add(hook);
    return () => {
      this.hooks.delete(hook);
    };
  }

  resetAll(): void {
    memoryCache.clear();
    for (const hook of this.hooks) {
      try {
        hook();
      } catch {
        // Ignore cleanup hook errors on sign-out.
      }
    }
  }
}

export const SessionReset = new SessionResetRegistry();

export type SyncTopic =
  | 'auth:changed'
  | 'auth:expired'
  | 'spaces:changed'
  | 'space:detail'
  | 'events:changed'
  | 'library:changed'
  | 'notifications:changed'
  | 'profile:changed'
  | 'streaks:changed';

type SyncListener = (payload?: unknown) => void;

class SyncBus {
  private readonly listeners = new Map<SyncTopic, Set<SyncListener>>();

  subscribe(topic: SyncTopic, listener: SyncListener): () => void {
    let set = this.listeners.get(topic);
    if (!set) {
      set = new Set();
      this.listeners.set(topic, set);
    }
    set.add(listener);
    return () => {
      set?.delete(listener);
    };
  }

  emit(topic: SyncTopic, payload?: unknown): void {
    const set = this.listeners.get(topic);
    if (!set) return;
    for (const listener of set) {
      try {
        listener(payload);
      } catch {
        // Keep other listeners running.
      }
    }
  }
}

export const AppSyncBus = new SyncBus();
