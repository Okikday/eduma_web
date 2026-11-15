import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/presentation/eduma_rich_text.dart';
import '../../../auth/data/auth_api.dart';
import '../../../main/data/main_space.dart';
import '../../../main/logic/main_actions.dart';
import '../../../main/presentation/widgets/app_tab_shell.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../data/space_detail_api.dart';
import '../../data/space_page_content_models.dart';
import '../../logic/space_detail_actions.dart';

/// Native in-app reader & quick editor for `/spacePageStatic` (Notes) and
/// `/spacePageCanvas` (Canvas). When opened without `id`, offers a native Quick
/// Note composer targeting any space.
class SpacePageViewerPage extends StatefulComponent {
  const SpacePageViewerPage({
    required this.isDynamicCanvas,
    this.spaceId,
    this.pageId,
    super.key,
  });

  final bool isDynamicCanvas;
  final String? spaceId;
  final String? pageId;

  @override
  State<SpacePageViewerPage> createState() => _SpacePageViewerPageState();
}

class _SpacePageViewerPageState extends State<SpacePageViewerPage> {
  EdumaSession? _session = MainActions.currentSession;
  bool _loadingSession = MainActions.currentSession == null;
  String? _sessionError;
  bool _loading = false;
  String? _error;
  String? _notice;
  bool _noticeIsError = false;

  FullSpacePageData? _data;
  int _selectedSection = 0;
  bool _editingTitle = false;
  String _draftTitle = '';
  bool _addingContent = false;
  String _newBlockText = '';
  bool _saving = false;

  // Quick Note composer state (when opened without a page id)
  List<MainSpace> _spaces = const [];
  String _quickSpaceId = '';
  String _quickTitle = '';
  String _quickContent = '';
  bool _creatingQuickNote = false;

