import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../main/data/main_space.dart';
import '../../../main/presentation/widgets/main_home_helpers.dart';

/// Top-level tabs on Profile & Settings.
enum ProfileTabSection {
  profile('Profile'),
  settings('Settings');

  const ProfileTabSection(this.label);

  final String label;
}

/// Interactive setting states shown across the 9 grouped sections.
class ProfileSettingsViewModel {
  const ProfileSettingsViewModel({
    required this.email,
    this.aboutYou = '',
    required this.spaceGridView,
    required this.spaceSort,
    required this.allowSpaceAdds,
    required this.showPresence,
    required this.personalization,
    required this.aiAccess,
    required this.autoZoom,
    required this.elementSheet,
    required this.checklistProgress,
    required this.autoApproveAi,
    required this.themeMode,
    required this.signingOut,
  });

  final String email;
  final String aboutYou;
  final bool spaceGridView;
  final MainSpaceSort spaceSort;
  final bool allowSpaceAdds;
  final bool showPresence;
  final bool personalization;
  final String aiAccess;
  final bool autoZoom;
  final bool elementSheet;
  final bool checklistProgress;
  final bool autoApproveAi;
  final String themeMode;
  final bool signingOut;
}

/// Action handlers wired from [ProfilePage] into [ProfileSettingsGroupData].
class ProfileSettingsActions {
  const ProfileSettingsActions({
    required this.onEditProfile,
    required this.onEditAboutYou,
    required this.onChangePassword,
    required this.onSignOut,
    required this.onSignOutAll,
    required this.onDeleteAccount,
    required this.onToggleGridView,
    required this.onCycleSort,
    required this.onToggleAllowSpaceAdds,
    required this.onToggleShowPresence,
    required this.onTogglePersonalization,
    required this.onCycleAiAccess,
    required this.onCycleThemeMode,
    required this.onToggleAutoZoom,
    required this.onToggleElementSheet,
    required this.onToggleChecklistProgress,
    required this.onToggleAutoApproveAi,
    required this.onShowNotice,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onEditAboutYou;
  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;
  final VoidCallback onSignOutAll;
  final VoidCallback onDeleteAccount;
  final ValueChanged<bool> onToggleGridView;
  final VoidCallback onCycleSort;
  final ValueChanged<bool> onToggleAllowSpaceAdds;
  final ValueChanged<bool> onToggleShowPresence;
  final ValueChanged<bool> onTogglePersonalization;
  final VoidCallback onCycleAiAccess;
  final VoidCallback onCycleThemeMode;
  final ValueChanged<bool> onToggleAutoZoom;
  final ValueChanged<bool> onToggleElementSheet;
  final ValueChanged<bool> onToggleChecklistProgress;
  final ValueChanged<bool> onToggleAutoApproveAi;
  final ValueChanged<String> onShowNotice;
}

/// Single row inside an inset settings group.
class ProfileSettingsItemData {
  const ProfileSettingsItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.keywords = const [],
    this.valueLabel,
    this.mutedValueLabel,
    this.badgeLabel,
    this.badgeIcon,
    this.switchValue,
    this.onToggle,
    this.onTap,
    this.flutterPath,
    this.isDestructive = false,
  });

  final Object icon;
  final String title;
  final String? subtitle;
  final List<String> keywords;
  final String? valueLabel;
  final String? mutedValueLabel;
  final String? badgeLabel;
  final Object? badgeIcon;
  final bool? switchValue;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final String? flutterPath;
  final bool isDestructive;

  bool matches(String lowerQuery, String lowerCaption) {
    if (lowerQuery.isEmpty) return true;
    if (title.toLowerCase().contains(lowerQuery)) return true;
    if ((subtitle ?? '').toLowerCase().contains(lowerQuery)) return true;
    if (lowerCaption.contains(lowerQuery)) return true;
    return keywords.any((kw) => kw.toLowerCase().contains(lowerQuery));
  }
}

/// Captioned group of [ProfileSettingsItemData] tiles.
class ProfileSettingsGroupData {
  const ProfileSettingsGroupData({
    required this.caption,
    required this.tab,
    required this.items,
  });

  final String caption;
  final ProfileTabSection tab;
  final List<ProfileSettingsItemData> items;
}

