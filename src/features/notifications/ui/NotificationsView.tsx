import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiClient } from '../../../core/api/apiClient';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { formatRelativeTime } from '../../../core/utils/dateFormatters';
import { AppButton } from '../../../shared/components/AppButton';
import { AppCircleIconButton } from '../../../shared/components/AppCircleIconButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { useToast } from '../../../shared/components/AppToast';
import { DesktopPageHeader } from '../../../shared/components/DesktopPageHeader';
import { DesktopPopupFrame } from '../../../shared/components/DesktopPopupFrame';
import { useFormFactor } from '../../../shared/components/formFactor';
import { PureAppBar } from '../../../shared/components/PureAppBar';

type NotificationType =
  | 'invite'
  | 'schedule'
  | 'milestone'
  | 'streak'
  | 'mention'
  | 'space'
  | 'joinRequest'
  | 'joinApproved'
  | 'joinDeclined'
  | 'whatsapp'
  | 'system';

type NotificationFilterKey = 'all' | 'unread' | 'invites' | 'schedule';

interface NotificationItem {
  id: string;
  title: string;
  body: string;
  type: NotificationType;
  isRead: boolean;
  inviteId?: string | null;
  spaceId?: string | null;
  createdAt?: string | null;
}

const FILTER_META: ReadonlyArray<{
  key: NotificationFilterKey;
  label: string;
  emptyTitle: string;
  emptyMessage: string;
}> = [
  {
    key: 'all',
    label: 'All',
    emptyTitle: "You're all caught up!",
    emptyMessage: 'New invites, reminders and milestones will show up here',
  },
  {
    key: 'unread',
    label: 'Unread',
    emptyTitle: 'No unread notifications',
    emptyMessage: "You've read everything. Nice work!",
  },
  {
    key: 'invites',
    label: 'Invites',
    emptyTitle: 'No invites yet',
    emptyMessage: 'Space invitations and join requests will appear here',
  },
  {
    key: 'schedule',
    label: 'Schedule',
    emptyTitle: 'No schedule updates',
    emptyMessage: 'Session reminders and schedule changes will appear here',
  },
];

const TYPE_STYLE: Record<
  NotificationType,
  { icon: string; badge: string; accent: string }
> = {
  invite: { icon: 'people_copy', badge: 'INVITATION', accent: 'var(--eduma-primary)' },
  schedule: { icon: 'calendar_1_copy', badge: 'SCHEDULE', accent: 'var(--accent-sky)' },
  milestone: { icon: 'award_copy', badge: 'MILESTONE', accent: 'var(--eduma-success)' },
  streak: { icon: 'flash_1_copy', badge: 'STREAK', accent: 'var(--eduma-warning)' },
  mention: { icon: 'message_text_copy', badge: 'MENTION', accent: 'var(--eduma-primary)' },
  space: { icon: 'element_4_copy', badge: 'SPACE', accent: 'var(--eduma-primary)' },
  joinRequest: { icon: 'user_add_copy', badge: 'JOIN REQUEST', accent: 'var(--eduma-primary)' },
  joinApproved: { icon: 'tick_circle_copy', badge: 'APPROVED', accent: 'var(--eduma-success)' },
  joinDeclined: { icon: 'close_circle_copy', badge: 'DECLINED', accent: 'var(--eduma-text-muted)' },
  whatsapp: { icon: 'whatsapp_copy', badge: 'WHATSAPP', accent: 'var(--eduma-whatsapp)' },
  system: { icon: 'notification_copy', badge: 'UPDATE', accent: 'var(--eduma-text-muted)' },
};

function normalizeType(raw?: string | null): NotificationType {
  const s = String(raw || '').toLowerCase();
  if (s === 'invite' || s === 'space_invite') return 'invite';
  if (s === 'schedule' || s === 'event_reminder') return 'schedule';
  if (s === 'milestone') return 'milestone';
  if (s === 'streak') return 'streak';
  if (s === 'mention') return 'mention';
  if (s === 'space') return 'space';
  if (s === 'joinrequest' || s === 'join_request') return 'joinRequest';
  if (s === 'joinapproved' || s === 'join_approved') return 'joinApproved';
  if (s === 'joindeclined' || s === 'join_declined') return 'joinDeclined';
  if (s === 'whatsapp') return 'whatsapp';
  return 'system';
}

