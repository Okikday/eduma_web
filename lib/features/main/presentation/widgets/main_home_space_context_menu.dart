import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_cover_fallback.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../auth/data/auth_api.dart';
import '../../../space/data/space_detail_models.dart';
import '../../../space/logic/space_detail_actions.dart';
import '../../../space/presentation/widgets/space_detail_dialogs.dart';
import '../../data/main_space.dart';
import 'main_home_helpers.dart';
import 'main_home_icons.dart';
import 'main_home_spaces_section.dart';
import 'web_dialog_helper.dart';

/// Right-click / long-press glass menu matching `SpaceTileContextMenuSheet` in `../eduma`.
class MainHomeSpaceContextMenuDialog extends StatefulComponent {
  const MainHomeSpaceContextMenuDialog({
    required this.space,
    required this.pinning,
    required this.onClose,
    required this.onTogglePin,
    required this.onSpaceRemoved,
    super.key,
  });

  final MainSpace? space;
  final bool pinning;
  final VoidCallback onClose;
  final ValueChanged<MainSpace> onTogglePin;
  final ValueChanged<MainSpace> onSpaceRemoved;

  @override
  State<MainHomeSpaceContextMenuDialog> createState() => _MainHomeSpaceContextMenuDialogState();
}

class _MainHomeSpaceContextMenuDialogState extends State<MainHomeSpaceContextMenuDialog> {
  static const _dialogId = 'main-home-space-context-dialog';

