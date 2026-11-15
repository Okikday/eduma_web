import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { apiClient } from '../../../core/api/apiClient';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { ProfileAvatarButton } from '../../../shared/components/BadgesAndAvatars';
import { useFormFactor } from '../../../shared/components/formFactor';
import { useAuth } from '../../auth/data/AuthContext';
import { CalendarAgendaPanel } from './CalendarAgendaPanel';

export type MainTabKey = 'home' | 'calendar' | 'library';

interface MainShellProps {
  activeTab: MainTabKey;
  children: React.ReactNode;
  onQuickCreateSpace?: () => void;
  onQuickJoinSpace?: () => void;
  onQuickCreateEvent?: () => void;
}

const RAIL_ITEMS: ReadonlyArray<{
  key: MainTabKey;
  label: string;
  to: string;
  railActiveIcon: string;
  railIdleIcon: string;
  bottomStrokeIcon: string;
  bottomSolidFamily: 'huge-solid' | 'huge-stroke';
  bottomSolidIcon: string;
}> = [
  {
    key: 'home',
    label: 'Home',
    to: '/main',
    railActiveIcon: 'home_1',
    railIdleIcon: 'home_copy',
    bottomStrokeIcon: 'home07',
    bottomSolidFamily: 'huge-solid',
    bottomSolidIcon: 'home07',
  },
  {
    key: 'calendar',
    label: 'Calendar',
    to: '/calendarTab',
    railActiveIcon: 'calendar',
    railIdleIcon: 'calendar_1_copy',
    bottomStrokeIcon: 'calendar03',
    bottomSolidFamily: 'huge-solid',
    bottomSolidIcon: 'calendar03',
  },
  {
    key: 'library',
    label: 'Library',
    to: '/libraryTab',
    railActiveIcon: 'book',
    railIdleIcon: 'book_copy',
    bottomStrokeIcon: 'libraries',
    bottomSolidFamily: 'huge-solid',
    bottomSolidIcon: 'bookOpen02',
  },
];

const AGENDA_PANEL_MIN_WIDTH = 1180;

