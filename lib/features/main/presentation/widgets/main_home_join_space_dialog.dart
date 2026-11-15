import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_link.dart';
import '../../../auth/data/auth_api.dart';
import '../../data/main_space.dart';
import '../../data/main_space_mutations.dart';
import '../../logic/main_actions.dart';
import '../../logic/space_invite_link.dart';
import 'main_home_helpers.dart';
import 'main_home_icons.dart';
import 'web_dialog_helper.dart';

/// Native `<dialog>` modal matching `../eduma`'s Join Space flow (code/URL lookup,
/// space preview card, approval-pending handling, and join submission).
class MainHomeJoinSpaceDialog extends StatefulComponent {
  const MainHomeJoinSpaceDialog({
    required this.open,
    required this.initialCode,
    required this.currentUserId,
    required this.onClose,
    required this.onJoined,
    super.key,
  });

  final bool open;
  final String initialCode;
  final String currentUserId;
  final VoidCallback onClose;
  final ValueChanged<MainSpaceJoinResult> onJoined;

  @override
  State<MainHomeJoinSpaceDialog> createState() => _MainHomeJoinSpaceDialogState();
}

class _MainHomeJoinSpaceDialogState extends State<MainHomeJoinSpaceDialog> {
  static const _dialogId = 'main-home-join-space-dialog';

  String _code = '';
  MainSpacePreview? _preview;
  bool _loadingPreview = false;
  bool _joining = false;
  bool _pending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resetFromComponent();
    Future<void>.microtask(_syncDialog);
    if (component.open && SpaceInviteLink.extractCode(_code).isNotEmpty) {
      Future<void>.microtask(_lookupPreview);
    }
  }

  @override
  void didUpdateComponent(covariant MainHomeJoinSpaceDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.open && !oldComponent.open) {
      _resetFromComponent();
      if (SpaceInviteLink.extractCode(_code).isNotEmpty) {
        Future<void>.microtask(_lookupPreview);
      }
    }
    if (component.open != oldComponent.open) {
      Future<void>.microtask(_syncDialog);
    }
  }

  void _resetFromComponent() {
    _code = component.initialCode;
    _preview = null;
    _loadingPreview = false;
    _joining = false;
    _pending = false;
    _error = null;
  }

  void _syncDialog() {
    if (mounted) WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  void _handleNativeClose() {
    WebDialogHelper.resetReturnValue(_dialogId);
    if (component.open) component.onClose();
  }

  Future<void> _lookupPreview() async {
    final extracted = SpaceInviteLink.extractCode(_code);
    if (extracted.isEmpty || _loadingPreview) return;
    setState(() {
      _loadingPreview = true;
      _error = null;
      _preview = null;
      _pending = false;
    });
    try {
      final preview = await MainActions.previewInvite(extracted);
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _preview = preview;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _error = error.message;
      });
    }
  }

  Future<void> _join() async {
    final extracted = SpaceInviteLink.extractCode(_code);
    if (extracted.isEmpty || _joining) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final result = await MainActions.joinSpace(
        extracted,
        currentUserId: component.currentUserId,
      );
      if (!mounted) return;
      if (result.pending) {
        setState(() {
          _joining = false;
          _pending = true;
        });
        return;
      }
      setState(() => _joining = false);
      component.onJoined(result);
      component.onClose();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = error.message;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    final preview = _preview;
    final alreadyMember = preview?.alreadyMember == true;
    final canFind = SpaceInviteLink.extractCode(_code).isNotEmpty && !_loadingPreview;
    final subtitle = alreadyMember
        ? "You're already in this space"
        : component.initialCode.trim().isNotEmpty
        ? 'You were invited to join this space'
        : 'Enter an invite code shared by your peer or educator';

    return dialog(
      id: _dialogId,
      classes: 'eduma-modal',
      attributes: {
        'aria-labelledby': 'join-space-title',
        'closedby': 'any',
      },
      events: {'close': (_) => _handleNativeClose()},
      [
        div(classes: 'eduma-modal__header', [
          div(classes: 'eduma-modal__heading', [
            h2(id: 'join-space-title', [.text('Join a Space')]),
            p([.text(subtitle)]),
          ]),
          button(
            classes: 'eduma-modal__close',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close Join Space dialog'},
            onClick: component.onClose,
            [mainHomeIcon(.close, size: 18)],
          ),
        ]),
        div(classes: 'eduma-modal__body', [
          if (_pending)
            _pendingRequestCard(preview?.title)
          else
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'join-space-code-input', [.text('Invite Code or Link')]),
              div(classes: 'eduma-modal__inline-row', [
                div(classes: 'eduma-modal__input-wrap', [
                  mainHomeIcon(.key, size: 18),
                  input<String>(
                    id: 'join-space-code-input',
                    classes: 'eduma-modal__input',
                    type: InputType.text,
                    value: _code,
                    disabled: _joining,
                    attributes: {
                      'placeholder': 'e.g. SPC-4982',
                      'autofocus': 'true',
                    },
                    onInput: (value) => setState(() {
                      _code = value;
                      _error = null;
                      _pending = false;
                    }),
                  ),
                ]),
                button(
                  classes: 'eduma-modal__btn',
                  type: ButtonType.button,
                  disabled: !canFind || _joining,
                  onClick: () => unawaited(_lookupPreview()),
                  [.text(_loadingPreview ? 'Finding…' : 'Find')],
                ),
              ]),
            ]),
          if (preview != null && !_pending) _previewCard(preview),
          if (_error case final message?)
            p(
              classes: 'eduma-modal__error',
              attributes: {'role': 'alert'},
              [.text(message)],
            ),
        ]),
        div(classes: 'eduma-modal__footer', [
          if (_pending)
            button(
              classes: 'eduma-modal__btn eduma-modal__btn--primary',
              type: ButtonType.button,
              onClick: component.onClose,
              [.text('Done')],
            )
          else if (alreadyMember)
            if (preview?.spaceId case final id?)
              edumaLink(
                to: '/spaceDetail?id=${Uri.encodeComponent(id)}',
                classes: 'eduma-modal__btn eduma-modal__btn--primary',
                children: [.text('Open space')],
              )
            else
              button(
                classes: 'eduma-modal__btn',
                type: ButtonType.button,
                disabled: true,
                [.text('Already joined')],
              )
          else ...[
            button(
              classes: 'eduma-modal__btn',
              type: ButtonType.button,
              disabled: _joining,
              onClick: component.onClose,
              [.text('Cancel')],
            ),
            button(
              classes: 'eduma-modal__btn eduma-modal__btn--primary',
              type: ButtonType.button,
              disabled: SpaceInviteLink.extractCode(_code).isEmpty || _joining,
              onClick: () => unawaited(_join()),
              [.text(_joining ? 'Joining…' : 'Join Space')],
            ),
          ],
        ]),
      ],
    );
  }
}