  bool _confirmRemoval = false;
  bool _deleteMedia = false;
  bool _working = false;
  bool _loadingInvite = false;
  bool _inviteCanRenew = false;
  String? _error;
  SpaceDetailData? _inviteSpace;
  MainSpace? _reportSpace;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncDialog);
  }

  @override
  void didUpdateComponent(covariant MainHomeSpaceContextMenuDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.space != component.space) {
      _confirmRemoval = false;
      _deleteMedia = component.space?.role == MainSpaceRole.owner;
      _error = null;
      Future<void>.microtask(_syncDialog);
    }
  }

  void _syncDialog() {
    if (!mounted) return;
    WebDialogHelper.syncOpen(_dialogId, component.space != null);
  }

  Future<void> _openInvite(MainSpace space) async {
    if (_loadingInvite) return;
    setState(() {
      _loadingInvite = true;
      _error = null;
    });
    try {
      final inviteSpace = await SpaceDetailActions.loadSpaceSummary(space.id);
      if (!mounted) return;
      component.onClose();
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      setState(() {
        _loadingInvite = false;
        _inviteSpace = inviteSpace;
        _inviteCanRenew = space.role != MainSpaceRole.member;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingInvite = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingInvite = false;
        _error = error.message;
      });
    }
  }

  Future<void> _openReport(MainSpace space) async {
    component.onClose();
    await Future<void>.delayed(Duration.zero);
    if (mounted) setState(() => _reportSpace = space);
  }

  Future<void> _removeSpace(MainSpace space) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final session = SpaceDetailActions.currentSession ?? await SpaceDetailActions.restoreSession();
      if (session == null) {
        throw const AuthApiException(
          message: 'Your session has expired. Please sign in again.',
          statusCode: 401,
        );
      }
      await SpaceDetailActions.leaveOrDeleteSpace(
        space.id,
        userId: session.userId,
        deleteSpace: space.role == MainSpaceRole.owner,
        deleteMedia: _deleteMedia,
      );
      if (!mounted) return;
      component.onSpaceRemoved(space);
      component.onClose();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Component build(BuildContext context) {
    final space = component.space;
    final roleLabel = switch (space?.role) {
      .owner => 'Owner',
      .admin => 'Admin',
      .member => 'Member',
      null => '',
    };
    final meta = space == null
        ? ''
        : space.isPersonal
        ? 'Personal · Only you'
        : '${mainHomeMemberLabel(space.memberCount)} · $roleLabel';
    final checklist = space?.checklist;
    final isOwner = space?.role == MainSpaceRole.owner;

    return .fragment([
      dialog(
        id: _dialogId,
        classes: 'main-home__dialog main-home__context-menu',
        attributes: {
          ...WebDialogHelper.openAttr(space != null),
          'closedby': 'any',
          'aria-labelledby': 'main-space-ctx-title',
        },
        events: {'close': (_) => component.onClose()},
        [
          if (space != null)
            div(classes: 'main-home__context-menu-card', [
              div(classes: 'main-home__context-menu-header', [
                span(classes: 'main-home__context-menu-cover', [
                  span(classes: 'main-home__space-cover-box', [
                    if (space.coverUrl case final cover?) img(src: cover, alt: '') else edumaCoverFallback(),
                  ]),
                  mainHomeRoleBadge(space.role),
                ]),
                div(classes: 'main-home__context-menu-title-wrap', [
                  h2(id: 'main-space-ctx-title', [.text(space.title)]),
                  p([.text(meta)]),
                ]),
              ]),
              if (checklist case final progress? when progress.hasItems) _contextMenuProgress(progress),
              div(classes: 'main-home__context-menu-divider', []),
              if (!_confirmRemoval) ...[
                edumaLink(
                  to: '/spaceDetail?id=${Uri.encodeComponent(space.id)}',
                  classes: 'main-home__context-menu-row',
                  onClick: () => WebDialogHelper.syncOpen(_dialogId, false),
                  children: [
                    mainHomeIcon(.settings02, size: 18),
                    span([.text('Space options')]),
                  ],
                ),
                button(
                  type: ButtonType.button,
                  classes: 'main-home__context-menu-row',
                  disabled: component.pinning,
                  onClick: () {
                    component.onTogglePin(space);
                    component.onClose();
                  },
                  [
                    mainHomeIcon(space.isPinned ? .pinOff : .pinOutline, size: 18),
                    span([
                      .text(space.isPinned ? 'Unpin space' : 'Pin space to top'),
                    ]),
                  ],
                ),
                if (space.canInvite) ...[
                  button(
                    type: ButtonType.button,
                    classes: 'main-home__context-menu-row',
                    disabled: _loadingInvite,
                    onClick: () => unawaited(_openInvite(space)),
                    [
                      mainHomeIcon(.userAdd, size: 18),
                      span([.text(_loadingInvite ? 'Getting invite link…' : 'Invite someone')]),
                    ],
                  ),
                  button(
                    type: ButtonType.button,
                    classes: 'main-home__context-menu-row',
                    disabled: _loadingInvite,
                    onClick: () => unawaited(_openInvite(space)),
                    [
                      mainHomeIcon(.link, size: 18),
                      span([.text('Share space link')]),
                    ],
                  ),
                ],
                if (!isOwner)
                  button(
                    type: ButtonType.button,
                    classes: 'main-home__context-menu-row',
                    onClick: () => unawaited(_openReport(space)),
                    [
                      mainHomeIcon(.warning, size: 18),
                      span([.text('Report space')]),
                    ],
                  ),
                if (!space.isPersonal || isOwner) ...[
                  div(classes: 'main-home__context-menu-divider', []),
                  button(
                    type: ButtonType.button,
                    classes: 'main-home__context-menu-row main-home__context-menu-row--danger',
                    onClick: () => setState(() {
                      _confirmRemoval = true;
                      _deleteMedia = isOwner;
                      _error = null;
                    }),
                    [
                      mainHomeIcon(isOwner ? .delete : .user, size: 18),
                      span([.text(isOwner ? 'Delete space' : 'Leave space')]),
                    ],
                  ),
                ],
              ] else ...[
                div(classes: 'main-home__context-menu-confirm', [
                  p([
                    .text(
                      isOwner
                          ? '“${space.title}” and its shared materials will be deleted for everyone. This cannot be undone.'
                          : 'You will lose access to “${space.title}” and its shared materials.',
                    ),
                  ]),
                  label(classes: 'main-home__context-menu-check', [
                    input<bool>(
                      type: InputType.checkbox,
                      checked: _deleteMedia,
                      disabled: _working,
                      onChange: (value) => setState(() => _deleteMedia = value),
                    ),
                    span([
                      .text(
                        isOwner
                            ? 'Also delete all files stored for this space'
                            : 'Also delete files I added to this space',
                      ),
                    ]),
                  ]),
                  if (_error case final error?)
                    p(
                      classes: 'eduma-modal__error',
                      attributes: {'role': 'alert'},
                      [.text(error)],
                    ),
                  div(classes: 'main-home__context-menu-confirm-actions', [
                    button(
                      type: ButtonType.button,
                      classes: 'eduma-modal__btn',
                      disabled: _working,
                      onClick: () => setState(() {
                        _confirmRemoval = false;
                        _error = null;
                      }),
                      [.text('Cancel')],
                    ),
                    button(
                      type: ButtonType.button,
                      classes: 'eduma-modal__btn eduma-modal__btn--danger',
                      disabled: _working,
                      onClick: () => unawaited(_removeSpace(space)),
                      [
                        .text(
                          _working
                              ? 'Working…'
                              : isOwner
                              ? 'Delete space'
                              : 'Leave space',
                        ),
                      ],
                    ),
                  ]),
                ]),
              ],
              if (!_confirmRemoval)
                if (_error case final error?)
                  p(
                    classes: 'eduma-modal__error',
                    attributes: {'role': 'alert'},
                    [.text(error)],
                  ),
            ]),
        ],
      ),
      if (_inviteSpace case final inviteSpace?)
        SpaceInviteDialog(
          open: true,
          space: inviteSpace,
          canRenew: _inviteCanRenew,
          onClose: () => setState(() => _inviteSpace = null),
          onInviteRenewed: (inviteCode, expiresAt) => setState(() {
            _inviteSpace = inviteSpace.copyWith(
              inviteCode: inviteCode,
              inviteCodeExpiresAt: expiresAt,
            );
          }),
        ),
      if (_reportSpace case final reportSpace?)
        SpaceReportDialog(
          spaceId: reportSpace.id,
          spaceTitle: reportSpace.title,
          onClose: () => setState(() => _reportSpace = null),
        ),
    ]);
  }
}

