import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../auth/logic/auth_actions.dart';
import '../../../main/data/main_space.dart';
import '../../../main/logic/main_actions.dart';
import '../../../main/presentation/widgets/app_tab_shell.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../logic/notifications_actions.dart';

/// Notifications inbox (`/notifications`) matching `NotificationsView` via
/// `adaptivePageScaffold` (`maxWidth: 640`).
class NotificationsPage extends StatefulComponent {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _pageLimit = 25;

  EdumaSession? _session = AuthActions.currentSession;
  bool _loadingSession = AuthActions.currentSession == null;
  String? _sessionError;

  NotificationFilterTab _filter = .all;
  List<EdumaNotification> _items = const [];
  int _unreadCount = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _markingAll = false;
  Set<String> _busyIds = const {};
  String? _error;
  String? _notice;
  bool _noticeIsError = false;

  @override
  void initState() {
    super.initState();
    final session = _session;
    if (session != null) {
      EdumaMemoryCache.instance.ensureUser(session.userId);
      final cached = EdumaMemoryCache.instance.notifications;
      if (cached != null) {
        _items = cached.items;
        _unreadCount = cached.unreadCount;
        _hasMore = cached.hasMore;
      } else {
        _unreadCount = EdumaMemoryCache.instance.unreadNotifications ?? 0;
      }
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    final hasCached = _items.isNotEmpty;
    setState(() {
      _loadingSession = _session == null;
      _loading = !hasCached;
      _sessionError = null;
      _error = null;
    });

    try {
      final session = await AuthActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() => _session = null);
        return;
      }
      EdumaMemoryCache.instance.ensureUser(session.userId);
      setState(() => _session = session);
      await Future.wait([
        _loadPage(reset: true),
        _refreshUnreadCount(),
      ]);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _sessionError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sessionError = 'Could not load notifications right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshUnreadCount() async {
    final count = await NotificationsActions.loadUnreadCount();
    if (!mounted) return;
    EdumaMemoryCache.instance.unreadNotifications = count;
    setState(() => _unreadCount = count);
  }