String _aiAccessSubtitle(String value) => switch (value) {
  'auto' => 'Always allow when personalization is on',
  'denied' => 'Keep answers general; never use memory',
  _ => 'Ask before using your profile or memory',
};

/// Builds all 9 searchable groups matching `../eduma`'s Profile & Settings tabs.
List<ProfileSettingsGroupData> buildProfileSettingsGroups({
  required ProfileSettingsViewModel model,
  required ProfileSettingsActions actions,
}) {
  return [
    ProfileSettingsGroupData(
      caption: 'ACCOUNT',
      tab: .profile,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.crown,
          title: 'Plan & Billing',
          badgeLabel: 'Free',
          keywords: const ['plan', 'billing', 'pro', 'subscription', 'upgrade'],
          onTap: () => actions.onShowNotice('Manage billing and plans inside the Eduma app.'),
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.userEdit,
          title: 'Edit Personal Details',
          subtitle: model.email.isEmpty ? 'Update name and @username' : model.email,
          keywords: const ['name', 'username', 'handle', 'email', 'account'],
          onTap: actions.onEditProfile,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.teacher,
          title: 'About you',
          subtitle: model.aboutYou.isEmpty ? 'Add your school, level and goals' : model.aboutYou,
          keywords: const ['school', 'level', 'onboarding', 'goals', 'profile'],
          onTap: actions.onEditAboutYou,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.lock,
          title: 'Password & Security',
          keywords: const ['password', 'reset', 'security', '2fa'],
          onTap: actions.onChangePassword,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.securitySafe,
          title: 'Sign out of all devices',
          subtitle: 'Ends every session, including the WhatsApp bot',
          keywords: const ['devices', 'logout', 'sessions', 'whatsapp'],
          onTap: actions.onSignOutAll,
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'PRIVACY',
      tab: .profile,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.userAdd,
          title: 'Let people add me to spaces',
          subtitle: model.allowSpaceAdds
              ? 'Admins can add you directly'
              : 'Admins send you an invite to accept or decline',
          keywords: const ['invites', 'spaces', 'privacy', 'members'],
          switchValue: model.allowSpaceAdds,
          onToggle: actions.onToggleAllowSpaceAdds,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.eye,
          title: "Show when I'm active",
          subtitle: model.showPresence ? 'Others see you on pages you have open' : 'Hide your presence on open pages',
          keywords: const ['presence', 'online', 'active', 'status'],
          switchValue: model.showPresence,
          onToggle: actions.onToggleShowPresence,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.userTag,
          title: 'Personalization',
          subtitle: model.personalization ? 'Eduma may personalize your experience' : 'Personalization is turned off',
          keywords: const ['personalize', 'ai', 'memory', 'privacy'],
          switchValue: model.personalization,
          onToggle: actions.onTogglePersonalization,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.shieldTick,
          title: 'AI access to personal information',
          subtitle: _aiAccessSubtitle(model.aiAccess),
          keywords: const ['ai', 'memory', 'permission', 'privacy'],
          onTap: actions.onCycleAiAccess,
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'SESSION',
      tab: .profile,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.logout,
          title: model.signingOut ? 'Logging out…' : 'Log Out',
          keywords: const ['sign out', 'logout', 'exit'],
          isDestructive: true,
          onTap: actions.onSignOut,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.userRemove,
          title: 'Delete Account',
          keywords: const ['delete', 'remove', 'close account'],
          isDestructive: true,
          onTap: actions.onDeleteAccount,
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'APPEARANCE',
      tab: .settings,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.moon,
          title: 'Theme',
          valueLabel: model.themeMode,
          keywords: const ['dark', 'light', 'theme', 'mode', 'appearance'],
          onTap: actions.onCycleThemeMode,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.colorfilter,
          title: 'Color theme',
          valueLabel: 'Eduma',
          keywords: const ['palette', 'color', 'indigo', 'accent'],
          onTap: () => actions.onShowNotice('Using default Eduma indigo palette.'),
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.text,
          title: 'Font',
          valueLabel: 'Raleway',
          keywords: const ['font', 'typography', 'raleway'],
          onTap: () => actions.onShowNotice('Web typography uses Raleway.'),
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.note2,
          title: 'Default page style',
          valueLabel: 'Plain',
          keywords: const ['page', 'grid', 'lined', 'blank', 'paper'],
          onTap: () => actions.onShowNotice('Default canvas paper style is Plain.'),
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'EDITING & VIEWING',
      tab: .settings,
      items: [
        ProfileSettingsItemData(
          icon: model.spaceGridView ? EdumaIcons.grid : EdumaIcons.list,
          title: 'Spaces grid layout',
          subtitle: 'Show Home spaces in multi-column cards instead of list rows',
          keywords: const ['home', 'spaces', 'grid', 'list', 'view', 'layout'],
          switchValue: model.spaceGridView,
          onToggle: actions.onToggleGridView,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.sort,
          title: 'Default space order',
          subtitle: 'Sort order applied to your Home spaces',
          valueLabel: model.spaceSort.label,
          keywords: const ['sort', 'order', 'recent', 'alphabetical', 'home'],
          onTap: actions.onCycleSort,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.searchZoomIn,
          title: 'Auto-zoom while editing',
          subtitle: "Zoom the canvas onto what you're editing",
          keywords: const ['canvas', 'zoom', 'editing'],
          switchValue: model.autoZoom,
          onToggle: actions.onToggleAutoZoom,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.edit,
          title: 'Edit elements in a sheet',
          subtitle: 'Open board cards in a bottom panel',
          keywords: const ['board', 'elements', 'sheet', 'cards'],
          switchValue: model.elementSheet,
          onToggle: actions.onToggleElementSheet,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.taskSquare,
          title: 'Checklist progress',
          subtitle: 'Progress ring on pages with checklists',
          keywords: const ['checklist', 'todo', 'progress', 'ring'],
          switchValue: model.checklistProgress,
          onToggle: actions.onToggleChecklistProgress,
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'WHATSAPP',
      tab: .settings,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.whatsapp,
          title: 'WhatsApp',
          subtitle: 'Not linked · Send files to Eduma from WhatsApp',
          keywords: const ['whatsapp', 'bot', 'link', 'phone'],
          onTap: () =>
              actions.onShowNotice('Link your WhatsApp number in the mobile app to send study files directly.'),
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'AI',
      tab: .settings,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.messages2,
          title: 'AI chats',
          subtitle: 'Saved assistant conversations',
          keywords: const ['ai', 'assistant', 'chats', 'history'],
          flutterPath: '/assistantHistory',
          onTap: () => actions.onShowNotice('AI chat history opens in the full Eduma workspace.'),
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.archiveBook,
          title: 'Personal memory',
          subtitle: 'What Eduma remembers about you',
          keywords: const ['memory', 'ai', 'facts', 'context'],
          onTap: () => actions.onShowNotice('Manage personal memory facts in the Eduma app.'),
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.tickSquare,
          title: 'Auto-approve AI edits',
          subtitle: 'Apply assistant page edits immediately',
          keywords: const ['ai', 'approve', 'edits', 'assistant'],
          switchValue: model.autoApproveAi,
          onToggle: actions.onToggleAutoApproveAi,
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.microphone2,
          title: 'Transcribe voice memos automatically',
          subtitle: 'Included with paid plans',
          badgeLabel: 'Upgrade',
          badgeIcon: EdumaIcons.lock1,
          keywords: const ['voice', 'audio', 'transcribe', 'ai', 'memo'],
          onTap: () => actions.onShowNotice('Automatic voice transcription requires an upgraded Eduma plan.'),
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'ADVANCED',
      tab: .settings,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.lampCharge,
          title: 'Labs',
          subtitle: 'Experimental features and preview options',
          keywords: const ['labs', 'beta', 'experimental', 'blur', 'animations'],
          onTap: () => actions.onShowNotice('All stable web experiments are enabled.'),
        ),
      ],
    ),
    ProfileSettingsGroupData(
      caption: 'ABOUT & SUPPORT',
      tab: .settings,
      items: [
        ProfileSettingsItemData(
          icon: EdumaIcons.infoCircle,
          title: 'About Eduma',
          mutedValueLabel: 'Web',
          keywords: const ['about', 'version', 'eduma'],
          onTap: () => actions.onShowNotice('Eduma Web · Collaborative study spaces and AI learning.'),
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.messageQuestion,
          title: 'Help & Feedback',
          keywords: const ['help', 'support', 'feedback', 'contact'],
          onTap: () => actions.onShowNotice('Need assistance? Reach support at support@eduma.app.'),
        ),
        ProfileSettingsItemData(
          icon: EdumaIcons.document,
          title: 'Terms & Privacy Policy',
          keywords: const ['terms', 'privacy', 'legal', 'policy'],
          onTap: () => actions.onShowNotice('View Terms of Service and Privacy Policy at eduma.app/legal.'),
        ),
      ],
    ),
  ];
}

