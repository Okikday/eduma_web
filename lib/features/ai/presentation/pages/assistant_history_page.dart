import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/presentation/eduma_rich_text.dart';
import '../../../../core/presentation/see_all_bottom_bar.dart';
import '../../../auth/data/auth_api.dart';
import '../../../main/logic/main_actions.dart';
import '../../../main/presentation/widgets/app_tab_shell.dart';
import '../../../main/presentation/widgets/main_home_notices.dart';
import '../../data/ai_history_api.dart';
import '../../data/ai_history_models.dart';

enum _AiViewMode { grouped, all }

enum _AiKindFilter {
  all('All'),
  chats('Chats'),
  quizzes('Quizzes'),
  flashcards('Flashcards');

  const _AiKindFilter(this.label);

  final String label;
}

/// Native AI chat & study-set history screen (`/assistantHistory`), matching
/// `AssistantHistoryView` in `../eduma`.
class AssistantHistoryPage extends StatefulComponent {
  const AssistantHistoryPage({this.conversationId, super.key});

  final String? conversationId;

  @override
  State<AssistantHistoryPage> createState() => _AssistantHistoryPageState();
}

class _AssistantHistoryPageState extends State<AssistantHistoryPage> {
  EdumaSession? _session = MainActions.currentSession;
  bool _loadingSession = MainActions.currentSession == null;
  String? _sessionError;
  List<AiHistoryEntry> _entries = const [];
  bool _loading = false;
  String? _error;

  String _query = '';
  _AiViewMode _view = .grouped;
  _AiKindFilter _filter = .all;
  bool _filterMenuOpen = false;

