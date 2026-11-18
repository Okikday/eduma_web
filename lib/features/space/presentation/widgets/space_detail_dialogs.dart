import 'dart:async';
import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../../auth/data/auth_api.dart';
import '../../../main/data/main_space.dart';
import '../../../main/logic/space_invite_link.dart';
import '../../../main/presentation/widgets/main_home_icons.dart';
import '../../../main/presentation/widgets/web_dialog_helper.dart';
import '../../data/space_detail_models.dart';
import '../../logic/space_detail_actions.dart';

/// Edit space title & description native modal.
class SpaceEditDialog extends StatefulComponent {
  const SpaceEditDialog({
    required this.open,
    required this.space,
    required this.onClose,
    required this.onUpdated,
    super.key,
  });

  final bool open;
  final SpaceDetailData space;
  final VoidCallback onClose;
  final ValueChanged<SpaceDetailData> onUpdated;

  @override
  State<SpaceEditDialog> createState() => _SpaceEditDialogState();
}

class _SpaceEditDialogState extends State<SpaceEditDialog> {
  static const _dialogId = 'space-edit-dialog';

  String _title = '';
  String _description = '';
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seed();
    Future<void>.microtask(_syncDialog);
  }

  @override
  void didUpdateComponent(covariant SpaceEditDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.open && !oldComponent.open) _seed();
    if (component.open != oldComponent.open) Future<void>.microtask(_syncDialog);
  }

  void _seed() {
    _title = component.space.title;
    _description = component.space.description ?? '';
    _error = null;
    _saving = false;
  }

  void _syncDialog() {
    if (mounted) WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  Future<void> _submit() async {
    if (_title.trim().isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await SpaceDetailActions.updateSpace(
        component.space.id,
        title: _title,
        description: _description,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      component.onUpdated(updated);
      component.onClose();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Component build(BuildContext context) => dialog(
    id: _dialogId,
    classes: 'eduma-modal',
    attributes: {...WebDialogHelper.openAttr(component.open), 'aria-labelledby': 'edit-space-title', 'closedby': 'any'},
    events: {
      'close': (_) {
        WebDialogHelper.resetReturnValue(_dialogId);
        if (component.open) component.onClose();
      },
    },
    [
      div(classes: 'eduma-modal__header', [
        div(classes: 'eduma-modal__heading', [
          h2(id: 'edit-space-title', [.text('Edit space')]),
          p([.text('Update the title or description for members')]),
        ]),
        button(
          classes: 'eduma-modal__close',
          type: ButtonType.button,
          attributes: {'aria-label': 'Close Edit space dialog'},
          onClick: component.onClose,
          [mainHomeIcon(.close, size: 18)],
        ),
      ]),
      form(
        events: {
          'submit': (event) {
            event.preventDefault();
            unawaited(_submit());
          },
        },
        [
          div(classes: 'eduma-modal__body', [
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'edit-space-name-input', [.text('Space name')]),
              input<String>(
                id: 'edit-space-name-input',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _title,
                disabled: _saving,
                attributes: {'required': 'true', 'maxlength': '80', 'autofocus': 'true'},
                onInput: (value) => setState(() => _title = value),
              ),
            ]),
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'edit-space-desc-input', [.text('Description')]),
              textarea(
                id: 'edit-space-desc-input',
                classes: 'eduma-modal__textarea',
                disabled: _saving,
                attributes: {'maxlength': '240'},
                onInput: (value) => setState(() => _description = value),
                [.text(_description)],
              ),
            ]),
            if (_error case final message?)
              p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(message)]),
          ]),
          div(classes: 'eduma-modal__footer', [
            button(
              classes: 'eduma-modal__btn eduma-modal__btn--primary',
              type: ButtonType.submit,
              disabled: _title.trim().isEmpty || _saving,
              [.text(_saving ? 'Saving…' : 'Save changes')],
            ),
          ]),
        ],
      ),
    ],
  );
}

/// Create Canvas or Notes page native modal.
class SpaceCreatePageDialog extends StatefulComponent {
  const SpaceCreatePageDialog({
    required this.open,
    required this.spaceId,
    required this.onClose,
    required this.onCreated,
    super.key,
  });

