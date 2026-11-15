import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { apiClient, unwrapData } from '../../../core/api/apiClient';
import { EdumaIcon } from '../../../core/icons/EdumaIcon';
import {
  APP_FONT_OPTIONS,
  useTheme,
  type ThemeMode,
} from '../../../core/theme/themeContext';
import { AppButton } from '../../../shared/components/AppButton';
import { AppModalDialog } from '../../../shared/components/AppModalDialog';
import { AppTextFormField } from '../../../shared/components/AppTextFormField';
import { useToast } from '../../../shared/components/AppToast';
import { UserAvatar, VerifiedBadge } from '../../../shared/components/BadgesAndAvatars';
import { DesktopSplitScaffold } from '../../../shared/components/DesktopSplitScaffold';
import { useFormFactor } from '../../../shared/components/formFactor';
import { PureAppBar } from '../../../shared/components/PureAppBar';
import { useAuth } from '../../auth/data/AuthContext';
import { authApi } from '../../auth/data/authApi';
import { ProfileDesktopHero, type ProfileStats } from './ProfileDesktopHero';
import { ProfileDesktopPanel } from './ProfileDesktopPanel';

interface MemoryItem {
  id: string;
  text: string;
  category?: string;
}

export function ProfileView() {
  const { user, logout, logoutAll, refreshProfile, updateLocalUser } = useAuth();
  const {
    themeMode,
    systemScheme,
    fontFamily,
    reduceBlur,
    setThemeMode,
    setFontFamily,
    setReduceBlur,
  } = useTheme();
  const { showToast } = useToast();
  const { isExpanded } = useFormFactor();
  const navigate = useNavigate();

  const [editOpen, setEditOpen] = useState(false);
  const [desktopTab, setDesktopTab] = useState<'profile' | 'settings'>('profile');
  const [settingsQuery, setSettingsQuery] = useState('');
  const [stats, setStats] = useState<ProfileStats>({
    spacesCount: 0,
    notebooksCount: 0,
    studyMinutes: 0,
  });
  const avatarInputRef = useRef<HTMLInputElement | null>(null);
  const nameInputRef = useRef<HTMLInputElement | null>(null);
  const [nameDraft, setNameDraft] = useState(user?.name || '');
  const [bioDraft, setBioDraft] = useState(user?.bio || '');
  const [goalDraft, setGoalDraft] = useState(user?.studyGoal || '');
  const [savingProfile, setSavingProfile] = useState(false);

  const loadStats = useCallback(async () => {
    try {
      const res = await apiClient.get<unknown>('/users/me/stats');
      const data = unwrapData<Record<string, unknown>>(res);
      setStats({
        spacesCount: Number(data.spacesCount ?? data.spaces ?? 0) || 0,
        notebooksCount: Number(data.notebooksCount ?? data.pagesCount ?? data.notebooks ?? 0) || 0,
        studyMinutes: Number(data.studyMinutes ?? data.totalMinutes ?? 0) || 0,
      });
    } catch {
      // Ignore optional stats failures on initial render.
    }
  }, []);

  useEffect(() => {
    void refreshProfile();
    void loadStats();
  }, [refreshProfile, loadStats]);

  useEffect(() => {
    setNameDraft(user?.name || '');
    setBioDraft(user?.bio || '');
    setGoalDraft(user?.studyGoal || '');
  }, [user?.name, user?.bio, user?.studyGoal]);

  const [memoryOpen, setMemoryOpen] = useState(false);
  const [memories, setMemories] = useState<MemoryItem[]>([]);
  const [feedbackOpen, setFeedbackOpen] = useState(false);
  const [feedbackText, setFeedbackText] = useState('');

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavingProfile(true);
    try {
      const updated = await apiClient.patch<Record<string, unknown>>('/users/me', {
        name: nameDraft.trim(),
        bio: bioDraft.trim(),
        studyGoal: goalDraft.trim(),
      });
      if (user) {
        updateLocalUser({
          ...user,
          name: String(updated?.name || nameDraft.trim()),
          bio: bioDraft.trim(),
          studyGoal: goalDraft.trim(),
        });
      }
      setEditOpen(false);
      showToast('Profile updated.', 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Unable to save profile.', 'error');
    } finally {
      setSavingProfile(false);
    }
  };

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const updated = await authApi.uploadAvatar(file);
      if (updated) updateLocalUser(updated);
      showToast('Profile photo updated.', 'success');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Photo upload failed.', 'error');
    }
  };

  const handleOpenMemory = async () => {
    setMemoryOpen(true);
    try {
      const res = await apiClient.get<{ memories?: Record<string, unknown>[]; items?: Record<string, unknown>[] }>(
        '/users/me/memory'
      );
      const raw = Array.isArray(res)
        ? res
        : Array.isArray(res?.memories)
        ? res.memories
        : Array.isArray(res?.items)
        ? res.items
        : [];
      setMemories(
        raw.map((m, idx) => ({
          id: String(m.id || m._id || idx),
          text: String(m.content || m.text || m.fact || ''),
          category: typeof m.category === 'string' ? m.category : undefined,
        }))
      );
    } catch {
      setMemories([]);
    }
  };

  const handleSendFeedback = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!feedbackText.trim()) return;
    await apiClient.post('/feedback', {
      message: feedbackText.trim(),
      source: 'web',
    });
    setFeedbackText('');
    setFeedbackOpen(false);
    showToast('Thanks for sharing feedback with the Eduma team!', 'success');
  };

  const handleSignOutAll = async () => {
    if (!window.confirm('Sign out across all active browsers and devices?')) return;
    await logoutAll();
    navigate('/sign-in', { replace: true });
  };

  const handleDeleteAccount = async () => {
    const confirmEmail = window.prompt(
      `Type your email (${user?.email || 'DELETE'}) to permanently delete your Eduma account:`
    );
    if (!confirmEmail || (user?.email && confirmEmail.trim() !== user.email)) return;
    await apiClient.delete('/users/me');
    await logout();
    navigate('/sign-in', { replace: true });
  };

  const themeOptions: ReadonlyArray<{
    id: ThemeMode;
    label: string;
    detail: string;
  }> = [
    { id: 'light', label: 'Light', detail: 'Always bright surface' },
    { id: 'dark', label: 'Dark', detail: 'Always low-glare dark' },
    {
      id: 'system',
      label: `System (Currently ${systemScheme})`,
      detail: 'Matches your device appearance automatically',
    },
  ];

  const normalizedSettingsQuery = settingsQuery.trim().toLowerCase();
  const matchesSetting = (keywords: string) =>
    !normalizedSettingsQuery || keywords.includes(normalizedSettingsQuery);

  const showAppearance = matchesSetting('appearance theme dark light system font typography blur transparency');
  const showAccount = matchesSetting('account profile study goal ai memory plan billing pro whatsapp integrations legal privacy terms feedback support');
  const showDanger = matchesSetting('session sign out logout devices delete account danger');

  const mainSettings = (
    <div className="space-y-6">
      {showAppearance ? (
        <>
          {/* Appearance Section (matching Three-state dark-mode-toggle rule) */}
          <section className="eduma-card-surface rounded-[22px] p-5">
        <h2 className="type-title-md text-[var(--eduma-text-primary)]">
          Appearance
        </h2>
        <p className="type-body-sm mt-0.5 text-[var(--eduma-text-muted)]">
          Customize theme polarity, typography, and backdrop blur.
        </p>

        <div className="mt-4 space-y-2">
          <p className="type-label-md text-[var(--eduma-text-secondary)]">
            Theme
          </p>
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
            {themeOptions.map((opt) => {
              const selected = themeMode === opt.id;
              return (
                <button
                  key={opt.id}
                  type="button"
                  onClick={() => setThemeMode(opt.id)}
                  className={`cursor-pointer rounded-[14px] border p-3 text-left transition ${
                    selected
                      ? 'border-[var(--eduma-primary)] bg-[var(--eduma-nav-pill)]'
                      : 'border-[var(--eduma-border)] bg-[var(--eduma-surface)]'
                  }`}
                >
                  <p className="type-title-sm text-[var(--eduma-text-primary)]">
                    {opt.label}
                  </p>
                  <p className="mt-0.5 text-[11.5px] text-[var(--eduma-text-muted)]">
                    {opt.detail}
                  </p>
                </button>
              );
            })}
          </div>
        </div>

        <div className="mt-5">
          <p className="type-label-md text-[var(--eduma-text-secondary)]">
            App Font
          </p>
          <div className="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-3">
            {APP_FONT_OPTIONS.map((font) => (
              <button
                key={font.id}
                type="button"
                onClick={() => setFontFamily(font.id)}
                className={`cursor-pointer rounded-[13px] border px-3 py-2 text-left text-[13px] font-semibold transition ${
                  fontFamily === font.id
                    ? 'border-[var(--eduma-primary)] bg-[var(--eduma-nav-pill)] text-[var(--eduma-primary)]'
                    : 'border-[var(--eduma-border)] bg-[var(--eduma-surface)] text-[var(--eduma-text-primary)]'
                }`}
              >
                {font.label}
              </button>
            ))}
          </div>
        </div>

        <label className="mt-5 flex cursor-pointer items-center justify-between gap-3 rounded-[14px] border border-[var(--eduma-border-subtle)] bg-[var(--eduma-bg)]/50 px-4 py-3">
          <div>
            <p className="type-title-sm text-[var(--eduma-text-primary)]">
              Reduce transparency &amp; blur
            </p>
            <p className="type-body-sm text-[var(--eduma-text-muted)]">
              Improves contrast and battery life on lower-power displays.
            </p>
          </div>
          <input
            type="checkbox"
            checked={reduceBlur}
            onChange={(e) => setReduceBlur(e.target.checked)}
            className="h-4 w-4 accent-[var(--eduma-primary)]"
          />
        </label>
          </section>
        </>
      ) : null}

      {showAccount ? (
        <>
          {/* Account, Plan, Integrations, Legal */}
          <section className="eduma-card-surface overflow-hidden rounded-[22px]">
        <div className="divide-y divide-[var(--eduma-border-subtle)]">
          <button
            type="button"
            onClick={() => {
              setNameDraft(user?.name || '');
              setBioDraft(user?.bio || '');
              setGoalDraft(user?.studyGoal || '');
              setEditOpen(true);
            }}
            className="flex w-full cursor-pointer items-center justify-between px-5 py-3.5 text-left hover:bg-[var(--eduma-bg)]/50"
          >
            <div className="flex items-center gap-3">
              <EdumaIcon family="iconsax" name="user_edit_copy" size={18} />
              <span className="type-title-sm">Edit profile &amp; study goal</span>
            </div>
            <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
          </button>

          <button
            type="button"
            onClick={handleOpenMemory}
            className="flex w-full cursor-pointer items-center justify-between px-5 py-3.5 text-left hover:bg-[var(--eduma-bg)]/50"
          >
            <div className="flex items-center gap-3">
              <EdumaIcon family="huge-stroke" name="sparkles" size={18} />
              <span className="type-title-sm">What Eduma remembers</span>
            </div>
            <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
          </button>

          <Link
            to="/premium"
            className="flex items-center justify-between px-5 py-3.5 hover:bg-[var(--eduma-bg)]/50"
          >
            <div className="flex items-center gap-3">
              <EdumaIcon family="huge-solid" name="crown" size={18} color="var(--eduma-gold)" />
              <span className="type-title-sm">Plan &amp; Billing</span>
            </div>
            <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
          </Link>

          <Link
            to="/whatsapp"
            className="flex items-center justify-between px-5 py-3.5 hover:bg-[var(--eduma-bg)]/50"
          >
            <div className="flex items-center gap-3">
              <EdumaIcon family="iconsax" name="whatsapp_copy" size={18} color="var(--eduma-whatsapp)" />
              <span className="type-title-sm">WhatsApp Companion</span>
            </div>
            <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
          </Link>

          <button
            type="button"
            onClick={() => setFeedbackOpen(true)}
            className="flex w-full cursor-pointer items-center justify-between px-5 py-3.5 text-left hover:bg-[var(--eduma-bg)]/50"
          >
            <div className="flex items-center gap-3">
              <EdumaIcon family="huge-stroke" name="informationCircle" size={18} />
              <span className="type-title-sm">Help &amp; Support</span>
            </div>
            <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
          </button>

          <Link
            to="/legalDocument?id=privacy"
            className="flex items-center justify-between px-5 py-3.5 hover:bg-[var(--eduma-bg)]/50"
          >
            <div className="flex items-center gap-3">
              <EdumaIcon family="huge-stroke" name="shield01" size={18} />
              <span className="type-title-sm">Privacy, Terms &amp; Legal</span>
            </div>
            <EdumaIcon family="huge-stroke" name="arrowRight01" size={16} />
          </Link>
        </div>
          </section>
        </>
      ) : null}

      {showDanger ? (
        <>
          {/* Session & Danger Actions */}
          <section className="eduma-card-surface rounded-[22px] p-5">
        <div className="flex flex-wrap items-center gap-3">
          <AppButton
            variant="secondary"
            onClick={async () => {
              await logout();
              navigate('/sign-in', { replace: true });
            }}
          >
            Sign out
          </AppButton>
          <AppButton variant="ghost" onClick={handleSignOutAll}>
            Sign out all devices
          </AppButton>
          <AppButton variant="danger" onClick={handleDeleteAccount}>
            Delete account
          </AppButton>
        </div>
      </section>
        </>
      ) : null}

      {!showAppearance && !showAccount && !showDanger ? (
        <div className="eduma-card-surface rounded-[22px] p-6 text-center">
          <p className="type-title-sm text-[var(--eduma-text-primary)]">
            No matching settings
          </p>
          <p className="type-body-sm mt-1 text-[var(--eduma-text-muted)]">
            Try clearing your search filter.
          </p>
        </div>
      ) : null}
    </div>
  );

  const profileTabContent = (
    <div className="space-y-4">
      <div className="grid grid-cols-3 gap-3">
        <div className="eduma-card-surface rounded-[18px] p-4">
          <p className="text-[11.5px] font-bold uppercase tracking-wider text-[var(--eduma-text-muted)]">
            Spaces
          </p>
          <p className="mt-1 text-[22px] font-bold text-[var(--eduma-text-primary)]">
            {stats.spacesCount}
          </p>
        </div>
        <div className="eduma-card-surface rounded-[18px] p-4">
          <p className="text-[11.5px] font-bold uppercase tracking-wider text-[var(--eduma-text-muted)]">
            Pages
          </p>
          <p className="mt-1 text-[22px] font-bold text-[var(--eduma-text-primary)]">
            {stats.notebooksCount}
          </p>
        </div>
        <div className="eduma-card-surface rounded-[18px] p-4">
          <p className="text-[11.5px] font-bold uppercase tracking-wider text-[var(--eduma-text-muted)]">
            Study time
          </p>
          <p className="mt-1 text-[22px] font-bold text-[var(--eduma-text-primary)]">
            {stats.studyMinutes}m
          </p>
        </div>
      </div>

      <form
        onSubmit={handleSaveProfile}
        className="eduma-card-surface space-y-4 rounded-[22px] p-5"
      >
        <div className="flex items-center justify-between gap-2">
          <h2 className="type-title-md text-[var(--eduma-text-primary)]">
            About you
          </h2>
          {user?.username ? (
            <span className="rounded-full bg-[var(--eduma-card)] px-3 py-1 text-[12px] font-bold text-[var(--eduma-text-secondary)]">
              @{user.username}
            </span>
          ) : null}
        </div>

        <label className="block space-y-1.5">
          <span className="text-[12.5px] font-semibold text-[var(--eduma-text-secondary)]">
            Display name
          </span>
          <input
            ref={nameInputRef}
            type="text"
            value={nameDraft}
            onChange={(e) => setNameDraft(e.target.value)}
            placeholder="Your full name"
            className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)] px-3.5 py-2.5 text-[14.5px] font-medium text-[var(--eduma-text-primary)] focus:border-[var(--eduma-primary)] focus:outline-none"
          />
        </label>

        <label className="block space-y-1.5">
          <span className="text-[12.5px] font-semibold text-[var(--eduma-text-secondary)]">
            Bio
          </span>
          <textarea
            rows={3}
            value={bioDraft}
            onChange={(e) => setBioDraft(e.target.value)}
            placeholder="Tell classmates what you're studying…"
            className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)] px-3.5 py-2.5 text-[14.5px] font-medium text-[var(--eduma-text-primary)] focus:border-[var(--eduma-primary)] focus:outline-none"
          />
        </label>

        <label className="block space-y-1.5">
          <span className="text-[12.5px] font-semibold text-[var(--eduma-text-secondary)]">
            Study goal
          </span>
          <input
            type="text"
            value={goalDraft}
            onChange={(e) => setGoalDraft(e.target.value)}
            placeholder="e.g. Ace organic chemistry midterm"
            className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)] px-3.5 py-2.5 text-[14.5px] font-medium text-[var(--eduma-text-primary)] focus:border-[var(--eduma-primary)] focus:outline-none"
          />
        </label>

        <div className="flex justify-end">
          <AppButton type="submit" loading={savingProfile}>
            Save changes
          </AppButton>
        </div>
      </form>

      {user?.referralCode || user?.username ? (
        <div className="eduma-card-surface flex flex-wrap items-center justify-between gap-3 rounded-[22px] p-5">
          <div>
            <h3 className="type-title-sm text-[var(--eduma-text-primary)]">
              Referral code
            </h3>
            <p className="type-body-sm mt-0.5 text-[var(--eduma-text-muted)]">
              Invite classmates with your code:{' '}
              <span className="font-mono font-bold text-[var(--eduma-primary)]">
                {user.referralCode || user.username}
              </span>
            </p>
          </div>
          <AppButton
            variant="secondary"
            size="sm"
            onClick={async () => {
              const code = user.referralCode || user.username || '';
              if (!code) return;
              await navigator.clipboard?.writeText(code);
              showToast('Referral code copied.', 'success');
            }}
          >
            Copy code
          </AppButton>
        </div>
      ) : null}

      <div className="eduma-card-surface flex flex-wrap items-center justify-between gap-3 rounded-[22px] p-5">
        <div>
          <h3 className="type-title-sm text-[var(--eduma-text-primary)]">
            Email verification
          </h3>
          <p className="type-body-sm mt-0.5 text-[var(--eduma-text-muted)]">
            {user?.isEmailVerified || user?.emailVerified
              ? `${user.email} is verified.`
              : `Verify ${user?.email || 'your email'} to keep full workspace access.`}
          </p>
        </div>
        {!(user?.isEmailVerified || user?.emailVerified) ? (
          <Link to="/verify-email">
            <AppButton size="sm">Verify email</AppButton>
          </Link>
        ) : (
          <span className="rounded-full bg-[var(--eduma-success)]/15 px-3 py-1 text-[12px] font-bold text-[var(--eduma-success)]">
            Verified
          </span>
        )}
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-[var(--eduma-bg)] pb-14">
      <input
        ref={avatarInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handleAvatarChange}
      />
      {!isExpanded ? <PureAppBar title="Profile & Settings" backTo="/main" /> : null}

      {isExpanded ? (
        <DesktopSplitScaffold
          minBodyWidth={460}
          hero={
            <ProfileDesktopHero
              user={user}
              stats={stats}
              onBack={() => navigate('/main')}
              onRefresh={() => {
                void refreshProfile();
                void loadStats();
              }}
              onEditProfile={() => {
                setDesktopTab('profile');
                window.setTimeout(() => nameInputRef.current?.focus(), 60);
              }}
              onPickPhoto={() => avatarInputRef.current?.click()}
              onLogout={async () => {
                await logout();
                navigate('/sign-in', { replace: true });
              }}
            />
          }
          body={
            <ProfileDesktopPanel
              desktopTab={desktopTab}
              onTabChange={setDesktopTab}
              settingsQuery={settingsQuery}
              onSettingsQueryChange={setSettingsQuery}
              profileContent={profileTabContent}
              settingsContent={mainSettings}
            />
          }
        />
      ) : (
        <div className="mx-auto max-w-2xl px-4 pt-5">
          <div className="eduma-card-surface mb-5 flex items-center gap-4 rounded-[22px] p-4">
            <button
              type="button"
              onClick={() => avatarInputRef.current?.click()}
              className="relative shrink-0 cursor-pointer"
              title="Change photo"
            >
              <UserAvatar
                person={{
                  id: user?.id,
                  name: user?.name,
                  avatarUrl: user?.avatarUrl,
                }}
                size={60}
              />
            </button>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5">
                <h2 className="type-title-lg truncate">{user?.name || 'Student'}</h2>
                {user?.hasVerifiedBadge ? <VerifiedBadge /> : null}
              </div>
              <p className="type-body-sm truncate text-[var(--eduma-text-muted)]">
                {user?.username ? `@${user.username} · ` : ''}
                {user?.email}
              </p>
            </div>
            <AppButton variant="secondary" size="sm" onClick={() => setEditOpen(true)}>
              Edit
            </AppButton>
          </div>
          {mainSettings}
        </div>
      )}

      {/* Edit Profile Modal */}
      <AppModalDialog
        open={editOpen}
        onClose={() => setEditOpen(false)}
        title="Edit profile"
      >
        <form onSubmit={handleSaveProfile} className="flex flex-col gap-4">
          <AppTextFormField
            label="Full name"
            autoComplete="name"
            required
            value={nameDraft}
            onChange={(e) => setNameDraft(e.target.value)}
          />
          <AppTextFormField
            label="Study goal"
            placeholder="e.g. Ace Organic Chemistry finals"
            value={goalDraft}
            onChange={(e) => setGoalDraft(e.target.value)}
          />
          <div className="flex flex-col gap-1.5">
            <label
              htmlFor="profile-bio"
              className="type-label-md text-[var(--eduma-text-secondary)]"
            >
              Bio
            </label>
            <textarea
              id="profile-bio"
              rows={3}
              value={bioDraft}
              onChange={(e) => setBioDraft(e.target.value)}
              className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] px-3.5 py-2.5 text-[14px]"
            />
          </div>
          <div className="flex justify-end gap-2">
            <AppButton variant="ghost" onClick={() => setEditOpen(false)}>
              Cancel
            </AppButton>
            <AppButton type="submit" loading={savingProfile}>
              Save profile
            </AppButton>
          </div>
        </form>
      </AppModalDialog>

      {/* What Eduma Remembers Modal */}
      <AppModalDialog
        open={memoryOpen}
        onClose={() => setMemoryOpen(false)}
        title="What Eduma remembers"
        subtitle="Facts personalized from your study sessions"
      >
        {memories.length === 0 ? (
          <p className="type-body-md text-[var(--eduma-text-muted)]">
            No saved learning memories yet.
          </p>
        ) : (
          <ul className="space-y-2">
            {memories.map((m) => (
              <li
                key={m.id}
                className="rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-bg)]/60 p-3 text-[13.5px]"
              >
                {m.text}
              </li>
            ))}
          </ul>
        )}
      </AppModalDialog>

      {/* Help & Feedback Modal */}
      <AppModalDialog
        open={feedbackOpen}
        onClose={() => setFeedbackOpen(false)}
        title="Help & Support"
      >
        <form onSubmit={handleSendFeedback} className="flex flex-col gap-4">
          <textarea
            rows={4}
            required
            placeholder="Describe an issue or feature idea…"
            value={feedbackText}
            onChange={(e) => setFeedbackText(e.target.value)}
            className="w-full rounded-[14px] border border-[var(--eduma-border)] bg-[var(--eduma-surface)] p-3.5 text-[14.5px]"
          />
          <div className="flex justify-end gap-2">
            <AppButton variant="ghost" onClick={() => setFeedbackOpen(false)}>
              Cancel
            </AppButton>
            <AppButton type="submit" disabled={!feedbackText.trim()}>
              Send feedback
            </AppButton>
          </div>
        </form>
      </AppModalDialog>
    </div>
  );
}