Component _contextMenuProgress(MainSpaceChecklist checklist) => div(
  classes: 'main-home__context-menu-progress',
  attributes: {
    'role': 'progressbar',
    'aria-label': 'Checklist progress',
    'aria-valuemin': '0',
    'aria-valuemax': '${checklist.total}',
    'aria-valuenow': '${checklist.done}',
    'aria-valuetext': checklist.label,
  },
  [
    div(classes: 'main-home__context-menu-progress-label', [
      span([.text('Checklist progress')]),
      strong([.text(checklist.label)]),
    ]),
    div(classes: 'main-home__context-menu-progress-track', [
      span(
        attributes: {'style': 'width: ${(checklist.fraction * 100).round()}%;'},
        [],
      ),
    ]),
  ],
);

class SpaceReportDialog extends StatefulComponent {
  const SpaceReportDialog({required this.spaceId, required this.spaceTitle, required this.onClose, super.key});

  final String spaceId;
  final String spaceTitle;
  final VoidCallback onClose;

  @override
  State<SpaceReportDialog> createState() => _SpaceReportDialogState();
}

class _SpaceReportDialogState extends State<SpaceReportDialog> {
  static const _dialogId = 'main-home-space-report-dialog';
  static const _reasons = {
    'spam': 'Spam or scam',
    'harassment': 'Harassment or bullying',
    'inappropriate': 'Inappropriate or explicit content',
    'hate': 'Hate speech',
    'copyright': 'Copyright or plagiarism',
    'misinformation': 'Misleading information',
    'other': 'Something else',
  };

  String? _reason;
  String _details = '';
  String? _error;
  bool _sending = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncDialog);
  }

  @override
  void didUpdateComponent(covariant SpaceReportDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.spaceId != component.spaceId) {
      _reason = null;
      _details = '';
      _error = null;
      _submitted = false;
    }
  }

  void _syncDialog() {
    if (mounted) WebDialogHelper.syncOpen(_dialogId, true);
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await SpaceDetailActions.reportSpace(
        spaceId: component.spaceId,
        reason: reason,
        details: _details,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _submitted = true;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
    }
  }

  @override
  Component build(BuildContext context) => dialog(
    id: _dialogId,
    classes: 'eduma-modal main-home__report-dialog',
    attributes: {
      ...WebDialogHelper.openAttr(true),
      'aria-labelledby': 'main-home-space-report-title',
      'closedby': 'any',
    },
    events: {
      'close': (_) {
        WebDialogHelper.resetReturnValue(_dialogId);
        component.onClose();
      },
    },
    [
      div(classes: 'eduma-modal__header', [
        div(classes: 'eduma-modal__heading', [
          h2(id: 'main-home-space-report-title', [
            .text(_submitted ? 'Report sent' : 'Report “${component.spaceTitle}”'),
          ]),
          p([
            .text(
              _submitted
                  ? 'The Eduma team will review your report.'
                  : 'Reports are private. The Eduma team reviews every one.',
            ),
          ]),
        ]),
        button(
          classes: 'eduma-modal__close',
          type: ButtonType.button,
          attributes: {'aria-label': 'Close report dialog'},
          onClick: component.onClose,
          [mainHomeIcon(.close, size: 18)],
        ),
      ]),
      if (!_submitted) ...[
        div(classes: 'eduma-modal__body', [
          div(
            classes: 'main-home__report-reasons',
            attributes: {'role': 'group', 'aria-label': 'What is wrong?'},
            [
              for (final entry in _reasons.entries)
                button(
                  type: ButtonType.button,
                  classes: 'main-home__report-reason',
                  attributes: {'aria-pressed': '${_reason == entry.key}'},
                  onClick: () => setState(() => _reason = entry.key),
                  [
                    span(classes: 'main-home__report-radio', [
                      if (_reason == entry.key) span([]),
                    ]),
                    span([.text(entry.value)]),
                  ],
                ),
            ],
          ),
          div(classes: 'eduma-modal__field', [
            label(htmlFor: 'main-home-report-details', [.text('Details (optional)')]),
            textarea(
              id: 'main-home-report-details',
              classes: 'eduma-modal__textarea',
              disabled: _sending,
              attributes: {'maxlength': '500', 'rows': '3'},
              onInput: (value) => setState(() => _details = value),
              [.text(_details)],
            ),
          ]),
          if (_error case final error?) p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(error)]),
        ]),
        div(classes: 'eduma-modal__footer', [
          button(
            classes: 'eduma-modal__btn',
            type: ButtonType.button,
            disabled: _sending,
            onClick: component.onClose,
            [.text('Cancel')],
          ),
          button(
            classes: 'eduma-modal__btn eduma-modal__btn--primary',
            type: ButtonType.button,
            disabled: _reason == null || _sending,
            onClick: () => unawaited(_submit()),
            [.text(_sending ? 'Sending…' : 'Send report')],
          ),
        ]),
      ] else
        div(classes: 'eduma-modal__footer', [
          button(
            classes: 'eduma-modal__btn eduma-modal__btn--primary',
            type: ButtonType.button,
            onClick: component.onClose,
            [.text('Done')],
          ),
        ]),
    ],
  );
}