export function NotificationsView() {
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();
  const navigate = useNavigate();

  const [filter, setFilter] = useState<NotificationFilterKey>('all');
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState(true);

  const loadNotifications = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiClient.get<{ notifications?: Record<string, unknown>[]; items?: Record<string, unknown>[] }>(
        '/notifications',
        { params: { filter: 'all', limit: 60 } }
      );
      const raw = Array.isArray(res)
        ? res
        : Array.isArray(res?.notifications)
        ? res.notifications
        : Array.isArray(res?.items)
        ? res.items
        : [];
      setItems(
        raw.map((n) => {
          const payload =
            n.payload && typeof n.payload === 'object'
              ? (n.payload as Record<string, unknown>)
              : null;
          return {
            id: String(n.id || n._id || ''),
            title: String(n.title || 'Notification'),
            body: String(n.body || n.message || ''),
            type: normalizeType(typeof n.type === 'string' ? n.type : null),
            isRead: Boolean(n.isRead ?? n.read ?? false),
            inviteId:
              typeof n.inviteId === 'string'
                ? n.inviteId
                : typeof payload?.inviteId === 'string'
                ? payload.inviteId
                : null,
            spaceId:
              typeof n.spaceId === 'string'
                ? n.spaceId
                : typeof payload?.spaceId === 'string'
                ? payload.spaceId
                : null,
            createdAt: typeof n.createdAt === 'string' ? n.createdAt : null,
          };
        })
      );
    } catch {
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadNotifications();
  }, [loadNotifications]);

  const filtered = useMemo(() => {
    return items.filter((item) => {
      if (filter === 'unread') return !item.isRead;
      if (filter === 'invites')
        return (
          item.type === 'invite' ||
          item.type === 'joinRequest' ||
          item.type === 'joinApproved' ||
          item.type === 'joinDeclined'
        );
      if (filter === 'schedule') return item.type === 'schedule';
      return true;
    });
  }, [items, filter]);

  const handleToggleRead = async (item: NotificationItem) => {
    const nextRead = !item.isRead;
    setItems((prev) =>
      prev.map((n) => (n.id === item.id ? { ...n, isRead: nextRead } : n))
    );
    await apiClient.patch(
      `/notifications/${encodeURIComponent(item.id)}/${
        nextRead ? 'read' : 'unread'
      }`,
      {}
    );
    AppSyncBus.emit('notifications:changed');
  };

  const handleMarkAllRead = async () => {
    await apiClient.post('/notifications/read-all', {});
    setItems((prev) => prev.map((n) => ({ ...n, isRead: true })));
    AppSyncBus.emit('notifications:changed');
    showToast('Marked all notifications as read.', 'success');
  };

  const handleInviteDecision = async (
    item: NotificationItem,
    action: 'accept' | 'decline'
  ) => {
    if (!item.inviteId) return;
    try {
      await apiClient.post(
        `/spaces/invites/${encodeURIComponent(item.inviteId)}/${action}`,
        {}
      );
      setItems((prev) => prev.filter((n) => n.id !== item.id));
      AppSyncBus.emit('notifications:changed');
      AppSyncBus.emit('spaces:changed');
      showToast(
        action === 'accept' ? 'Space invite accepted!' : 'Invite declined.',
        'success'
      );
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to respond to invite.',
        'error'
      );
    }
  };

  const handleDelete = async (id: string) => {
    setItems((prev) => prev.filter((n) => n.id !== id));
    await apiClient.delete(`/notifications/${encodeURIComponent(id)}`);
    AppSyncBus.emit('notifications:changed');
  };

  const currentMeta =
    FILTER_META.find((f) => f.key === filter) || FILTER_META[0];

  const markAllBtn = (
    <AppButton variant="secondary" size="sm" onClick={handleMarkAllRead}>
      Mark all read
    </AppButton>
  );

  const notificationsBody = (
    <>
      {!isExpanded ? (
        <PureAppBar title="Notifications" backTo="/main" trailing={markAllBtn} />
      ) : null}

      <div className={isExpanded ? 'px-7 pb-8 pt-2' : 'mx-auto w-full max-w-[880px] px-4 py-6 sm:px-6'}>
        {isExpanded ? (
          <DesktopPageHeader
            title="Notifications"
            subtitle="Space invites, reminders, streak updates, and comments"
            backTo="/main"
            trailing={markAllBtn}
          />
        ) : null}

        {/* Filter chips */}
        <div className="mb-5 flex flex-wrap gap-2">
          {FILTER_META.map((f) => (
            <button
              key={f.key}
              type="button"
              onClick={() => setFilter(f.key)}
              className={`cursor-pointer rounded-full border px-3.5 py-1.5 text-[13px] font-semibold transition ${
                filter === f.key
                  ? 'border-[var(--eduma-primary)] bg-[var(--eduma-primary)] text-white'
                  : 'border-[var(--eduma-border)] bg-[var(--eduma-surface)] text-[var(--eduma-text-secondary)]'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        {loading ? (
          <p className="type-body-md text-[var(--eduma-text-muted)]">Loading…</p>
        ) : filtered.length === 0 ? (
          <AppEmptyState
            iconFamily="iconsax"
            iconName="notification_copy"
            title={currentMeta.emptyTitle}
            description={currentMeta.emptyMessage}
          />
        ) : (
          <div className="space-y-2.5">
            {filtered.map((item) => {
              const style = TYPE_STYLE[item.type];
              return (
                <article
                  key={item.id}
                  className={`eduma-card-surface rounded-[20px] p-4 transition ${
                    item.isRead ? 'opacity-85' : 'border-[var(--eduma-primary)]/40'
                  }`}
                >
                  <div className="flex items-start gap-3.5">
                    <div
                      className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl text-white"
                      style={{ backgroundColor: style.accent }}
                    >
                      <EdumaIcon family="iconsax" name={style.icon} size={19} />
                    </div>

                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <span
                          className="text-[10.5px] font-bold tracking-wider"
                          style={{ color: style.accent }}
                        >
                          {style.badge}
                        </span>
                        <span className="text-[11.5px] text-[var(--eduma-text-muted)]">
                          {formatRelativeTime(item.createdAt)}
                        </span>
                      </div>

                      <h3 className="type-title-md mt-0.5 text-[var(--eduma-text-primary)]">
                        {item.title}
                      </h3>
                      {item.body ? (
                        <p className="type-body-sm mt-1 text-[var(--eduma-text-secondary)]">
                          {item.body}
                        </p>
                      ) : null}

                      <div className="mt-3 flex flex-wrap items-center gap-2">
                        {item.type === 'invite' && item.inviteId ? (
                          <>
                            <AppButton
                              size="sm"
                              onClick={() => handleInviteDecision(item, 'accept')}
                            >
                              Accept invite
                            </AppButton>
                            <AppButton
                              variant="secondary"
                              size="sm"
                              onClick={() => handleInviteDecision(item, 'decline')}
                            >
                              Decline
                            </AppButton>
                          </>
                        ) : item.spaceId ? (
                          <AppButton
                            variant="secondary"
                            size="sm"
                            onClick={() =>
                              navigate(
                                `/spaceDetail?id=${encodeURIComponent(
                                  item.spaceId!
                                )}`
                              )
                            }
                          >
                            Open space
                          </AppButton>
                        ) : null}

                        <button
                          type="button"
                          onClick={() => handleToggleRead(item)}
                          className="cursor-pointer px-2 py-1 text-[12px] font-semibold text-[var(--eduma-primary)] hover:underline"
                        >
                          {item.isRead ? 'Mark unread' : 'Mark read'}
                        </button>
                      </div>
                    </div>

                    <AppCircleIconButton
                      label="Delete notification"
                      size={32}
                      onClick={() => handleDelete(item.id)}
                    >
                      <EdumaIcon family="huge-stroke" name="cancel01" size={14} />
                    </AppCircleIconButton>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>
    </>
  );

  if (isExpanded) {
    return (
      <DesktopPopupFrame maxWidth={880} backTo="/main">
        {notificationsBody}
      </DesktopPopupFrame>
    );
  }

  return <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">{notificationsBody}</div>;
}
