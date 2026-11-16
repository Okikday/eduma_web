import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../auth/data/auth_api.dart';
import '../../../main/presentation/widgets/main_home_helpers.dart';
import '../../logic/profile_actions.dart';
import 'profile_settings_groups.dart';

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String? _formatMemberSince(Object? raw) {
  final parsed = raw is DateTime ? raw : DateTime.tryParse('${raw ?? ''}');
  if (parsed == null || parsed.year <= 1970) return null;
  return 'Member since ${_shortMonths[parsed.month - 1]} ${parsed.year}';
}

Object _roleIcon(String role) => switch (role.toLowerCase()) {
  'admin' => EdumaIcons.crown,
  'tutor' => EdumaIcons.teacher,
  _ => EdumaIcons.book1,
};

/// Full-bleed left pane for `desktopSplitScaffold` matching `ProfileDesktopHero`.
Component profileDesktopHero({
  required EdumaSession session,
  required ProfileStats stats,
  required VoidCallback onEditProfile,
  required VoidCallback onPhotoAction,
  required VoidCallback onSignOut,
}) {
  final user = session.user;
  final displayName = session.name.trim().isEmpty ? 'Eduma Learner' : session.name.trim();
  final initials = mainHomeInitials(displayName);
  final avatarUrl = mainHomeSafeImageUrl(user['avatarUrl'] ?? user['profilePic']);
  final username = '${user['username'] ?? ''}'.trim();
  final email = '${user['email'] ?? ''}'.trim();
  final role = session.role.trim();
  final isVerified = user['isEmailVerified'] == true;
  final memberSince = _formatMemberSince(user['createdAt']);
  final handleLine = [
    if (username.isNotEmpty) '@$username',
    if (email.isNotEmpty) email,
  ].join('  ·  ');

  return desktopHeroPane(
    backdrop: _heroBackdrop(initials: initials, avatarUrl: avatarUrl),
    leading: desktopHeroBackButton(fallbackHref: '/home'),
    trailing: div(classes: 'eduma-profile__hero-corner', [
      desktopHeroButton(
        icon: EdumaIcons.camera,
        label: 'Change photo',
        onPressed: onPhotoAction,
      ),
    ]),
    bottomContent: [
      div(classes: 'eduma-profile__hero-details', [
        div(classes: 'eduma-profile__fact-chips', [
          if (role.isNotEmpty)
            _factChip(
              icon: _roleIcon(role),
              label: '${role[0].toUpperCase()}${role.substring(1)}',
            ),
          if (isVerified) _factChip(icon: EdumaIcons.verify, label: 'Verified'),
          if (memberSince != null) _factChip(icon: EdumaIcons.calendarTick, label: memberSince),
        ]),
        div(classes: 'eduma-profile__hero-name-row', [
          h2(classes: 'eduma-profile__hero-name', [.text(displayName)]),
          if (isVerified)
            span(classes: 'eduma-profile__verified-gold', [
              edumaIcon(EdumaIcons.verify, size: 22),
            ]),
        ]),
        if (handleLine.isNotEmpty) p(classes: 'eduma-profile__hero-handle', [.text(handleLine)]),
        profileStatsRow(stats, frosted: true),
        div(classes: 'eduma-profile__hero-actions', [
          desktopPillButton(
            icon: EdumaIcons.edit,
            label: 'Edit profile',
            variant: .light,
            onPressed: onEditProfile,
          ),
          if (!isVerified)
            desktopPillButton(
              icon: EdumaIcons.key,
              label: 'Verify email',
              variant: .glass,
              href: '/verify-email',
            )
          else
            desktopPillButton(
              icon: EdumaIcons.camera,
              label: 'Change photo',
              variant: .glass,
              onPressed: onPhotoAction,
            ),
          desktopPillButton(
            icon: EdumaIcons.logout,
            label: 'Log out',
            variant: .glass,
            onPressed: onSignOut,
          ),
        ]),
      ]),
    ],
  );
}

Component _heroBackdrop({required String initials, String? avatarUrl}) => div(
  classes: 'eduma-profile__backdrop',
  [
    div(classes: 'eduma-profile__monogram-bg', [
      span(classes: 'eduma-profile__glow-tr', attributes: {'aria-hidden': 'true'}, []),
      span(classes: 'eduma-profile__glow-bl', attributes: {'aria-hidden': 'true'}, []),
      div(classes: 'eduma-profile__monogram-ring', [
        span([.text(initials.isEmpty ? '?' : initials)]),
      ]),
    ]),
    if (avatarUrl != null) img(src: avatarUrl, alt: 'Profile photo', classes: 'eduma-profile__photo-img'),
  ],
);

Component _factChip({required Object icon, required String label}) => span(
  classes: 'eduma-profile__fact-chip',
  [
    edumaIcon(icon, size: 14),
    span([.text(label)]),
  ],
);