  AiHistoryGroup? _openGroup;
  AiHistoryEntry? _openEntry;
  bool _loadingDetail = false;
  Set<String> _deletingIds = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
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
      final list = await AiHistoryApi.instance.listHistory();
      if (!mounted) return;
      setState(() => _entries = list);
      final requestedId = component.conversationId;
      if (requestedId != null) {
        AiHistoryEntry? requestedEntry;
        for (final entry in list) {
          if (entry.id == requestedId) {
            requestedEntry = entry;
            break;
          }
        }
        if (requestedEntry == null) {
          setState(() => _error = 'This AI conversation is no longer available.');
        } else {
          unawaited(_openConversation(requestedEntry));
        }
      }
    } on AuthApiException catch (err) {
      if (!mounted) return;
      setState(() => _error = err.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load AI chat history right now.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
          _loading = false;
        });
      }
    }
  }

  @override
  void didUpdateComponent(covariant AssistantHistoryPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    final requestedId = component.conversationId;
    if (oldComponent.conversationId == requestedId) return;
    if (requestedId == null) {
      setState(() {
        _openEntry = null;
        _error = null;
      });
      return;
    }
    for (final entry in _entries) {
      if (entry.id == requestedId) {
        unawaited(_openConversation(entry));
        return;
      }
    }
    if (_loading || _loadingSession) return;
    setState(() => _error = 'This AI conversation is no longer available.');
  }

  Future<void> _openConversation(AiHistoryEntry entry) async {
    setState(() {
      _openEntry = entry;
      _loadingDetail = entry.messages.isEmpty && entry.questions.isEmpty;
      _error = null;
    });
    try {
      final full = await AiHistoryApi.instance.getConversation(entry.id);
      if (!mounted || _openEntry?.id != entry.id || full == null) return;
      setState(() {
        _openEntry = full;
        _entries = [for (final item in _entries) item.id == full.id ? full : item];
      });
    } catch (_) {
      // Keep the summary view if full fetch fails or conversation only has summary.
    } finally {
      if (mounted && _openEntry?.id == entry.id) {
        setState(() => _loadingDetail = false);
      }
    }
  }

  Future<void> _deleteConversation(AiHistoryEntry entry) async {
    if (_deletingIds.contains(entry.id)) return;
    setState(() => _deletingIds = {..._deletingIds, entry.id});
    try {
      await AiHistoryApi.instance.deleteConversation(entry.id);
      if (!mounted) return;
      setState(() {
        _entries = _entries.where((e) => e.id != entry.id).toList();
        if (_openEntry?.id == entry.id) _openEntry = null;
        if (_openGroup != null) {
          final remaining = _openGroup!.entries.where((e) => e.id != entry.id).toList();
          _openGroup = remaining.isEmpty
              ? null
              : AiHistoryGroup(
                  key: _openGroup!.key,
                  title: _openGroup!.title,
                  entries: remaining,
                );
        }
      });
    } on AuthApiException catch (err) {
      if (!mounted) return;
      setState(() => _error = err.message);
    } finally {
      if (mounted) {
        setState(() => _deletingIds = {..._deletingIds}..remove(entry.id));
      }
    }
  }

  List<AiHistoryEntry> get _filteredEntries {
    final q = _query.trim().toLowerCase();
    return _entries.where((entry) {
      final matchesKind = switch (_filter) {
        .all => true,
        .chats => entry.kind == .chat,
        .quizzes => entry.kind == .quiz || entry.kind == .written,
        .flashcards => entry.kind == .flashcards,
      };
      if (!matchesKind) return false;
      if (q.isEmpty) return true;
      return entry.displayTitle.toLowerCase().contains(q) ||
          entry.preview.toLowerCase().contains(q) ||
          (entry.source.spaceTitle?.toLowerCase().contains(q) ?? false) ||
          (entry.source.pageTitle?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<AiHistoryGroup> _buildGroups(List<AiHistoryEntry> items) {
    final byKey = <String, List<AiHistoryEntry>>{};
    final titles = <String, String>{};
    for (final entry in items) {
      final key = entry.source.groupKey;
      titles[key] ??= entry.source.groupTitle;
      (byKey[key] ??= []).add(entry);
    }
    final groups = [
      for (final mapEntry in byKey.entries)
        AiHistoryGroup(
          key: mapEntry.key,
          title: titles[mapEntry.key] ?? 'General & other',
          entries: mapEntry.value,
        ),
    ];
    groups.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return groups;
  }

  @override
  Component build(BuildContext context) {
    final filtered = _filteredEntries;
    final flat = _query.trim().isNotEmpty || _view == .all;
    final groups = flat ? const <AiHistoryGroup>[] : _buildGroups(filtered);
    final hasActiveFilter = _view != .grouped || _filter != .all;

    return adaptivePageScaffold(
      title: 'AI chats',
      subtitle: _entries.isEmpty
          ? 'Chats and study sets'
          : '${_entries.length} ${_entries.length == 1 ? 'item' : 'items'}',
      maxWidth: 1120,
      showEdges: false,
      fullBleed: true,
      fallbackHref: '/main',
      body: [
        appSessionGateBody(
          session: _session,
          loadingSession: _loadingSession,
          sessionError: _sessionError,
          onRetrySession: () => unawaited(_load()),
          builder: (_) => [
            if (_error case final err?) mainHomeNotice(err, isError: true),
            if (_loading && _entries.isEmpty)
              div(classes: 'ai-history__loading', [span(classes: 'main-home__spinner', [])])
            else if (_entries.isEmpty)
              appFeatureStateCard(
                icon: .ai,
                title: 'No AI chats yet',
                message: 'Ask the assistant on a canvas or a document. Your conversations and study sets sync here.',
              )
            else if ((flat && filtered.isEmpty) || (!flat && groups.isEmpty))
              appFeatureStateCard(
                icon: _query.trim().isNotEmpty ? .search : .ai,
                title: _query.trim().isNotEmpty ? 'No matching chats' : 'No ${_filter.label.toLowerCase()} yet',
                message: _query.trim().isNotEmpty
                    ? 'Try another search term or switch filters.'
                    : 'Switch filter or start a new study session with the assistant.',
              )
            else if (!flat)
              div(classes: 'ai-history__list', [
                for (final group in groups) _groupCard(group),
              ])
            else
              div(classes: 'ai-history__list', [
                for (final entry in filtered) _chatCard(entry),
              ]),
          ],
        ),
      ],
      bottomFloatingBar: _session != null && _entries.isNotEmpty
          ? seeAllBottomBar(
              query: _query,
              hintText: 'Search AI chats…',
              onQueryChanged: (q) => setState(() => _query = q),
              filterFirst: true,
              filterActive: hasActiveFilter,
              filterMenuOpen: _filterMenuOpen,
              onToggleFilterMenu: () => setState(() => _filterMenuOpen = !_filterMenuOpen),
              onCloseFilterMenu: () => setState(() => _filterMenuOpen = false),
              filterMenuChildren: [
                seeAllFilterGroup('VIEW', [
                  seeAllFilterOption(
                    icon: EdumaIcons.layer,
                    label: 'Grouped by space',
                    selected: _view == .grouped,
                    onTap: () => setState(() {
                      _view = .grouped;
                      _filterMenuOpen = false;
                    }),
                  ),
                  seeAllFilterOption(
                    icon: EdumaIcons.list,
                    label: 'All items',
                    selected: _view == .all,
                    onTap: () => setState(() {
                      _view = .all;
                      _filterMenuOpen = false;
                    }),
                  ),
                ]),
                seeAllFilterGroup('TYPE', [
                  for (final k in _AiKindFilter.values)
                    seeAllFilterOption(
                      icon: switch (k) {
                        .all => EdumaIcons.sparkles,
                        .chats => EdumaIcons.messages2,
                        .quizzes => EdumaIcons.tickCircle,
                        .flashcards => EdumaIcons.element4,
                      },
                      label: k.label,
                      selected: _filter == k,
                      onTap: () => setState(() {
                        _filter = k;
                        _filterMenuOpen = false;
                      }),
                    ),
                ]),
              ],
            )
          : null,
      overlays: [
        if (_openGroup case final group?) _groupSheet(group),
        if (_openEntry case final entry?) _conversationModal(entry),
      ],
    );
  }

  Component _groupCard(AiHistoryGroup group) {
    final latest = group.entries.first;
    return button(
      classes: 'ai-history__card',
      type: ButtonType.button,
      onClick: () => setState(() => _openGroup = group),
      [
        span(classes: 'ai-history__leading ai-history__leading--group', [
          edumaIcon(
            group.key.startsWith('space:')
                ? EdumaIcons.layer
                : group.key.startsWith('doc:')
                ? EdumaIcons.book1
                : EdumaIcons.sparkles,
            size: 22,
          ),
        ]),
        div(classes: 'ai-history__copy', [
          strong(classes: 'ai-history__title', [.text(group.title)]),
          span(classes: 'ai-history__preview', [.text(latest.displayTitle)]),
          div(classes: 'ai-history__meta-row', [
            span(classes: 'ai-history__counts', [.text(group.countsLabel)]),
            span(classes: 'ai-history__dot', [.text('·')]),
            span(classes: 'ai-history__when', [.text(aiRelativeTimeLabel(group.updatedAt))]),
          ]),
        ]),
        span(classes: 'ai-history__chevron', [
          edumaIcon(EdumaIcons.chevronRight, size: 16),
        ]),
      ],
    );
  }

  Component _chatCard(AiHistoryEntry entry) {
    final previewText = entry.kind.isStudy
        ? (entry.statsLabel ?? '')
        : (entry.preview.isEmpty ? '' : (entry.isPreviewFromUser ? 'You: ${entry.preview}' : entry.preview));
    return div(classes: 'ai-history__card-wrap', [
      button(
        classes: 'ai-history__card',
        type: ButtonType.button,
        onClick: () => unawaited(_openConversation(entry)),
        [
          span(classes: 'ai-history__leading', [
            edumaIcon(switch (entry.kind) {
              .chat => EdumaIcons.messages2,
              .quiz => EdumaIcons.tickCircle,
              .flashcards => EdumaIcons.element4,
              .written => EdumaIcons.edit,
            }, size: 22),
          ]),
          div(classes: 'ai-history__copy', [
            div(classes: 'ai-history__title-row', [
              strong(classes: 'ai-history__title', [.text(entry.displayTitle)]),
              span(classes: 'ai-history__when', [.text(aiRelativeTimeLabel(entry.updatedAt))]),
            ]),
            if (previewText.isNotEmpty) span(classes: 'ai-history__preview', [.text(previewText)]),
            if (entry.breadcrumbLabel.isNotEmpty) span(classes: 'ai-history__crumb', [.text(entry.breadcrumbLabel)]),
          ]),
        ],
      ),
      button(
        classes: 'ai-history__delete-btn',
        type: ButtonType.button,
        disabled: _deletingIds.contains(entry.id),
        attributes: {'aria-label': 'Delete ${entry.displayTitle}', 'title': 'Delete'},
        onClick: () => unawaited(_deleteConversation(entry)),
        [edumaIcon(EdumaIcons.delete, size: 16)],
      ),
    ]);
  }

  Component _groupSheet(AiHistoryGroup group) => div(
    classes: 'ai-history__overlay ai-history__overlay--group',
    attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': group.title},
    events: {
      'click': (e) {
        if (e.target == e.currentTarget) setState(() => _openGroup = null);
      },
    },
    [
      div(classes: 'ai-history__overlay-panel ai-history__overlay-panel--group', [
        div(classes: 'space-detail__modal-head', [
          div([
            h2([.text(group.title)]),
            p([.text(group.countsLabel)]),
          ]),
          button(
            classes: 'space-detail__modal-close',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close'},
            onClick: () => setState(() => _openGroup = null),
            [edumaIcon(EdumaIcons.closePlain, size: 18)],
          ),
        ]),
        div(classes: 'space-detail__modal-body ai-history__sheet-list', [
          for (final entry in group.entries) _chatCard(entry),
        ]),
      ]),
    ],
  );

  Component _conversationModal(AiHistoryEntry entry) {
    final sourceSpaceId = entry.source.spaceId;
    final sourcePageId = entry.source.pageId;
    final pageRoute = (sourceSpaceId != null && sourcePageId != null)
        ? Uri(
            path: '/spacePageStatic',
            queryParameters: {'id': sourcePageId, 'spaceId': sourceSpaceId},
          ).toString()
        : null;

    return div(
      classes: 'ai-history__overlay ai-history__overlay--conversation',
      attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': entry.displayTitle},
      events: {
        'click': (e) {
          if (e.target == e.currentTarget) setState(() => _openEntry = null);
        },
      },
      [
        div(classes: 'ai-history__overlay-panel ai-history__overlay-panel--conversation', [
          div(classes: 'space-detail__modal-head', [
            div(classes: 'ai-history__dialog-head-copy', [
              h2([.text(entry.displayTitle)]),
              p([
                .text(
                  entry.breadcrumbLabel.isEmpty
                      ? aiRelativeTimeLabel(entry.updatedAt)
                      : '${entry.breadcrumbLabel} · ${aiRelativeTimeLabel(entry.updatedAt)}',
                ),
              ]),
            ]),
            div(classes: 'space-detail__modal-head-actions', [
              if (pageRoute != null)
                edumaLink(
                  to: pageRoute,
                  classes: 'eduma-desktop-pill eduma-desktop-pill--tonal',
                  children: [
                    edumaIcon(EdumaIcons.note, size: 14),
                    span([.text('Open page')]),
                  ],
                ),
              button(
                classes: 'space-detail__modal-close',
                type: ButtonType.button,
                attributes: {'aria-label': 'Close conversation'},
                onClick: () => setState(() => _openEntry = null),
                [edumaIcon(EdumaIcons.closePlain, size: 18)],
              ),
            ]),
          ]),
          div(classes: 'space-detail__modal-body ai-history__thread', [
            if (_loadingDetail)
              div(classes: 'ai-history__loading', [span(classes: 'main-home__spinner', [])])
            else if (entry.questions.isNotEmpty)
              for (var i = 0; i < entry.questions.length; i++)
                div(classes: 'ai-history__study-card', [
                  strong([.text('${i + 1}. ${entry.questions[i].prompt}')]),
                  if (entry.questions[i].options.isNotEmpty)
                    ul(classes: 'ai-history__study-opts', [
                      for (final opt in entry.questions[i].options)
                        li(
                          classes: entry.questions[i].answer == opt ? 'is-correct' : '',
                          [.text(opt)],
                        ),
                    ]),
                  if (entry.questions[i].answer case final ans?)
                    p(classes: 'ai-history__study-answer', [.text('Answer: $ans')]),
                  if (entry.questions[i].explanation case final exp?) p(classes: 'ai-history__study-exp', [.text(exp)]),
                ])
            else if (entry.messages.isNotEmpty)
              for (final msg in entry.messages)
                div(
                  classes: msg.isUser ? 'ai-history__bubble is-user' : 'ai-history__bubble is-assistant',
                  [
                    span(classes: 'ai-history__bubble-role', [
                      .text(msg.isUser ? 'You' : 'Eduma AI'),
                    ]),
                    if (msg.isUser) p([.text(msg.content)]) else ...edumaRenderMarkdownBlocks(msg.content),
                  ],
                )
            else if (entry.preview.isNotEmpty)
              div(classes: 'ai-history__bubble is-assistant', [
                p([.text(entry.preview)]),
              ])
            else
              p(classes: 'ai-history__empty-note', [.text('No saved messages in this entry.')]),
          ]),
        ]),
      ],
    );
  }
}