  final bool open;
  final String spaceId;
  final VoidCallback onClose;
  final ValueChanged<SpacePage> onCreated;

  @override
  State<SpaceCreatePageDialog> createState() => _SpaceCreatePageDialogState();
}

class _SpaceCreatePageDialogState extends State<SpaceCreatePageDialog> {
  static const _dialogId = 'space-create-page-dialog';

  String _title = '';
  String _description = '';
  SpacePageType _type = .staticCanvas;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncDialog);
  }

  @override
  void didUpdateComponent(covariant SpaceCreatePageDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.open && !oldComponent.open) {
      _title = '';
      _description = '';
      _type = .staticCanvas;
      _error = null;
      _submitting = false;
    }
    if (component.open != oldComponent.open) Future<void>.microtask(_syncDialog);
  }

  void _syncDialog() {
    if (mounted) WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  Future<void> _submit() async {
    if (_title.trim().isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await SpaceDetailActions.createPage(
        component.spaceId,
        title: _title,
        description: _description,
        pageType: _type,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      component.onCreated(created);
      component.onClose();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    }
  }

  @override
  Component build(BuildContext context) => dialog(
    id: _dialogId,
    classes: 'eduma-modal',
    attributes: {
      ...WebDialogHelper.openAttr(component.open),
      'aria-labelledby': 'create-page-title',
      'closedby': 'any',
    },
    events: {
      'close': (_) {
        WebDialogHelper.resetReturnValue(_dialogId);
        if (component.open) component.onClose();
      },
    },
    [
      div(classes: 'eduma-modal__header', [
        div(classes: 'eduma-modal__heading', [
          h2(id: 'create-page-title', [.text('New page')]),
          p([.text('Add structured Notes or a free-form Canvas to this space')]),
        ]),
        button(
          classes: 'eduma-modal__close',
          type: ButtonType.button,
          attributes: {'aria-label': 'Close New page dialog'},
          onClick: component.onClose,
          [mainHomeIcon(.close, size: 18)],
        ),
      ]),
      form(
        events: {
          'submit': (event) {
            event.preventDefault();
            unawaited(_submit());
          },
        },
        [
          div(classes: 'eduma-modal__body', [
            div(classes: 'space-detail__segment', [
              for (final option in SpacePageType.values)
                button(
                  classes: [
                    'space-detail__type-card',
                    if (_type == option) 'is-selected',
                  ].join(' '),
                  type: ButtonType.button,
                  onClick: () => setState(() => _type = option),
                  [
                    strong([.text(option.label)]),
                    span([.text(option.blurb)]),
                  ],
                ),
            ]),
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'create-page-title-input', [.text('Page title')]),
              input<String>(
                id: 'create-page-title-input',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _title,
                disabled: _submitting,
                attributes: {
                  'required': 'true',
                  'maxlength': '80',
                  'placeholder': 'e.g. Week 4 Summary',
                  'autofocus': 'true',
                },
                onInput: (value) => setState(() => _title = value),
              ),
            ]),
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'create-page-desc-input', [.text('Description (optional)')]),
              textarea(
                id: 'create-page-desc-input',
                classes: 'eduma-modal__textarea',
                disabled: _submitting,
                attributes: {'maxlength': '200'},
                onInput: (value) => setState(() => _description = value),
                [.text(_description)],
              ),
            ]),
            if (_error case final message?)
              p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(message)]),
          ]),
          div(classes: 'eduma-modal__footer', [
            button(
              classes: 'eduma-modal__btn eduma-modal__btn--primary',
              type: ButtonType.submit,
              disabled: _title.trim().isEmpty || _submitting,
              [.text(_submitting ? 'Creating…' : 'Create page')],
            ),
          ]),
        ],
      ),
    ],
  );
}

/// Space invite code & shareable join-link native modal.
class SpaceInviteDialog extends StatefulComponent {
  const SpaceInviteDialog({
    required this.open,
    required this.space,
    required this.canRenew,
    required this.onClose,
    required this.onInviteRenewed,
    super.key,
  });

  final bool open;
  final SpaceDetailData space;
  final bool canRenew;
  final VoidCallback onClose;
  final void Function(String code, DateTime? expiresAt) onInviteRenewed;

