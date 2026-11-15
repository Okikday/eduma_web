import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/theme_controller.dart';
import '../../../auth/logic/auth_actions.dart';
import '../../../main/data/main_preferences.dart';
import '../../../main/data/main_space.dart';
import '../../../main/logic/main_actions.dart';
import '../../../main/presentation/widgets/app_tab_shell.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../logic/profile_actions.dart';
import '../widgets/profile_account_dialogs.dart';
import '../widgets/profile_edit_dialog.dart';
import '../widgets/profile_hero_widgets.dart';
import '../widgets/profile_password_dialog.dart';
import '../widgets/profile_settings_groups.dart';

/// User Profile & Settings screen (`/profile`), matching `ProfileDesktopView`
/// on wide screens (`>= 1024px`) and `ProfileView` on narrower viewports.
class ProfilePage extends StatefulComponent {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  EdumaSession? _session = AuthActions.currentSession;
  bool _loadingSession = AuthActions.currentSession == null;
  bool _refreshing = false;
  String? _sessionError;

  ProfileStats _stats = const ProfileStats();
  MainUserPreferences _prefs = const MainUserPreferences();
  ProfileTabSection _activeTab = .profile;
  bool _searching = false;
  String _searchQuery = '';
  bool _verifyDismissed = false;

  // Interactive preferences mirrored from user session + local app toggles.
  bool _allowSpaceAdds = true;
  bool _showPresence = true;
  bool _personalization = true;
  String _aiAccess = 'ask';
  bool _autoZoom = true;
  bool _elementSheet = true;
  bool _checklistProgress = true;
  bool _autoApproveAi = false;
  String _themeMode = EdumaThemeController.currentModeLabel();

  bool _editOpen = false;
  bool _aboutYouOpen = false;
  bool _passwordOpen = false;
  bool _deleteAccountOpen = false;
  bool _signingOut = false;
  String? _notice;
  bool _noticeIsError = false;

  @override
  void initState() {
    super.initState();
    final session = _session;
    if (session != null) {
      EdumaMemoryCache.instance.ensureUser(session.userId);
      _syncPrivacyFromUser(session.user);
      _stats = EdumaMemoryCache.instance.profileStats ?? const ProfileStats();
    }
    unawaited(_load());
  }