export function MainShell({
  activeTab,
  children,
  onQuickCreateSpace,
  onQuickJoinSpace,
  onQuickCreateEvent,
}: MainShellProps) {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { isExpanded, width } = useFormFactor();

  const [unreadCount, setUnreadCount] = useState(0);
  const [quickMenuOpen, setQuickMenuOpen] = useState(false);

  const showAgendaPanel =
    isExpanded && width >= AGENDA_PANEL_MIN_WIDTH && activeTab !== 'calendar';

  useEffect(() => {
    let active = true;

    const loadUnread = async () => {
      try {
        const countRes = await apiClient.get<{
          count?: number;
          unreadCount?: number;
        }>('/notifications/unread-count');
        const nextCount = Number(countRes?.unreadCount ?? countRes?.count ?? 0);
        if (active && Number.isFinite(nextCount)) setUnreadCount(nextCount);
      } catch {
        // Ignore transient badge load failure
      }
    };

    loadUnread();
    const unsub = AppSyncBus.subscribe('notifications:changed', loadUnread);
    return () => {
      active = false;
      unsub();
    };
  }, []);

  if (isExpanded) {
    return (
      <div className="flex h-screen w-full overflow-hidden bg-[var(--eduma-bg)]">
        {/* 84px MainNavRail matching ../eduma/lib/features/main/main/ui/desktop/main_nav_rail.dart */}
        <nav
          aria-label="Primary"
          className="flex h-full w-[84px] shrink-0 flex-col items-center bg-[var(--eduma-bg)] select-none"
        >
          <Link
            to="/main"
            aria-label="Eduma Home"
            className="mt-[18px] mb-[40px] flex h-[30px] w-[30px] items-center justify-center"
          >
            <img
              src="/assets/logo/logo.png"
              alt="Eduma"
              className="h-[30px] w-[30px] object-contain"
            />
          </Link>

          <div className="flex flex-col items-center gap-[6px]">
            {RAIL_ITEMS.map((item) => {
              const selected = activeTab === item.key;
              return (
                <Link
                  key={item.key}
                  to={item.to}
                  aria-current={selected ? 'page' : undefined}
                  className="group flex h-[62px] w-[68px] flex-col items-center justify-center gap-1"
                >
                  <div
                    className={`flex h-[30px] w-[52px] items-center justify-center rounded-[40px] transition-colors ${
                      selected
                        ? 'bg-[var(--eduma-text-primary)]/15'
                        : 'group-hover:bg-[var(--eduma-text-primary)]/8'
                    }`}
                  >
                    <EdumaIcon
                      family="iconsax"
                      name={selected ? item.railActiveIcon : item.railIdleIcon}
                      size={22}
                      color={
                        selected
                          ? 'var(--eduma-text-primary)'
                          : 'var(--eduma-text-muted)'
                      }
                    />
                  </div>
                  <span
                    className={`text-[12px] leading-none ${
                      selected
                        ? 'font-semibold text-[var(--eduma-text-primary)]'
                        : 'font-normal text-[var(--eduma-text-muted)]'
                    }`}
                  >
                    {item.label}
                  </span>
                </Link>
              );
            })}
          </div>

          {/* NavRailFooter: Notifications + ProfileAvatarButton(42) */}
          <div className="mt-auto flex flex-col items-center gap-1 pb-4">
            <button
              type="button"
              onClick={() => navigate('/notifications')}
              aria-label="Notifications"
              title="Notifications"
              className="relative flex h-[42px] w-[42px] cursor-pointer items-center justify-center rounded-full text-[var(--eduma-text-primary)] transition hover:bg-[var(--eduma-text-primary)]/8"
            >
              <EdumaIcon
                family="iconsax"
                name="notification_status_copy"
                size={22}
              />
              {unreadCount > 0 ? (
                <span className="absolute top-1.5 right-1.5 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-[var(--eduma-error)] px-1 text-[10px] font-bold text-white">
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              ) : null}
            </button>

            <ProfileAvatarButton
              name={user?.name}
              avatarUrl={user?.avatarUrl}
              size={42}
              onClick={() => navigate('/profile')}
            />
          </div>
        </nav>

        {/* 0.5px Vertical Rail Divider */}
        <div className="h-full w-[0.5px] shrink-0 bg-[var(--eduma-border)]" />

        {/* Center Active Tab Pane + DesktopQuickNoteFab */}
        <main className="relative flex h-full min-w-0 flex-1 flex-col overflow-hidden bg-[var(--eduma-bg)]">
          <div className="h-full min-h-0 flex-1 overflow-y-auto">
            {children}
          </div>

          {/* DesktopQuickNoteFab */}
          <div className="absolute right-[24px] bottom-[24px] z-20 flex flex-col items-end gap-2">
            {quickMenuOpen ? (
              <div className="w-52 rounded-[20px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] p-1.5 shadow-xl">
                {onQuickCreateSpace ? (
                  <button
                    type="button"
                    onClick={() => {
                      setQuickMenuOpen(false);
                      onQuickCreateSpace();
                    }}
                    className="flex w-full cursor-pointer items-center gap-2.5 rounded-[14px] px-3 py-2 text-left text-[13px] font-semibold text-[var(--eduma-text-primary)] hover:bg-[var(--eduma-card)]"
                  >
                    <EdumaIcon family="huge-stroke" name="folderAdd" size={16} color="var(--eduma-primary)" />
                    <span>New study space</span>
                  </button>
                ) : null}
                {onQuickJoinSpace ? (
                  <button
                    type="button"
                    onClick={() => {
                      setQuickMenuOpen(false);
                      onQuickJoinSpace();
                    }}
                    className="flex w-full cursor-pointer items-center gap-2.5 rounded-[14px] px-3 py-2 text-left text-[13px] font-semibold text-[var(--eduma-text-primary)] hover:bg-[var(--eduma-card)]"
                  >
                    <EdumaIcon family="iconsax" name="login_copy" size={16} />
                    <span>Join with code</span>
                  </button>
                ) : null}
                <button
                  type="button"
                  onClick={() => {
                    setQuickMenuOpen(false);
                    if (onQuickCreateEvent) onQuickCreateEvent();
                    else navigate('/calendarTab?create=1');
                  }}
                  className="flex w-full cursor-pointer items-center gap-2.5 rounded-[14px] px-3 py-2 text-left text-[13px] font-semibold text-[var(--eduma-text-primary)] hover:bg-[var(--eduma-card)]"
                >
                  <EdumaIcon family="huge-stroke" name="calendarAdd01" size={16} />
                  <span>New event</span>
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setQuickMenuOpen(false);
                    navigate('/assistantHistory');
                  }}
                  className="flex w-full cursor-pointer items-center gap-2.5 rounded-[14px] px-3 py-2 text-left text-[13px] font-semibold text-[var(--eduma-text-primary)] hover:bg-[var(--eduma-card)]"
                >
                  <EdumaIcon family="huge-stroke" name="sparkles" size={16} color="var(--accent-violet)" />
                  <span>Ask Eduma AI</span>
                </button>
              </div>
            ) : null}

            <button
              type="button"
              onClick={() => setQuickMenuOpen((v) => !v)}
              aria-label="Quick actions"
              title="Quick actions"
              className="flex h-12 w-12 cursor-pointer items-center justify-center rounded-full bg-[var(--eduma-primary)] text-white shadow-lg transition hover:brightness-105 active:scale-95"
            >
              <EdumaIcon
                family="huge-stroke"
                name={quickMenuOpen ? 'cancel01' : 'add01'}
                size={21}
              />
            </button>
          </div>
        </main>

        {/* Right CalendarAgendaPanel (>= 1180px on non-calendar tabs) */}
        {showAgendaPanel ? (
          <>
            <div className="h-full w-[0.5px] shrink-0 bg-[var(--eduma-border)]" />
            <CalendarAgendaPanel onCreateEvent={onQuickCreateEvent} />
          </>
        ) : null}
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--eduma-bg)] pb-[104px]">
      {children}

      {/* MainBottomNavBar: 216x68 floating pill + SpecialActionButton */}
      <nav
        aria-label="Mobile Navigation"
        className="pointer-events-none fixed inset-x-0 bottom-4 z-30 flex items-center justify-center gap-5 px-4"
      >
        <div className="pointer-events-auto flex h-[68px] w-[216px] items-center rounded-[40px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)]/97 p-1 shadow-[0_12px_36px_rgba(16,24,40,0.16)] backdrop-blur-xl">
          {RAIL_ITEMS.map((item) => {
            const selected = activeTab === item.key;
            return (
              <Link
                key={item.key}
                to={item.to}
                aria-label={item.label}
                aria-current={selected ? 'page' : undefined}
                className={`flex h-full flex-1 items-center justify-center rounded-[40px] transition-colors ${
                  selected
                    ? 'bg-[var(--eduma-text-primary)]/15 text-[var(--eduma-text-primary)]'
                    : 'text-[var(--eduma-text-muted)]'
                }`}
              >
                <EdumaIcon
                  family={selected ? item.bottomSolidFamily : 'huge-stroke'}
                  name={selected ? item.bottomSolidIcon : item.bottomStrokeIcon}
                  size={22}
                />
              </Link>
            );
          })}
        </div>

        <button
          type="button"
          onClick={() => navigate('/assistantHistory')}
          aria-label="Eduma AI Assistant"
          className="pointer-events-auto flex h-[58px] w-[58px] shrink-0 cursor-pointer items-center justify-center rounded-full bg-gradient-to-br from-[#4B24D2] via-[#7C3AED] to-[#EC4899] text-white shadow-lg transition active:scale-95"
        >
          <EdumaIcon family="huge-stroke" name="sparkles" size={23} />
        </button>
      </nav>
    </div>
  );
}