/// Filters all groups across tabs when the user searches settings.
List<ProfileSettingsGroupData> filterProfileSettingsGroups(
  List<ProfileSettingsGroupData> groups,
  String query,
) {
  final lower = query.trim().toLowerCase();
  if (lower.isEmpty) return groups;
  return [
    for (final group in groups)
      if (group.items.where((item) => item.matches(lower, group.caption.toLowerCase())).toList() case final matched
          when matched.isNotEmpty)
        ProfileSettingsGroupData(
          caption: group.caption,
          tab: group.tab,
          items: matched,
        ),
  ];
}

/// Renders one captioned card container with 36x36 icon circles and dividers.
Component profileSettingsGroupSection(ProfileSettingsGroupData group) {
  return section(classes: 'eduma-profile__group', [
    span(classes: 'eduma-profile__group-caption', [.text(group.caption)]),
    div(classes: 'eduma-profile__group-card', [
      for (var i = 0; i < group.items.length; i++) ...[
        if (i > 0) div(classes: 'eduma-profile__group-divider', attributes: {'aria-hidden': 'true'}, []),
        _settingsTile(group.items[i]),
      ],
    ]),
  ]);
}

Component _settingsTile(ProfileSettingsItemData item) {
  final cls = [
    'eduma-profile__tile',
    if (item.isDestructive) 'is-destructive',
  ].join(' ');
  final children = [
    span(classes: 'eduma-profile__tile-icon', [edumaIcon(item.icon, size: 18)]),
    div(classes: 'eduma-profile__tile-copy', [
      strong(classes: 'eduma-profile__tile-title', [.text(item.title)]),
      if (item.subtitle != null && item.subtitle!.isNotEmpty)
        span(classes: 'eduma-profile__tile-subtitle', [.text(item.subtitle!)]),
    ]),
    _tileTrailing(item),
  ];

  if (item.switchValue != null && item.onToggle != null) {
    final isOn = item.switchValue!;
    return button(
      classes: cls,
      type: ButtonType.button,
      attributes: {'role': 'switch', 'aria-checked': '$isOn'},
      onClick: () => item.onToggle!(!isOn),
      children,
    );
  }
  if (item.flutterPath case final path?) {
    if (path == '/assistantHistory') {
      return edumaLink(to: path, classes: cls, children: children);
    }
    final handoffHref = mainHomeFlutterPath(path);
    if (handoffHref != null) {
      return a(href: handoffHref, classes: cls, children);
    }
  }
  return button(
    classes: cls,
    type: ButtonType.button,
    onClick: item.onTap,
    children,
  );
}