/// Mobile top profile identity row matching `ProfileHeaderCard`.
Component profileMobileHeaderCard({
  required EdumaSession session,
  required VoidCallback onEditProfile,
  required VoidCallback onPhotoAction,
}) {
  final user = session.user;
  final displayName = session.name.trim().isEmpty ? 'Eduma Learner' : session.name.trim();
  final initials = mainHomeInitials(displayName);
  final avatarUrl = mainHomeSafeImageUrl(user['avatarUrl'] ?? user['profilePic']);
  final username = '${user['username'] ?? ''}'.trim();
  final role = session.role.trim().toUpperCase();
  final isVerified = user['isEmailVerified'] == true;

  return div(classes: 'eduma-profile__mobile-card', [
    button(
      classes: 'eduma-profile__mobile-avatar-btn',
      type: ButtonType.button,
      attributes: {'aria-label': 'Change photo'},
      onClick: onPhotoAction,
      [
        span(classes: 'eduma-profile__mobile-avatar', [
          if (avatarUrl != null) img(src: avatarUrl, alt: displayName) else .text(initials.isEmpty ? '?' : initials),
        ]),
        span(
          classes: 'eduma-profile__camera-badge',
          attributes: {'aria-hidden': 'true'},
          [
            edumaIcon(EdumaIcons.camera, size: 14),
          ],
        ),
      ],
    ),
    div(classes: 'eduma-profile__mobile-meta', [
      div(classes: 'eduma-profile__name-row', [
        h2([.text(displayName)]),
        if (isVerified)
          span(classes: 'eduma-profile__verified-gold', [
            edumaIcon(EdumaIcons.verify, size: 18),
          ]),
        button(
          classes: 'eduma-profile__inline-edit',
          type: ButtonType.button,
          attributes: {'aria-label': 'Edit profile'},
          onClick: onEditProfile,
          [edumaIcon(EdumaIcons.edit, size: 16)],
        ),
      ]),
      if (username.isNotEmpty) p(classes: 'eduma-profile__handle', [.text('@$username')]),
      if (role.isNotEmpty) span(classes: 'eduma-profile__role-pill', [.text(role)]),
    ]),
  ]);
}

/// Notebooks · Time studied · Spaces capsule (`frosted` in hero, colored on mobile).
Component profileStatsRow(ProfileStats stats, {bool frosted = false}) => section(
  classes: frosted ? 'eduma-profile__stats is-frosted' : 'eduma-profile__stats is-colored',
  [
    if (stats.notebooks > 0) ...[
      _statTile('Notebooks', '${stats.notebooks}'),
      span(classes: 'eduma-profile__stat-divider', attributes: {'aria-hidden': 'true'}, []),
    ],
    _statTile('Time studied', stats.formattedStudyTime),
    span(classes: 'eduma-profile__stat-divider', attributes: {'aria-hidden': 'true'}, []),
    _statTile('Spaces', '${stats.spaces}'),
  ],
);

Component _statTile(String labelText, String value) => article(
  classes: 'eduma-profile__stat-card',
  [
    strong([.text(value)]),
    span(classes: 'eduma-profile__stat-label', [.text(labelText)]),
  ],
);

/// Profile | Settings segmented capsule + morphing 46x46 search toggle.
Component profileTabBar({
  required ProfileTabSection activeTab,
  required bool searching,
  required String searchQuery,
  required ValueChanged<ProfileTabSection> onSelectTab,
  required VoidCallback onStartSearch,
  required ValueChanged<String> onSearchInput,
  required VoidCallback onStopSearch,
}) {
  if (searching) {
    return div(classes: 'eduma-profile__tabbar', [
      div(classes: 'eduma-profile__search-pill', [
        edumaIcon(EdumaIcons.search, size: 18),
        input(
          classes: 'eduma-profile__search-input',
          type: InputType.search,
          value: searchQuery,
          attributes: {'placeholder': 'Search settings, labs, theme…', 'autofocus': 'true'},
          onInput: onSearchInput,
        ),
        button(
          classes: 'eduma-profile__search-close',
          type: ButtonType.button,
          attributes: {'aria-label': 'Close search'},
          onClick: onStopSearch,
          [edumaIcon(EdumaIcons.closePlain, size: 16)],
        ),
      ]),
    ]);
  }

  return div(classes: 'eduma-profile__tabbar', [
    div(
      classes: 'eduma-profile__segmented',
      attributes: {'role': 'tablist'},
      [
        for (final tab in ProfileTabSection.values)
          button(
            classes: tab == activeTab ? 'eduma-profile__seg-btn is-active' : 'eduma-profile__seg-btn',
            type: ButtonType.button,
            attributes: {'role': 'tab', 'aria-selected': '${tab == activeTab}'},
            onClick: () => onSelectTab(tab),
            [.text(tab.label)],
          ),
      ],
    ),
    button(
      classes: 'eduma-profile__search-toggle',
      type: ButtonType.button,
      attributes: {'aria-label': 'Search settings', 'title': 'Search settings'},
      onClick: onStartSearch,
      [edumaIcon(EdumaIcons.search, size: 20)],
    ),
  ]);
}

/// Calm "Verify your email" prompt banner matching `EmailVerificationBanner`.
Component profileVerificationBanner({
  required String email,
  required VoidCallback onDismiss,
}) => aside(classes: 'eduma-profile__verify-banner', [
  span(classes: 'eduma-profile__verify-icon', [
    edumaIcon(EdumaIcons.smsTracking, size: 20),
  ]),
  div(classes: 'eduma-profile__verify-copy', [
    strong([.text('Verify your email')]),
    p([
      .text(
        email.isEmpty
            ? 'Enter the 6-digit code we emailed you to confirm your email address.'
            : 'We sent a 6-digit code to $email. Enter it to confirm your email address.',
      ),
    ]),
    div(classes: 'eduma-profile__verify-actions', [
      edumaLink(
        to: '/verify-email',
        classes: 'eduma-profile__verify-cta',
        children: [edumaIcon(EdumaIcons.key, size: 14), .text('Enter code')],
      ),
    ]),
  ]),
  button(
    classes: 'eduma-profile__verify-dismiss',
    type: ButtonType.button,
    attributes: {'aria-label': 'Not now', 'title': 'Not now'},
    onClick: onDismiss,
    [edumaIcon(EdumaIcons.closeCircle, size: 18)],
  ),
]);