  Future<void> _load({bool manualRefresh = false}) async {
    setState(() {
      _loadingSession = _session == null;
      _refreshing = manualRefresh;
      _sessionError = null;
    });

    try {
      final session = await AuthActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() => _session = null);
        return;
      }
      EdumaMemoryCache.instance.ensureUser(session.userId);
      _syncPrivacyFromUser(session.user);
      setState(() => _session = session);
      final results = await Future.wait<Object?>([
        ProfileActions.loadStats(),
        MainActions.loadPreferences(),
        ProfileActions.refreshMe().catchError((_) => null),
      ]);
      if (!mounted) return;
      final freshUser = results[2] as Map<String, dynamic>?;
      final stats = results[0] as ProfileStats;
      EdumaMemoryCache.instance.profileStats = stats;
      setState(() {
        _stats = stats;
        _prefs = results[1] as MainUserPreferences;
        if (freshUser != null) {
          _session = EdumaSession(
            user: freshUser,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
          _syncPrivacyFromUser(freshUser);
        }
        if (manualRefresh) {
          _notice = 'Profile refreshed.';
          _noticeIsError = false;
        }
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _sessionError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sessionError = 'Could not load your profile right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _refreshing = false;
        });
      }
    }
  }

  void _syncPrivacyFromUser(Map<String, dynamic> user) {
    final prefsMap = user['preferences'] is Map ? user['preferences'] as Map : const {};
    _allowSpaceAdds = (user['allowSpaceAdds'] ?? prefsMap['allowSpaceAdds']) as bool? ?? true;
    _showPresence =
        (user['showPresence'] ?? user['isPresenceShown'] ?? prefsMap['showPresence']) as bool? ?? true;
    _personalization =
        (user['personalizationEnabled'] ?? user['isPersonalizationEnabled']) as bool? ?? true;
    final rawAccess = '${user['aiPersonalityAccess'] ?? 'ask'}'.trim().toLowerCase();
    _aiAccess = (rawAccess == 'auto' || rawAccess == 'denied') ? rawAccess : 'ask';
  }

  void _showNotice(String message, {bool isError = false}) {
    setState(() {
      _notice = message;
      _noticeIsError = isError;
    });
  }

  Future<void> _setGridView(bool grid) async {
    setState(() => _prefs = MainUserPreferences(spaceGridView: grid, spaceSort: _prefs.spaceSort));
    await MainActions.saveSpaceGridView(grid);
  }

  Future<void> _cycleSort() async {
    const order = [MainSpaceSort.recent, MainSpaceSort.accessed, MainSpaceSort.name, MainSpaceSort.date];
    final next = order[(order.indexOf(_prefs.spaceSort) + 1) % order.length];
    setState(() => _prefs = MainUserPreferences(spaceGridView: _prefs.spaceGridView, spaceSort: next));
    await MainActions.saveSpaceSort(next);
  }

  Future<void> _updatePrivacy({
    bool? allowSpaceAdds,
    bool? showPresence,
    bool? personalization,
    String? aiAccess,
  }) async {
    final prevAllow = _allowSpaceAdds;
    final prevPresence = _showPresence;
    final prevPers = _personalization;
    final prevAi = _aiAccess;
    setState(() {
      if (allowSpaceAdds != null) _allowSpaceAdds = allowSpaceAdds;
      if (showPresence != null) _showPresence = showPresence;
      if (personalization != null) _personalization = personalization;
      if (aiAccess != null) _aiAccess = aiAccess;
    });
    try {
      await ProfileActions.updatePrivacyPreferences(
        allowSpaceAdds: allowSpaceAdds,
        showPresence: showPresence,
        personalizationEnabled: personalization,
        aiPersonalityAccess: aiAccess,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allowSpaceAdds = prevAllow;
        _showPresence = prevPresence;
        _personalization = prevPers;
        _aiAccess = prevAi;
      });
      _showNotice('Could not update privacy preference.', isError: true);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await AuthActions.signOut();
    if (!mounted) return;
    setState(() {
      _session = null;
      _signingOut = false;
    });
  }

  Future<void> _signOutAllDevices() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await ProfileActions.signOutAllDevices();
    if (!mounted) return;
    setState(() {
      _session = null;
      _signingOut = false;
    });
  }

  List<ProfileSettingsGroupData> _buildGroups(String email) {
    final user = _session?.user ?? const {};
    final rawLevel = '${user['level'] ?? ''}'.trim();
    final levelMatch = RegExp(r'^[lL](\d+)$').firstMatch(rawLevel);
    final levelText = levelMatch != null ? '${levelMatch.group(1)} level' : rawLevel;
    final fieldText = '${user['fieldOfStudy'] ?? user['department'] ?? ''}'.trim();
    final inst = user['institution'];
    final instText = inst is Map
        ? '${inst['name'] ?? inst['shortName'] ?? ''}'.trim()
        : '${inst ?? user['school'] ?? ''}'.trim();
    final aboutParts = [
      if (levelText.isNotEmpty) levelText,
      if (fieldText.isNotEmpty) fieldText,
      if (instText.isNotEmpty) instText,
    ];
    final model = ProfileSettingsViewModel(
      email: email,
      aboutYou: aboutParts.join(' · '),
      spaceGridView: _prefs.spaceGridView,
      spaceSort: _prefs.spaceSort,
      allowSpaceAdds: _allowSpaceAdds,
      showPresence: _showPresence,
      personalization: _personalization,
      aiAccess: _aiAccess,
      autoZoom: _autoZoom,
      elementSheet: _elementSheet,
      checklistProgress: _checklistProgress,
      autoApproveAi: _autoApproveAi,
      themeMode: _themeMode,
      signingOut: _signingOut,
    );
    final actions = ProfileSettingsActions(
      onEditProfile: () => setState(() => _editOpen = true),
      onEditAboutYou: () => setState(() => _aboutYouOpen = true),
      onChangePassword: () => setState(() => _passwordOpen = true),
      onSignOut: () => unawaited(_signOut()),
      onSignOutAll: () => unawaited(_signOutAllDevices()),
      onDeleteAccount: () => setState(() => _deleteAccountOpen = true),
      onToggleGridView: (val) => unawaited(_setGridView(val)),
      onCycleSort: () => unawaited(_cycleSort()),
      onToggleAllowSpaceAdds: (val) => unawaited(_updatePrivacy(allowSpaceAdds: val)),
      onToggleShowPresence: (val) => unawaited(_updatePrivacy(showPresence: val)),
      onTogglePersonalization: (val) => unawaited(_updatePrivacy(personalization: val)),
      onCycleAiAccess: () {
        const order = ['ask', 'auto', 'denied'];
        final next = order[(order.indexOf(_aiAccess) + 1) % order.length];
        unawaited(_updatePrivacy(aiAccess: next));
      },
      onCycleThemeMode: () {
        final next = EdumaThemeController.cycleMode(_themeMode);
        EdumaThemeController.applyMode(next);
        setState(() => _themeMode = next);
        _showNotice('Theme switched to $next.');
      },
      onToggleAutoZoom: (val) => setState(() => _autoZoom = val),
      onToggleElementSheet: (val) => setState(() => _elementSheet = val),
      onToggleChecklistProgress: (val) => setState(() => _checklistProgress = val),
      onToggleAutoApproveAi: (val) => setState(() => _autoApproveAi = val),
      onShowNotice: (msg) => _showNotice(msg),
    );
    return buildProfileSettingsGroups(model: model, actions: actions);
  }

  List<Component> _panelGroupsContent({
    required String email,
    required bool isVerified,
    required List<ProfileSettingsGroupData> allGroups,
  }) {
    final showSearchResults = _searching && _searchQuery.trim().isNotEmpty;
    if (showSearchResults) {
      final matched = filterProfileSettingsGroups(allGroups, _searchQuery);
      if (matched.isEmpty) {
        return [
          div(classes: 'eduma-profile__empty-search', [
            edumaIcon(EdumaIcons.search, size: 28),
            strong([.text('No matching settings')]),
            p([.text('Try searching for theme, privacy, WhatsApp, or AI.')]),
          ]),
        ];
      }
      return [for (final group in matched) profileSettingsGroupSection(group)];
    }
    final tabGroups = allGroups.where((group) => group.tab == _activeTab);
    return [
      if (_activeTab == .profile && !isVerified && !_verifyDismissed)
        profileVerificationBanner(
          email: email,
          onDismiss: () => setState(() => _verifyDismissed = true),
        ),
      for (final group in tabGroups) profileSettingsGroupSection(group),
    ];
  }

  @override
  Component build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return adaptivePageScaffold(
        title: 'Profile & Settings',
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

    final user = session.user;
    final email = '${user['email'] ?? ''}'.trim();
    final username = '${user['username'] ?? ''}'.trim();
    final isVerified = user['isEmailVerified'] == true;
    final allGroups = _buildGroups(email);
    final groupsContent = _panelGroupsContent(
      email: email,
      isVerified: isVerified,
      allGroups: allGroups,
    );
    final tabBar = profileTabBar(
      activeTab: _activeTab,
      searching: _searching,
      searchQuery: _searchQuery,
      onSelectTab: (tab) => setState(() => _activeTab = tab),
      onStartSearch: () => setState(() => _searching = true),
      onSearchInput: (val) => setState(() => _searchQuery = val),
      onStopSearch: () => setState(() {
        _searching = false;
        _searchQuery = '';
      }),
    );

    return div(classes: 'eduma-profile-root', [
      // Desktop split (`>= 1024px`)
      div(classes: 'eduma-profile__desktop-only', [
        desktopSplitScaffold(
          classes: 'eduma-profile-split',
          hero: profileDesktopHero(
            session: session,
            stats: _stats,
            refreshing: _refreshing,
            onRefresh: () => unawaited(_load(manualRefresh: true)),
            onEditProfile: () => setState(() => _editOpen = true),
            onPhotoAction: () => _showNotice('Avatar upload opens in the mobile & desktop Eduma app.'),
            onSignOut: () => unawaited(_signOut()),
          ),
          body: div(classes: 'eduma-profile-panel', [
            div(classes: 'eduma-profile-panel__sticky', [
              div(classes: 'eduma-profile-panel__inner', [
                h1(classes: 'eduma-profile-panel__title', [.text('Profile & Settings')]),
                tabBar,
              ]),
            ]),
            div(classes: 'eduma-profile-panel__scroll', [
              if (_notice case final msg?)
                div(classes: 'eduma-profile-panel__notice', [mainHomeNotice(msg, isError: _noticeIsError)]),
              ...groupsContent,
            ]),
          ]),
        ),
      ]),
      // Mobile adaptive view (`< 1024px`)
      div(classes: 'eduma-profile__mobile-only', [
        pureAppBar(
          title: 'Profile & Settings',
          fallbackHref: '/home',
          trailing: button(
            classes: _refreshing
                ? 'eduma-profile__refresh-btn is-spinning'
                : 'eduma-profile__refresh-btn',
            type: ButtonType.button,
            disabled: _refreshing,
            attributes: {'aria-label': 'Refresh profile', 'title': 'Refresh profile'},
            onClick: () => unawaited(_load(manualRefresh: true)),
            [edumaIcon(EdumaIcons.refresh, size: 20)],
          ),
        ),
        div(classes: 'eduma-profile-mobile__sticky-tabs', [tabBar]),
        div(classes: 'eduma-profile-mobile__body', [
          if (_notice case final msg?) mainHomeNotice(msg, isError: _noticeIsError),
          if (!(_searching && _searchQuery.trim().isNotEmpty) && _activeTab == .profile) ...[
            profileMobileHeaderCard(
              session: session,
              onEditProfile: () => setState(() => _editOpen = true),
              onPhotoAction: () => _showNotice('Avatar upload opens in the mobile & desktop Eduma app.'),
            ),
            profileStatsRow(_stats),
          ],
          ...groupsContent,
        ]),
      ]),
      ProfileEditDialog(
        open: _editOpen,
        currentName: session.name,
        currentUsername: username,
        onClose: () => setState(() => _editOpen = false),
        onSaved: (updated) => setState(() {
          _session = EdumaSession(
            user: updated,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
          _syncPrivacyFromUser(updated);
          _notice = 'Profile updated.';
          _noticeIsError = false;
        }),
      ),
      ProfilePasswordDialog(
        open: _passwordOpen,
        email: email,
        onClose: () => setState(() => _passwordOpen = false),
        onChanged: (freshSession) => setState(() {
          _session = freshSession;
          _notice = 'Password updated and session refreshed.';
          _noticeIsError = false;
        }),
      ),
      ProfileAboutYouDialog(
        open: _aboutYouOpen,
        user: session.user,
        onClose: () => setState(() => _aboutYouOpen = false),
        onSaved: (updated) => setState(() {
          _session = EdumaSession(
            user: updated,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
          _notice = 'Academic profile updated.';
          _noticeIsError = false;
        }),
      ),
      ProfileDeleteAccountDialog(
        open: _deleteAccountOpen,
        onClose: () => setState(() => _deleteAccountOpen = false),
        onDeleted: () => setState(() => _session = null),
      ),
    ]);
  }
}