Component _tileTrailing(ProfileSettingsItemData item) {
  if (item.switchValue != null) {
    return span(
      classes: item.switchValue! ? 'eduma-profile__switch is-on' : 'eduma-profile__switch',
      attributes: {'aria-hidden': 'true'},
      [span(classes: 'eduma-profile__switch-thumb', [])],
    );
  }
  if (item.badgeLabel != null) {
    return span(classes: 'eduma-profile__tile-trailing', [
      span(classes: 'eduma-profile__tile-badge', [
        if (item.badgeIcon != null) edumaIcon(item.badgeIcon!, size: 12),
        .text(item.badgeLabel!),
      ]),
    ]);
  }
  if (item.valueLabel != null) {
    return span(classes: 'eduma-profile__tile-trailing', [
      span(classes: 'eduma-profile__tile-value', [.text(item.valueLabel!)]),
      edumaIcon(EdumaIcons.chevronRight, size: 16),
    ]);
  }
  if (item.mutedValueLabel != null) {
    return span(classes: 'eduma-profile__tile-trailing', [
      span(classes: 'eduma-profile__tile-value is-muted', [.text(item.mutedValueLabel!)]),
    ]);
  }
  return span(
    classes: 'eduma-profile__tile-chevron',
    [edumaIcon(EdumaIcons.chevronRight, size: 18)],
  );
}