  bool get _isQuickNoteMode =>
      (component.pageId ?? '').trim().isEmpty ||
      (component.spaceId ?? '').trim().isEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateComponent(covariant SpacePageViewerPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.spaceId != component.spaceId ||
        oldComponent.pageId != component.pageId) {
      _data = null;
      _selectedSection = 0;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loadingSession = _session == null;
      _loading = true;
      _sessionError = null;
      _error = null;
      _notice = null;
    });
    try {
      final session = await MainActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() => _session = null);
        return;
      }
      setState(() => _session = session);

      if (_isQuickNoteMode) {
        final home = await MainActions.loadHome(session);
        if (!mounted) return;
        setState(() {
          _spaces = home.spaces;
          if (_quickSpaceId.isEmpty && home.spaces.isNotEmpty) {
            _quickSpaceId = home.spaces.first.id;
          }
        });
        return;
      }

      final spaceId = component.spaceId!.trim();
      final pageId = component.pageId!.trim();
      final full = await SpaceDetailApi.instance.loadFullPage(spaceId, pageId);
      if (!mounted) return;
      setState(() {
        _data = full;
        _draftTitle = full.page.title;
      });
      unawaited(SpaceDetailApi.instance.markPageOpened(spaceId, pageId));
    } on AuthApiException catch (err) {
      if (!mounted) return;
      setState(() => _error = err.message);
    } on MainApiException catch (err) {
      if (!mounted) return;
      setState(() => _error = err.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load this page right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveTitle() async {
    final data = _data;
    final trimmed = _draftTitle.trim();
    if (data == null || trimmed.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await SpaceDetailActions.updatePage(
        data.page.spaceId,
        data.page.id,
        title: trimmed,
      );
      if (!mounted) return;
      setState(() {
        _data = FullSpacePageData(
          page: updated,
          sections: data.sections,
          rawSections: data.rawSections,
          elements: data.elements,
          rawElements: data.rawElements,
          version: data.version,
        );
        _editingTitle = false;
        _notice = 'Title updated';
        _noticeIsError = false;
      });
    } on AuthApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _notice = err.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _appendNoteOrCard() async {
    final data = _data;
    final text = _newBlockText.trim();
    if (data == null || text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final isDynamic = data.page.pageType.isDynamic;
      if (isDynamic) {
        final nextElements = [
          ...data.rawElements,
          {
            'id': 'el_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'stickyNote',
            'x': 80 + (data.rawElements.length % 3) * 240,
            'y': 80 + (data.rawElements.length ~/ 3) * 200,
            'width': 220,
            'height': 180,
            'colorIndex': data.rawElements.length % 5,
            'text': text,
            'deltaJson': [
              {'insert': '$text\n'},
            ],
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          },
        ];
        await SpaceDetailApi.instance.savePageContent(
          data.page.spaceId,
          data.page.id,
          elements: nextElements,
          baseVersion: data.version,
        );
      } else {
        final existing = [...data.rawSections];
        final targetIndex =
            existing.isEmpty ? -1 : _selectedSection.clamp(0, existing.length - 1);
        if (targetIndex < 0) {
          existing.add({
            'id': 'sec_${DateTime.now().millisecondsSinceEpoch}',
            'name': 'Section 1',
            'delta': [
              {'insert': '$text\n'},
            ],
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          final section = Map<String, dynamic>.from(existing[targetIndex]);
          final rawDelta = section['delta'] is List
              ? [
                  for (final op in section['delta'] as List)
                    if (op is Map) Map<String, dynamic>.from(op),
                ]
              : <Map<String, dynamic>>[];
          rawDelta.add({'insert': '$text\n'});
          section['delta'] = rawDelta;
          section['updatedAt'] = DateTime.now().toUtc().toIso8601String();
          existing[targetIndex] = section;
        }
        await SpaceDetailApi.instance.savePageContent(
          data.page.spaceId,
          data.page.id,
          sections: existing,
          baseVersion: data.version,
        );
      }
      _newBlockText = '';
      _addingContent = false;
      await _load();
      if (!mounted) return;
      setState(() {
        _notice = isDynamic ? 'Added card to canvas' : 'Added to note';
        _noticeIsError = false;
      });
    } on AuthApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _notice = err.message;
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createQuickNote(BuildContext context) async {
    final spaceId = _quickSpaceId.trim();
    final title = _quickTitle.trim().isEmpty ? 'Quick note' : _quickTitle.trim();
    if (spaceId.isEmpty || _creatingQuickNote) return;
    setState(() {
      _creatingQuickNote = true;
      _error = null;
    });
    try {
      final created = await SpaceDetailActions.createPage(
        spaceId,
        title: title,
        pageType: .staticCanvas,
      );
      if (_quickContent.trim().isNotEmpty) {
        await SpaceDetailApi.instance.savePageContent(
          spaceId,
          created.id,
          sections: [
            {
              'id': 'sec_${DateTime.now().millisecondsSinceEpoch}',
              'name': 'Notes',
              'delta': [
                {'insert': '${_quickContent.trim()}\n'},
              ],
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            },
          ],
        );
      }
      if (!mounted) return;
      final dest = Uri(
        path: '/spacePageStatic',
        queryParameters: {'id': created.id, 'spaceId': spaceId},
      ).toString();
      edumaNavigate(context, dest);
    } on AuthApiException catch (err) {
      if (!mounted) return;
      setState(() => _error = err.message);
    } on MainApiException catch (err) {
      if (!mounted) return;
      setState(() => _error = err.message);
    } finally {
      if (mounted) setState(() => _creatingQuickNote = false);
    }
  }

  @override
  Component build(BuildContext context) {
    if (_isQuickNoteMode) {
      return _buildQuickNoteComposer(context);
    }
    final data = _data;
    final spaceId = component.spaceId?.trim() ?? '';
    final spaceHref = '/spaceDetail?id=${Uri.encodeComponent(spaceId)}';

    return adaptivePageScaffold(
      title: data?.page.title ?? (component.isDynamicCanvas ? 'Canvas' : 'Note'),
      subtitle: data != null
          ? '${data.page.pageType.label}${data.page.checklistTotal > 0 ? ' · ${data.page.checklistDone}/${data.page.checklistTotal} done' : ''}'
          : null,
      maxWidth: 1040,
      showEdges: false,
      fallbackHref: spaceHref,
      trailing: div(classes: 'page-viewer__head-actions', [
        if (data != null)
          button(
            classes: 'main-home__icon-link main-home__header-circle',
            type: ButtonType.button,
            attributes: {'aria-label': 'Add content', 'title': 'Add note or card'},
            onClick: () => setState(() => _addingContent = !_addingContent),
            [edumaIcon(EdumaIcons.add, size: 18)],
          ),
        edumaLink(
          to: spaceHref,
          classes: 'eduma-desktop-pill eduma-desktop-pill--tonal',
          children: [
            edumaIcon(EdumaIcons.layer, size: 15),
            span([.text('Space')]),
          ],
        ),
      ]),
      body: [
        appSessionGateBody(
          session: _session,
          loadingSession: _loadingSession,
          sessionError: _sessionError,
          onRetrySession: () => unawaited(_load()),
          builder: (_) => [
            if (_error case final err?) mainHomeNotice(err, isError: true),
            if (_notice case final msg?)
              mainHomeNotice(msg, isError: _noticeIsError),
            if (_loading && data == null)
              div(classes: 'page-viewer__loading', [span(classes: 'main-home__spinner', [])])
            else if (data != null)
              ..._buildPageBody(data),
          ],
        ),
      ],
    );
  }

  List<Component> _buildPageBody(FullSpacePageData data) {
    return [
      div(classes: 'page-viewer__meta-card', [
        div(classes: 'page-viewer__meta-title-row', [
          span(
            classes: data.page.pageType.isDynamic
                ? 'space-detail__type-pill space-detail__type-pill--canvas'
                : 'space-detail__type-pill space-detail__type-pill--notes',
            [
              edumaIcon(
                data.page.pageType.isDynamic ? EdumaIcons.canvas : EdumaIcons.note,
                size: 12,
              ),
              span([.text(data.page.pageType.label)]),
            ],
          ),
          if (_editingTitle)
            div(classes: 'page-viewer__title-edit', [
              input(
                type: InputType.text,
                value: _draftTitle,
                attributes: {'aria-label': 'Page title'},
                onInput: (dynamic val) =>
                    setState(() => _draftTitle = '${val ?? ''}'),
              ),
              button(
                classes: 'eduma-desktop-pill eduma-desktop-pill--primary',
                type: ButtonType.button,
                disabled: _saving,
                onClick: () => unawaited(_saveTitle()),
                [.text(_saving ? 'Saving…' : 'Save')],
              ),
              button(
                classes: 'eduma-desktop-pill eduma-desktop-pill--tonal',
                type: ButtonType.button,
                onClick: () => setState(() => _editingTitle = false),
                [.text('Cancel')],
              ),
            ])
          else
            button(
              classes: 'page-viewer__rename-btn',
              type: ButtonType.button,
              onClick: () => setState(() {
                _draftTitle = data.page.title;
                _editingTitle = true;
              }),
              [
                h2([.text(data.page.title)]),
                edumaIcon(EdumaIcons.edit, size: 14),
              ],
            ),
        ]),
        if (data.page.description case final desc?)
          p(classes: 'page-viewer__desc', [.text(desc)]),
      ]),
      if (_addingContent)
        div(classes: 'page-viewer__composer', [
          textarea(
            classes: 'page-viewer__textarea',
            attributes: {
              'rows': '4',
              'placeholder': data.page.pageType.isDynamic
                  ? 'Add a sticky note to this canvas…'
                  : 'Write to this section…',
            },
            onInput: (dynamic val) =>
                setState(() => _newBlockText = '${val ?? ''}'),
            [.text(_newBlockText)],
          ),
          div(classes: 'page-viewer__composer-actions', [
            button(
              classes: 'eduma-desktop-pill eduma-desktop-pill--tonal',
              type: ButtonType.button,
              onClick: () => setState(() => _addingContent = false),
              [.text('Cancel')],
            ),
            button(
              classes: 'eduma-desktop-pill eduma-desktop-pill--primary',
              type: ButtonType.button,
              disabled: _saving || _newBlockText.trim().isEmpty,
              onClick: () => unawaited(_appendNoteOrCard()),
              [
                edumaIcon(EdumaIcons.add, size: 15),
                span([.text(_saving ? 'Saving…' : 'Add')]),
              ],
            ),
          ]),
        ]),
      if (data.page.pageType.isDynamic)
        _buildCanvasView(data)
      else
        _buildStaticView(data),
    ];
  }

  Component _buildStaticView(FullSpacePageData data) {
    if (data.sections.isEmpty) {
      return appFeatureStateCard(
        icon: .note,
        title: 'Empty note',
        message: 'Tap + above to start writing in this note.',
      );
    }
    final activeIdx = _selectedSection.clamp(0, data.sections.length - 1);
    final section = data.sections[activeIdx];
    return div(classes: 'page-viewer__static', [
      if (data.sections.length > 1)
        div(classes: 'page-viewer__section-tabs', [
          for (var i = 0; i < data.sections.length; i++)
            button(
              classes: [
                'page-viewer__section-tab',
                if (i == activeIdx) 'is-active',
              ].join(' '),
              type: ButtonType.button,
              onClick: () => setState(() => _selectedSection = i),
              [.text(data.sections[i].name)],
            ),
        ]),
      article(classes: 'page-viewer__document-card', [
        if (section.lines.isEmpty)
          p(classes: 'page-viewer__empty-section', [.text('This section is empty.')])
        else
          for (final line in section.lines) _renderStaticLine(line),
      ]),
    ]);
  }

  Component _renderStaticLine(StaticDisplayLine line) {
    return switch (line.kind) {
      'heading' => line.headingLevel == 1
          ? h2(classes: 'page-viewer__h1', edumaRichInlineSpans(line.text))
          : h3(classes: 'page-viewer__h2', edumaRichInlineSpans(line.text)),
      'checklist' => div(
          classes: line.checked == true
              ? 'page-viewer__check is-done'
              : 'page-viewer__check',
          [
            span(classes: 'page-viewer__check-box', [
              if (line.checked == true) edumaIcon(EdumaIcons.check, size: 12),
            ]),
            span(edumaRichInlineSpans(line.text)),
          ],
        ),
      'bullet' => div(classes: 'page-viewer__bullet', [
          span(classes: 'page-viewer__bullet-dot', [.text('•')]),
          span(edumaRichInlineSpans(line.text)),
        ]),
      'code' => pre(classes: 'page-viewer__code', [code([.text(line.text)])]),
      'callout' => div(classes: 'page-viewer__callout', edumaRichInlineSpans(line.text)),
      'reference' => line.url != null
          ? a(
              href: line.url!,
              target: Target.blank,
              attributes: {'rel': 'noopener noreferrer'},
              classes: 'page-viewer__ref',
              [
                edumaIcon(EdumaIcons.link, size: 16),
                span([.text(line.text)]),
              ],
            )
          : div(classes: 'page-viewer__callout', edumaRichInlineSpans(line.text)),
      _ => p(classes: 'page-viewer__para', edumaRichInlineSpans(line.text)),
    };
  }

  Component _buildCanvasView(FullSpacePageData data) {
    if (data.elements.isEmpty) {
      return appFeatureStateCard(
        icon: .canvas,
        title: 'Blank canvas',
        message: 'Tap + above to add a sticky note card to this canvas.',
      );
    }
    return div(classes: 'page-viewer__canvas-grid', [
      for (final card in data.elements)
        div(
          classes:
              'page-viewer__canvas-card page-viewer__canvas-card--${card.colorIndex % 5}',
          [
            div(classes: 'page-viewer__canvas-card-head', [
              span(classes: 'page-viewer__canvas-kind', [.text(card.type)]),
            ]),
            if (card.title.isNotEmpty)
              strong(classes: 'page-viewer__canvas-title', [.text(card.title)]),
            if (card.text.isNotEmpty)
              p(classes: 'page-viewer__canvas-text', [.text(card.text)]),
            if (card.checklist.isNotEmpty)
              div(classes: 'page-viewer__canvas-checks', [
                for (final item in card.checklist)
                  div(
                    classes: item.done
                        ? 'page-viewer__check is-done'
                        : 'page-viewer__check',
                    [
                      span(classes: 'page-viewer__check-box', [
                        if (item.done) edumaIcon(EdumaIcons.check, size: 11),
                      ]),
                      span([.text(item.text)]),
                    ],
                  ),
              ]),
            if (card.referenceUrl case final url?)
              a(
                href: url,
                target: Target.blank,
                attributes: {'rel': 'noopener noreferrer'},
                classes: 'page-viewer__ref',
                [
                  edumaIcon(EdumaIcons.link, size: 15),
                  span([.text(url)]),
                ],
              ),
          ],
        ),
    ]);
  }

  Component _buildQuickNoteComposer(BuildContext context) {
    return adaptivePageScaffold(
      title: 'Quick note',
      subtitle: 'Create a note page inside any space',
      maxWidth: 680,
      showEdges: false,
      fallbackHref: '/main',
      body: [
        appSessionGateBody(
          session: _session,
          loadingSession: _loadingSession,
          sessionError: _sessionError,
          onRetrySession: () => unawaited(_load()),
          builder: (_) => [
            if (_error case final err?) mainHomeNotice(err, isError: true),
            if (_loading && _spaces.isEmpty)
              div(classes: 'page-viewer__loading', [span(classes: 'main-home__spinner', [])])
            else
              div(classes: 'page-viewer__quick-form', [
                label(classes: 'page-viewer__field', [
                  span([.text('Space')]),
                  select(
                    onChange: (dynamic val) =>
                        setState(() => _quickSpaceId = '${val ?? ''}'),
                    [
                      for (final s in _spaces)
                        option(
                          value: s.id,
                          selected: s.id == _quickSpaceId,
                          [.text(s.title)],
                        ),
                    ],
                  ),
                ]),
                label(classes: 'page-viewer__field', [
                  span([.text('Title')]),
                  input(
                    type: InputType.text,
                    value: _quickTitle,
                    attributes: {'placeholder': 'Quick study note…'},
                    onInput: (dynamic val) =>
                        setState(() => _quickTitle = '${val ?? ''}'),
                  ),
                ]),
                label(classes: 'page-viewer__field', [
                  span([.text('Notes')]),
                  textarea(
                    classes: 'page-viewer__textarea',
                    attributes: {
                      'rows': '6',
                      'placeholder': 'Start writing…',
                    },
                    onInput: (dynamic val) =>
                        setState(() => _quickContent = '${val ?? ''}'),
                    [.text(_quickContent)],
                  ),
                ]),
                div(classes: 'page-viewer__composer-actions', [
                  button(
                    classes: 'eduma-desktop-pill eduma-desktop-pill--primary',
                    type: ButtonType.button,
                    disabled: _creatingQuickNote || _quickSpaceId.isEmpty,
                    onClick: () => unawaited(_createQuickNote(context)),
                    [
                      edumaIcon(EdumaIcons.noteAdd, size: 16),
                      span([.text(_creatingQuickNote ? 'Creating…' : 'Create note')]),
                    ],
                  ),
                ]),
              ]),
          ],
        ),
      ],
    );
  }
}