Component _previewCard(MainSpacePreview preview) => div(classes: 'eduma-modal__preview', [
  div(classes: 'eduma-modal__preview-cover', [
    if (preview.coverUrl case final cover?)
      img(src: cover, alt: '')
    else
      mainHomeIcon(.people, size: 32),
  ]),
  div(classes: 'eduma-modal__preview-body', [
    div(classes: 'eduma-modal__preview-title', [
      span([.text(preview.title)]),
      if (preview.isVerified) mainHomeIcon(.verified, size: 16),
    ]),
    if (preview.description case final description?)
      p(classes: 'eduma-modal__preview-desc', [.text(description)]),
    if (preview.ownerName.isNotEmpty || preview.memberCount > 0)
      div(classes: 'eduma-modal__preview-meta', [
        if (preview.ownerName.isNotEmpty)
          span(classes: 'eduma-modal__preview-fact', [
            mainHomeIcon(.user, size: 14),
            .text('Owner: ${preview.ownerName}'),
          ]),
        if (preview.memberCount > 0)
          span(classes: 'eduma-modal__preview-fact', [
            mainHomeIcon(.people, size: 14),
            .text(mainHomeMemberLabel(preview.memberCount)),
          ]),
      ]),
  ]),
]);

Component _pendingRequestCard(String? spaceTitle) {
  final name = (spaceTitle == null || spaceTitle.isEmpty) ? 'this space' : spaceTitle;
  return div(classes: 'eduma-modal__pending', [
    mainHomeIcon(.clock, size: 28),
    strong([.text('Request sent')]),
    p([.text("An admin of $name will review it. We'll notify you as soon as you're in.")]),
  ]);
}