  @override
  State<SpaceInviteDialog> createState() => _SpaceInviteDialogState();
}

class _SpaceInviteDialogState extends State<SpaceInviteDialog> {
  static const _dialogId = 'space-invite-dialog';

  bool _renewing = false;
  String? _copiedLabel;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_syncDialog);
  }

  @override
  void didUpdateComponent(covariant SpaceInviteDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.open && !oldComponent.open) {
      _copiedLabel = null;
      _error = null;
    }
    if (component.open != oldComponent.open) Future<void>.microtask(_syncDialog);
  }

  void _syncDialog() {
    if (mounted) WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  Future<void> _copy(String text, String label) async {
    try {
      await web.window.navigator.clipboard.writeText(text).toDart;
      if (!mounted) return;
      setState(() => _copiedLabel = label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Copy failed. Select and copy the text manually.');
    }
  }

  Future<void> _renew() async {
    if (_renewing) return;
    setState(() {
      _renewing = true;
      _error = null;
    });
    try {
      final result = await SpaceDetailActions.renewInviteCode(component.space.id);
      if (!mounted) return;
      setState(() {
        _renewing = false;
        _copiedLabel = 'New invite link generated';
      });
      component.onInviteRenewed(result.inviteCode, result.expiresAt);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _renewing = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _renewing = false;
        _error = error.message;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    final code = component.space.inviteCode.trim();
    final joinLink = code.isEmpty ? '' : SpaceInviteLink.buildForOrigin(web.window.location.origin, code);
    final expiry = SpaceInviteExpiryLogic.label(component.space.inviteCodeExpiresAt);

    return dialog(
      id: _dialogId,
      classes: 'eduma-modal',
      attributes: {
        ...WebDialogHelper.openAttr(component.open),
        'aria-labelledby': 'invite-space-title',
        'closedby': 'any',
      },
      events: {
        'close': (_) {
          WebDialogHelper.resetReturnValue(_dialogId);
          if (component.open) component.onClose();
        },
      },
      [
        div(classes: 'eduma-modal__header', [
          div(classes: 'eduma-modal__heading', [
            h2(id: 'invite-space-title', [.text('Invite to ${component.space.title}')]),
            p([.text('Share this invite code or join link with your peers')]),
          ]),
          button(
            classes: 'eduma-modal__close',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close Invite dialog'},
            onClick: component.onClose,
            [mainHomeIcon(.close, size: 18)],
          ),
        ]),
        div(classes: 'eduma-modal__body', [
          if (code.isNotEmpty) ...[
            div(classes: 'eduma-modal__field', [
              label([.text('Invite code')]),
              div(classes: 'space-detail__invite-box', [
                span(classes: 'space-detail__invite-code', [.text(code)]),
                button(
                  classes: 'eduma-modal__btn',
                  type: ButtonType.button,
                  onClick: () => unawaited(_copy(code, 'Invite code copied')),
                  [mainHomeIcon(.copy, size: 16), .text('Copy code')],
                ),
              ]),
            ]),
            div(classes: 'eduma-modal__field', [
              label([.text('Shareable link')]),
              div(classes: 'space-detail__invite-box', [
                span(classes: 'space-detail__invite-code', [.text(joinLink)]),
                button(
                  classes: 'eduma-modal__btn',
                  type: ButtonType.button,
                  onClick: () => unawaited(_copy(joinLink, 'Invite link copied')),
                  [mainHomeIcon(.link, size: 16), .text('Copy link')],
                ),
              ]),
            ]),
            if (expiry != null) p(classes: 'eduma-modal__hint', [.text(expiry)]),
          ] else
            p(classes: 'eduma-modal__hint', [
              .text('No active invite link yet.'),
            ]),
          if (_copiedLabel case final copied?) p(classes: 'eduma-modal__hint', [.text(copied)]),
          if (_error case final message?)
            p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(message)]),
        ]),
        div(classes: 'eduma-modal__footer', [
          if (component.canRenew)
            button(
              classes: 'eduma-modal__btn',
              type: ButtonType.button,
              disabled: _renewing,
              onClick: () => unawaited(_renew()),
              [mainHomeIcon(.refresh, size: 16), .text(_renewing ? 'Generating…' : 'New link')],
            ),
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
}
