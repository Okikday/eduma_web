import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/presentation/flutter_embedded_page.dart';
import '../../../auth/data/auth_api.dart';
import '../../../main/data/main_space.dart';
import '../../../main/logic/main_actions.dart';
import '../../../main/presentation/widgets/app_tab_shell.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../data/space_detail_api.dart';
import '../../logic/space_detail_actions.dart';

/// Canvas and Notes pages use the Flutter implementation. Without a page id,
/// this route remains the native Quick Note composer.
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

  List<MainSpace> _spaces = const [];
  String _quickSpaceId = '';
  String _quickTitle = '';
  String _quickContent = '';
  bool _creatingQuickNote = false;

  bool get _isQuickNoteMode => (component.pageId ?? '').trim().isEmpty || (component.spaceId ?? '').trim().isEmpty;

  @override
  void initState() {
    super.initState();
    if (_isQuickNoteMode) unawaited(_loadSpaces());
  }

  @override
  void didUpdateComponent(covariant SpacePageViewerPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if ((oldComponent.spaceId != component.spaceId || oldComponent.pageId != component.pageId) && _isQuickNoteMode) {
      unawaited(_loadSpaces());
    }
  }

  Future<void> _loadSpaces() async {
    setState(() {
      _loadingSession = _session == null;
      _loading = true;
      _sessionError = null;
      _error = null;
    });
    try {
      final session = await MainActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() => _session = null);
        return;
      }
      setState(() => _session = session);

      final home = await MainActions.loadHome(session);
      if (!mounted) return;
      setState(() {
        _spaces = home.spaces;
        if (_quickSpaceId.isEmpty && home.spaces.isNotEmpty) {
          _quickSpaceId = home.spaces.first.id;
        }
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load spaces right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loading = false;
        });
      }
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
      final destination = Uri(
        path: '/spacePageStatic',
        queryParameters: {'id': created.id, 'spaceId': spaceId},
      ).toString();
      edumaNavigate(context, destination);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _creatingQuickNote = false);
    }
  }

  @override
  Component build(BuildContext context) {
    if (_isQuickNoteMode) return _buildQuickNoteComposer(context);

    final route = component.isDynamicCanvas ? '/spacePageCanvas' : '/spacePageStatic';
    return flutterEmbeddedPage(
      title: component.isDynamicCanvas ? 'Canvas' : 'Notes',
      route: Uri(
        path: route,
        queryParameters: {
          'spaceId': component.spaceId!.trim(),
          'id': component.pageId!.trim(),
        },
      ).toString(),
    );
  }

  Component _buildQuickNoteComposer(BuildContext context) => adaptivePageScaffold(
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
        onRetrySession: () => unawaited(_loadSpaces()),
        builder: (_) => [
          if (_error case final error?) mainHomeNotice(error, isError: true),
          if (_loading && _spaces.isEmpty)
            div(classes: 'page-viewer__loading', [
              span(classes: 'main-home__spinner', []),
            ])
          else
            div(classes: 'page-viewer__quick-form', [
              label(classes: 'page-viewer__field', [
                span([.text('Space')]),
                select(
                  onChange: (dynamic value) => setState(() => _quickSpaceId = '${value ?? ''}'),
                  [
                    for (final space in _spaces)
                      option(
                        value: space.id,
                        selected: space.id == _quickSpaceId,
                        [.text(space.title)],
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
                  onInput: (dynamic value) => setState(() => _quickTitle = '${value ?? ''}'),
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
                  onInput: (dynamic value) => setState(() => _quickContent = '${value ?? ''}'),
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
                    span([
                      .text(_creatingQuickNote ? 'Creating…' : 'Create note'),
                    ]),
                  ],
                ),
              ]),
            ]),
        ],
      ),
    ],
  );
}
