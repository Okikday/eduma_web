import { useCallback, useEffect, useState } from 'react';
import { apiClient } from '../../../core/api/apiClient';
import { AppSyncBus } from '../../../core/cache/memoryCache';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import { AppButton } from '../../../shared/components/AppButton';
import { AppEmptyState } from '../../../shared/components/AppEmptyState';
import { AppSegmentedControl } from '../../../shared/components/AppSegmentedControl';
import { useToast } from '../../../shared/components/AppToast';
import { UserAvatar } from '../../../shared/components/BadgesAndAvatars';
import { DesktopPopupFrame } from '../../../shared/components/DesktopPopupFrame';
import { useFormFactor } from '../../../shared/components/formFactor';
import { PureAppBar } from '../../../shared/components/PureAppBar';

interface StreakDay {
  label: string;
  done: boolean;
}

interface LeaderboardEntry {
  id: string;
  name: string;
  avatarUrl?: string | null;
  streak: number;
  minutes: number;
  rank: number;
}

export function StreakView() {
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();

  const [currentStreak, setCurrentStreak] = useState(0);
  const [longestStreak, setLongestStreak] = useState(0);
  const [todayMinutes, setTodayMinutes] = useState(0);
  const [dailyGoalMinutes, setDailyGoalMinutes] = useState(20);
  const [weekDays, setWeekDays] = useState<StreakDay[]>([]);
  const [scope, setScope] = useState<'friends' | 'spaces' | 'global'>('friends');
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [logging, setLogging] = useState(false);

  const loadStreak = useCallback(async () => {
    try {
      const tzOffsetMinutes = -new Date().getTimezoneOffset();
      const [meRes, lbRes] = await Promise.all([
        apiClient
          .get<Record<string, unknown>>('/streaks/me', {
            params: { days: 7, tzOffsetMinutes },
          })
          .catch(() => null),
        apiClient
          .get<unknown>('/streaks/leaderboard', {
            params: { scope, period: 'week', limit: 20 },
          })
          .catch(() => null),
      ]);

      if (meRes) {
        setCurrentStreak(Number(meRes.current ?? meRes.currentStreak ?? 0));
        setLongestStreak(Number(meRes.longest ?? meRes.longestStreak ?? 0));
        setTodayMinutes(Number(meRes.todayMinutes ?? meRes.minutesToday ?? 0));
        setDailyGoalMinutes(Number(meRes.dailyGoalMinutes ?? meRes.goalMinutes ?? 20));
        if (Array.isArray(meRes.days)) {
          setWeekDays(
            (meRes.days as Record<string, unknown>[]).map((d, idx) => ({
              label: String(d.label || d.day || `D${idx + 1}`).slice(0, 3),
              done: Boolean(d.done ?? d.completed ?? (Number(d.minutes ?? 0) > 0)),
            }))
          );
        }
      }

      const rawLb = Array.isArray(lbRes)
        ? lbRes
        : lbRes && typeof lbRes === 'object'
        ? ((lbRes as Record<string, unknown>).entries ??
            (lbRes as Record<string, unknown>).leaderboard ??
            (lbRes as Record<string, unknown>).users ??
            [])
        : [];
      if (Array.isArray(rawLb)) {
        setLeaderboard(
          (rawLb as Record<string, unknown>[]).map((row, idx) => ({
            id: String(row.id || row.userId || idx),
            name: String(row.name || 'Student'),
            avatarUrl: typeof row.avatarUrl === 'string' ? row.avatarUrl : null,
            streak: Number(row.streak ?? row.currentStreak ?? 0),
            minutes: Number(row.minutes ?? row.totalMinutes ?? 0),
            rank: Number(row.rank ?? idx + 1),
          }))
        );
      }
    } catch {
      // Ignore transient errors.
    }
  }, [scope]);

  useEffect(() => {
    loadStreak();
  }, [loadStreak]);

  const handleLogStudy = async () => {
    setLogging(true);
    try {
      await apiClient.post('/streaks/activity', {
        minutes: 15,
        source: 'web',
      });
      showToast('+15 study minutes logged!', 'success');
      AppSyncBus.emit('streaks:changed');
      await loadStreak();
    } catch (err) {
      showToast(
        err instanceof Error ? err.message : 'Unable to log activity.',
        'error'
      );
    } finally {
      setLogging(false);
    }
  };

  const progress = Math.min(1, Math.max(0, todayMinutes / Math.max(1, dailyGoalMinutes)));
  const radius = 30;
  const circumference = 2 * Math.PI * radius;
  const dashOffset = circumference * (1 - progress);

  const displayDays: StreakDay[] =
    weekDays.length === 7
      ? weekDays
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => ({
          label: d,
          done: false,
        }));

  const overviewSection = (
    <>
      {/* StreakHeroCard matching ../eduma/lib/features/streaks/ui/widgets/streak_hero_card.dart */}
      <section
        className="flex flex-wrap items-center justify-between gap-4 rounded-[24px] border p-5"
        style={{
          borderColor:
            currentStreak > 0
              ? 'color-mix(in srgb, var(--eduma-warning) 35%, transparent)'
              : 'var(--eduma-border)',
          background:
            'color-mix(in srgb, var(--eduma-warning) 9%, var(--eduma-surface))',
        }}
      >
        <div className="flex items-center gap-4">
          <div className="relative flex h-[76px] w-[76px] items-center justify-center">
            <svg className="h-full w-full -rotate-90" viewBox="0 0 72 72">
              <circle
                cx="36"
                cy="36"
                r={radius}
                fill="none"
                stroke="color-mix(in srgb, var(--eduma-warning) 20%, transparent)"
                strokeWidth="6"
              />
              <circle
                cx="36"
                cy="36"
                r={radius}
                fill="none"
                stroke={progress >= 1 ? 'var(--eduma-warning)' : 'var(--eduma-primary)'}
                strokeWidth="6"
                strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={dashOffset}
              />
            </svg>
            <span className="absolute">
              <EdumaIcon
                family={currentStreak > 0 ? 'huge-solid' : 'huge-stroke'}
                name="fire"
                size={30}
                color={currentStreak > 0 ? 'var(--eduma-warning)' : 'var(--eduma-primary)'}
              />
            </span>
          </div>

          <div>
            <p className="type-display-sm text-[var(--eduma-text-primary)]">
              {currentStreak} {currentStreak === 1 ? 'day' : 'days'}
            </p>
            <p className="type-body-sm text-[var(--eduma-text-secondary)]">
              {todayMinutes} / {dailyGoalMinutes} min today · Longest: {longestStreak}d
            </p>
          </div>
        </div>

        <AppButton size="sm" loading={logging} onClick={handleLogStudy}>
          Log 15m study
        </AppButton>
      </section>

      {/* 7-Day Week Strip */}
      <section className="eduma-card-surface rounded-[22px] p-5">
        <h2 className="type-title-md mb-4 text-[var(--eduma-text-primary)]">
          This week
        </h2>
        <div className="grid grid-cols-7 gap-2">
          {displayDays.map((day) => (
            <div key={day.label} className="flex flex-col items-center gap-2">
              <span className="text-[11.5px] font-semibold text-[var(--eduma-text-muted)]">
                {day.label}
              </span>
              <span
                className={`flex h-9 w-9 items-center justify-center rounded-full border ${
                  day.done
                    ? 'border-[var(--eduma-warning)] bg-[var(--eduma-warning)] text-white'
                    : 'border-[var(--eduma-border)] bg-[var(--eduma-bg)] text-[var(--eduma-text-muted)]'
                }`}
              >
                <EdumaIcon
                  family={day.done ? 'huge-solid' : 'huge-stroke'}
                  name={day.done ? 'fire' : 'tick01'}
                  size={16}
                />
              </span>
            </div>
          ))}
        </div>
      </section>
    </>
  );

  const leaderboardSection = (
    <section className="eduma-card-surface rounded-[22px] p-5">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h2 className="type-title-md text-[var(--eduma-text-primary)]">
          Weekly leaderboard
        </h2>
        <AppSegmentedControl
          value={scope}
          onChange={setScope}
          options={[
            { value: 'friends', label: 'Friends' },
            { value: 'spaces', label: 'Spaces' },
            { value: 'global', label: 'Global' },
          ]}
        />
      </div>

      {leaderboard.length === 0 ? (
        <AppEmptyState
          compact
          iconName="award_copy"
          iconFamily="iconsax"
          title="No leaderboard entries yet"
          description="Study sessions logged by you and classmates appear here."
        />
      ) : (
        <div className="space-y-2">
          {leaderboard.map((entry) => (
            <div
              key={entry.id}
              className="flex items-center justify-between gap-3 rounded-[14px] border border-[var(--eduma-border-subtle)] bg-[var(--eduma-bg)]/60 p-3"
            >
              <div className="flex min-w-0 items-center gap-3">
                <span className="w-6 text-center text-[13px] font-bold text-[var(--eduma-text-muted)]">
                  #{entry.rank}
                </span>
                <UserAvatar person={entry} size={34} />
                <span className="type-title-sm truncate text-[var(--eduma-text-primary)]">
                  {entry.name}
                </span>
              </div>
              <div className="flex items-center gap-3 text-[13px] font-bold">
                <span className="text-[var(--eduma-warning)]">
                  {entry.streak}d
                </span>
                <span className="text-[var(--eduma-text-muted)]">
                  {entry.minutes}m
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );

  if (isExpanded) {
    return (
      <DesktopPopupFrame maxWidth={880} backTo="/main">
        <PureAppBar title="Study Streak" backTo="/main" />
        <div className="flex items-start gap-7 p-7">
          <div className="w-[340px] shrink-0 space-y-5">{overviewSection}</div>
          <div className="min-w-0 flex-1">{leaderboardSection}</div>
        </div>
      </DesktopPopupFrame>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">
      <PureAppBar title="Study Streak" backTo="/main" />
      <div className="mx-auto w-full max-w-[920px] space-y-6 px-4 py-6 sm:px-6">
        {overviewSection}
        {leaderboardSection}
      </div>
    </div>
  );
}