  void _syncNotificationsCache() {
    EdumaMemoryCache.instance.unreadNotifications = _unreadCount;
    if (_filter == .all) {
      EdumaMemoryCache.instance.notifications = NotificationsCacheData(
        items: _items,
        unreadCount: _unreadCount,
        hasMore: _hasMore,
      );
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    final nextPage = reset ? 1 : _page + 1;
    final hasCachedAll = reset && _filter == .all && _items.isNotEmpty;
    setState(() {
      if (reset) {
        _loading = !hasCachedAll;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      // Backend filter accepts all/unread/invites cleanly; schedule fetches all and filters locally.
      final apiFilter = _filter == .schedule ? NotificationFilterTab.all : _filter;
      final result = await NotificationsActions.loadNotifications(
        filter: apiFilter,
        page: nextPage,
        limit: _pageLimit,
      );
      if (!mounted) return;
      setState(() {
        _items = reset ? result.items : [..._items, ...result.items];
        _page = nextPage;
        _hasMore = result.hasMore;
        if (result.unreadCount != null) _unreadCount = result.unreadCount!;
      });
      _syncNotificationsCache();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load notifications.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _selectFilter(NotificationFilterTab tab) {
    if (_filter == tab) return;
    setState(() => _filter = tab);
    unawaited(_loadPage(reset: true));
  }

  Future<void> _toggleRead(EdumaNotification item) async {
    if (_busyIds.contains(item.id)) return;
    final nextRead = !item.isRead;
    setState(() => _busyIds = {..._busyIds, item.id});
    try {
      if (nextRead) {
        await NotificationsActions.markRead(item.id);
      } else {
        await NotificationsActions.markUnread(item.id);
      }
      if (!mounted) return;
      setState(() {
        _items = [
          for (final entry in _items)
            if (entry.id == item.id) entry.copyWith(isRead: nextRead) else entry,
        ];
        if (_filter == .unread && nextRead) {
          _items = _items.where((entry) => entry.id != item.id).toList();
        }
        _unreadCount = nextRead ? (_unreadCount > 0 ? _unreadCount - 1 : 0) : _unreadCount + 1;
      });
      _syncNotificationsCache();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = 'Could not update notification status.';
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busyIds = {..._busyIds}..remove(item.id));
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _unreadCount == 0) return;
    setState(() {
      _markingAll = true;
      _notice = null;
    });
    try {
      await NotificationsActions.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _filter == .unread ? const [] : [for (final item in _items) item.copyWith(isRead: true)];
        _unreadCount = 0;
        _notice = 'All notifications marked as read.';
        _noticeIsError = false;
      });
      _syncNotificationsCache();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = 'Could not mark all notifications as read.';
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _deleteItem(EdumaNotification item) async {
    if (_busyIds.contains(item.id)) return;
    setState(() => _busyIds = {..._busyIds, item.id});
    try {
      await NotificationsActions.deleteNotification(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((entry) => entry.id != item.id).toList();
        if (!item.isRead && _unreadCount > 0) _unreadCount--;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = 'Could not delete notification.';
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busyIds = {..._busyIds}..remove(item.id));
    }
  }

  Future<void> _handleInvite(EdumaNotification item, {required bool accept}) async {
    if (_busyIds.contains(item.id)) return;
    setState(() {
      _busyIds = {..._busyIds, item.id};
      _notice = null;
    });
    try {
      String? targetSpaceId = item.spaceId;
      if (accept) {
        if (item.inviteId != null) {
          targetSpaceId = await NotificationsActions.acceptInvite(item.inviteId!) ?? targetSpaceId;
        } else if (item.inviteCode != null) {
          final joined = await MainActions.joinSpace(item.inviteCode!);
          targetSpaceId = joined.spaceId ?? targetSpaceId;
        }
        await NotificationsActions.markRead(item.id);
      } else if (item.inviteId != null) {
        await NotificationsActions.declineInvite(item.inviteId!);
        await NotificationsActions.markRead(item.id);
      }
      if (!mounted) return;
      setState(() {
        _items = [
          for (final entry in _items)
            if (entry.id == item.id) entry.copyWith(isRead: true) else entry,
        ];
        if (!item.isRead && _unreadCount > 0) _unreadCount--;
        _notice = accept
            ? 'Space invite accepted${targetSpaceId != null ? ' — open Space detail to jump in.' : '.'}'
            : 'Invite declined.';
        _noticeIsError = false;
      });
      _syncNotificationsCache();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error.message;
        _noticeIsError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = accept ? 'Could not accept invite.' : 'Could not decline invite.';
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busyIds = {..._busyIds}..remove(item.id));
    }
  }

  @override
  Component build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return adaptivePageScaffold(
        title: 'Notifications',
        maxWidth: 640,
        fullBleed: true,
        fallbackHref: '/home',
        body: [
          appSessionGateBody(
            session: null,
            loadingSession: _loadingSession,
            sessionError: _sessionError,
            onRetrySession: () => unawaited(_load()),
            builder: (_) => const [],
          ),
        ],
      );
    }

    final canMarkAll = _unreadCount > 0 && !_markingAll;
    final visibleItems = _items.where(_filter.matches).toList();

    return adaptivePageScaffold(
      title: 'Notifications',
      maxWidth: 640,
      fullBleed: true,
      fallbackHref: '/home',
      classes: 'eduma-notifications-page',
      trailing: button(
        classes: canMarkAll ? 'eduma-notifications__mark-all' : 'eduma-notifications__mark-all is-disabled',
        type: ButtonType.button,
        disabled: !canMarkAll,
        onClick: () => unawaited(_markAllRead()),
        [.text('Mark all read')],
      ),
      body: [
        if (_notice case final msg?) mainHomeNotice(msg, isError: _noticeIsError),
        if (_error case final err?)
          mainHomeNotice(
            err,
            isError: true,
            onRetry: () => unawaited(_loadPage(reset: true)),
          ),
        div(classes: 'eduma-notifications__filters', [
          for (final tab in NotificationFilterTab.values)
            button(
              classes: _filter == tab ? 'eduma-notifications__chip is-active' : 'eduma-notifications__chip',
              type: ButtonType.button,
              onClick: () => _selectFilter(tab),
              [.text(tab.label)],
            ),
        ]),
        if (visibleItems.isEmpty && !_loading)
          _emptyStateFor(_filter)
        else
          div(classes: 'eduma-notifications__list', [
            for (final item in visibleItems)
              _notificationCard(
                item,
                busy: _busyIds.contains(item.id),
                onToggleRead: () => unawaited(_toggleRead(item)),
                onDelete: () => unawaited(_deleteItem(item)),
                onAcceptInvite: (item.inviteId != null || item.inviteCode != null)
                    ? () => unawaited(_handleInvite(item, accept: true))
                    : null,
                onDeclineInvite: item.inviteId != null
                    ? () => unawaited(_handleInvite(item, accept: false))
                    : null,
              ),
          ]),
        if (_hasMore)
          div(classes: 'main-home__load-more', [
            button(
              classes: 'main-home__load-more-button',
              type: ButtonType.button,
              disabled: _loadingMore,
              onClick: () => unawaited(_loadPage(reset: false)),
              [
                edumaIcon(EdumaIcons.refresh, size: 16),
                .text(_loadingMore ? 'Loading…' : 'Load earlier notifications'),
              ],
            ),
          ]),
      ],
    );
  }
}

Component _emptyStateFor(NotificationFilterTab filter) {
  final (title, subtitle) = switch (filter) {
    .unread => ('No unread notifications', "You've read everything. Nice work!"),
    .invites => ('No invites yet', 'Space invitations and join requests will appear here'),
    .schedule => ('No schedule reminders', 'Upcoming class and study session reminders will show up here'),
    .all => ("You're all caught up!", 'New invites, reminders and milestones will show up here'),
  };
  return div(classes: 'eduma-notifications__empty', [
    span(classes: 'eduma-notifications__empty-icon', [
      edumaIcon(EdumaIcons.notifications, size: 28),
    ]),
    strong([.text(title)]),
    p([.text(subtitle)]),
  ]);
}

Object _notificationIcon(EdumaNotificationKind kind) => switch (kind) {
  .invite => EdumaIcons.people,
  .schedule => EdumaIcons.calendar,
  .milestone => EdumaIcons.award,
  .streak => EdumaIcons.flash,
  .mention => EdumaIcons.messageText,
  .space => EdumaIcons.element4,
  .joinRequest => EdumaIcons.userAdd,
  .joinApproved => EdumaIcons.tickCircle,
  .joinDeclined => EdumaIcons.closeCircle,
  .whatsapp => EdumaIcons.whatsapp,
  .system => EdumaIcons.notifications,
};

Component _notificationCard(
  EdumaNotification item, {
  required bool busy,
  required VoidCallback onToggleRead,
  required VoidCallback onDelete,
  VoidCallback? onAcceptInvite,
  VoidCallback? onDeclineInvite,
}) {
  final kind = item.kind;
  final classes = [
    'eduma-notifications__item',
    'eduma-notifications__item--${kind.cssModifier}',
    if (!item.isRead) 'is-unread',
  ].join(' ');
  final timeLabel = formatRelativeTimeLabel(item.createdAt);

  return article(classes: classes, [
    span(classes: 'eduma-notifications__icon', [
      edumaIcon(_notificationIcon(kind), size: 20),
    ]),
    div(classes: 'eduma-notifications__copy', [
      div(classes: 'eduma-notifications__top', [
        span(classes: 'eduma-notifications__badge', [.text(kind.label)]),
        if (timeLabel.isNotEmpty) span(classes: 'eduma-notifications__time', [.text(timeLabel)]),
        if (!item.isRead)
          span(classes: 'eduma-notifications__unread-dot', attributes: {'aria-label': 'Unread'}, []),
      ]),
      h3([.text(item.title)]),
      if (item.body.isNotEmpty) p([.text(item.body)]),
      if (kind == .invite && item.inviteStatus == 'requested')
        div(classes: 'eduma-notifications__outcome', [
          edumaIcon(EdumaIcons.clock, size: 14),
          .text('Request sent · waiting for approval'),
        ])
      else if (kind == .joinRequest && item.requestStatus == 'approved')
        div(classes: 'eduma-notifications__outcome is-success', [
          edumaIcon(EdumaIcons.tickCircle, size: 14),
          .text('Approved · added to the space'),
        ])
      else if (kind == .joinRequest && item.requestStatus == 'declined')
        div(classes: 'eduma-notifications__outcome', [
          edumaIcon(EdumaIcons.closeCircle, size: 14),
          .text('Declined'),
        ]),
      div(classes: 'eduma-notifications__actions', [
        if (item.canAcceptInvite && onAcceptInvite != null)
          button(
            classes: 'eduma-notifications__invite-btn',
            type: ButtonType.button,
            disabled: busy,
            onClick: onAcceptInvite,
            [
              edumaIcon(EdumaIcons.userAdd, size: 14),
              .text(busy ? 'Joining…' : 'Accept & Join Space'),
            ],
          ),
        if (item.isInvite && onDeclineInvite != null)
          button(
            classes: 'eduma-notifications__decline-btn',
            type: ButtonType.button,
            disabled: busy,
            onClick: onDeclineInvite,
            [.text('Decline')],
          ),
        if (item.spaceId != null)
          edumaLink(
            to: '/spaceDetail?id=${Uri.encodeQueryComponent(item.spaceId!)}',
            classes: 'eduma-space-link',
            children: [edumaIcon(EdumaIcons.layer, size: 14), .text('Open space')],
          ),
        button(
          classes: 'eduma-notifications__text-btn',
          type: ButtonType.button,
          disabled: busy,
          onClick: onToggleRead,
          [.text(item.isRead ? 'Mark unread' : 'Mark read')],
        ),
        button(
          classes: 'eduma-notifications__text-btn eduma-notifications__text-btn--danger',
          type: ButtonType.button,
          disabled: busy,
          onClick: onDelete,
          [.text('Delete')],
        ),
      ]),
    ]),
  ]);
}
