enum AiHistoryKind {
  chat,
  quiz,
  flashcards,
  written;

  bool get isStudy => this != chat;

  String? get badgeLabel => switch (this) {
    chat => null,
    quiz => 'Quiz',
    flashcards => 'Flashcards',
    written => 'Short answer',
  };

  static AiHistoryKind fromApi(Object? raw) {
    final s = '${raw ?? ''}'.trim().toLowerCase();
    return switch (s) {
      'quiz' => quiz,
      'flashcards' => flashcards,
      'written' => written,
      _ => chat,
    };
  }
}

class AiHistorySource {
  const AiHistorySource({
    required this.type,
    this.spaceId,
    this.spaceTitle,
    this.pageId,
    this.pageTitle,
    this.documentId,
    this.documentTitle,
  });

  final String type;
  final String? spaceId;
  final String? spaceTitle;
  final String? pageId;
  final String? pageTitle;
  final String? documentId;
  final String? documentTitle;

  String get groupKey {
    if (spaceId != null && spaceId!.isNotEmpty) return 'space:$spaceId';
    if (documentId != null && documentId!.isNotEmpty) return 'doc:$documentId';
    return 'general';
  }

  String get groupTitle {
    if (spaceTitle != null && spaceTitle!.isNotEmpty) return spaceTitle!;
    if (documentTitle != null && documentTitle!.isNotEmpty) return documentTitle!;
    return 'General & other';
  }

  factory AiHistorySource.fromMap(Object? raw) {
    if (raw is! Map) return const AiHistorySource(type: 'general');
    return AiHistorySource(
      type: _opt(raw['type']) ?? 'general',
      spaceId: _opt(raw['spaceId']),
      spaceTitle: _opt(raw['spaceTitle'] ?? raw['spaceName']),
      pageId: _opt(raw['pageId']),
      pageTitle: _opt(raw['pageTitle']),
      documentId: _opt(raw['documentId']),
      documentTitle: _opt(raw['documentTitle']),
    );
  }
}

class AiHistoryMessage {
  const AiHistoryMessage({
    required this.isUser,
    required this.content,
    this.createdAt,
  });

  final bool isUser;
  final String content;
  final DateTime? createdAt;

  static AiHistoryMessage? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final content = '${raw['content'] ?? raw['text'] ?? ''}'.trim();
    if (content.isEmpty) return null;
    final role = '${raw['role'] ?? (raw['isUser'] == true ? 'user' : 'assistant')}'
        .toLowerCase();
    return AiHistoryMessage(
      isUser: role == 'user' || raw['isUser'] == true,
      content: content,
      createdAt: _parseTime(raw['createdAt'] ?? raw['timestamp']),
    );
  }
}

class AiStudyQuestion {
  const AiStudyQuestion({
    required this.prompt,
    this.options = const [],
    this.answer,
    this.explanation,
  });

  final String prompt;
  final List<String> options;
  final String? answer;
  final String? explanation;

  static AiStudyQuestion? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final prompt = '${raw['question'] ?? raw['prompt'] ?? raw['front'] ?? ''}'.trim();
    if (prompt.isEmpty) return null;
    final rawOpts = raw['options'] ?? raw['choices'];
    final opts = [
      if (rawOpts is List)
        for (final opt in rawOpts)
          if ('$opt'.trim().isNotEmpty) '$opt'.trim(),
    ];
    final correctIdx = raw['correctIndex'];
    String? answer = _opt(raw['answer'] ?? raw['back'] ?? raw['correctAnswer']);
    if (answer == null &&
        correctIdx is num &&
        correctIdx.toInt() >= 0 &&
        correctIdx.toInt() < opts.length) {
      answer = opts[correctIdx.toInt()];
    }
    return AiStudyQuestion(
      prompt: prompt,
      options: opts,
      answer: answer,
      explanation: _opt(raw['explanation']),
    );
  }
}

class AiHistoryEntry {
  const AiHistoryEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.source,
    required this.updatedAt,
    this.createdAt,
    this.preview = '',
    this.isPreviewFromUser = false,
    this.messages = const [],
    this.questions = const [],
    this.statsLabel,
    this.deleted = false,
  });

  final String id;
  final AiHistoryKind kind;
  final String title;
  final AiHistorySource source;
  final DateTime updatedAt;
  final DateTime? createdAt;
  final String preview;
  final bool isPreviewFromUser;
  final List<AiHistoryMessage> messages;
  final List<AiStudyQuestion> questions;
  final String? statsLabel;
  final bool deleted;

  String get displayTitle {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    if (messages.isNotEmpty) {
      final first = messages.first.content.replaceAll('\n', ' ').trim();
      return first.length <= 54 ? first : '${first.substring(0, 52)}…';
    }
    return switch (kind) {
      .chat => 'Assistant chat',
      .quiz => 'Practice quiz',
      .flashcards => 'Flashcard deck',
      .written => 'Short answers',
    };
  }

  String get breadcrumbLabel {
    final parts = <String>[
      if (kind.badgeLabel case final label?) label,
      if (source.pageTitle case final p?) p,
      if (source.spaceTitle case final s?) s
      else if (source.documentTitle case final d?) d,
    ];
    return parts.join(' › ');
  }

  static AiHistoryEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id =
        '${raw['clientId'] ?? raw['localId'] ?? raw['id'] ?? raw['_id'] ?? ''}'
            .trim();
    if (id.isEmpty) return null;

    final deleted = raw['deleted'] == true || raw['deletedAt'] != null;
    if (deleted) return null;

    final nested = raw['conversation'] ?? raw['data'] ?? raw['payload'];
    final conv = nested is Map
        ? Map<String, dynamic>.from(nested)
        : Map<String, dynamic>.from(raw);

    final updatedAt =
        _parseTime(raw['updatedAt'] ?? conv['updatedAt'] ?? raw['createdAt']) ??
        DateTime.now();

    final rawMessages = conv['messages'] ?? raw['messages'];
    final messages = [
      if (rawMessages is List)
        for (final m in rawMessages)
          if (AiHistoryMessage.tryParse(m) case final parsed?) parsed,
    ];

    final studySet = conv['set'] ?? raw['set'];
    final questions = _parseQuestions(studySet);
    final kind = AiHistoryKind.fromApi(raw['kind'] ?? conv['kind']);

    String preview = _opt(raw['preview'] ?? conv['preview']) ?? '';
    var isPreviewFromUser = raw['isPreviewFromUser'] == true;
    if (preview.isEmpty && messages.isNotEmpty) {
      preview = messages.last.content.replaceAll(RegExp(r'\s+'), ' ').trim();
      isPreviewFromUser = messages.last.isUser;
    }

    String? statsLabel = _opt(raw['stats'] ?? conv['stats']);
    if (statsLabel == null && questions.isNotEmpty) {
      statsLabel =
          '${questions.length} ${kind == .flashcards ? 'cards' : 'questions'}';
    }

    return AiHistoryEntry(
      id: id,
      kind: kind,
      title: '${raw['title'] ?? conv['title'] ?? ''}'.trim(),
      source: AiHistorySource.fromMap(conv['source'] ?? raw['source']),
      updatedAt: updatedAt,
      createdAt: _parseTime(raw['createdAt'] ?? conv['createdAt']),
      preview: preview,
      isPreviewFromUser: isPreviewFromUser,
      messages: messages,
      questions: questions,
      statsLabel: statsLabel,
      deleted: deleted,
    );
  }
}

class AiHistoryGroup {
  const AiHistoryGroup({
    required this.key,
    required this.title,
    required this.entries,
  });

  final String key;
  final String title;
  final List<AiHistoryEntry> entries;

  DateTime get updatedAt => entries.first.updatedAt;

  String get countsLabel {
    final chats = entries.where((e) => e.kind == .chat).length;
    final quizzes = entries.where((e) => e.kind == .quiz).length;
    final decks = entries.where((e) => e.kind == .flashcards).length;
    final written = entries.where((e) => e.kind == .written).length;
    final parts = [
      if (chats > 0) '$chats ${chats == 1 ? 'chat' : 'chats'}',
      if (quizzes > 0) '$quizzes ${quizzes == 1 ? 'quiz' : 'quizzes'}',
      if (decks > 0) '$decks ${decks == 1 ? 'deck' : 'decks'}',
      if (written > 0) '$written written',
    ];
    return parts.isEmpty ? '${entries.length} items' : parts.join(' · ');
  }
}

String aiRelativeTimeLabel(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 2) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = time.toLocal();
  return '${months[local.month - 1]} ${local.day}';
}

List<AiStudyQuestion> _parseQuestions(Object? rawSet) {
  if (rawSet is! Map) return const [];
  final list = rawSet['questions'] ?? rawSet['cards'] ?? rawSet['items'];
  if (list is! List) return const [];
  return [
    for (final q in list)
      if (AiStudyQuestion.tryParse(q) case final parsed?) parsed,
  ];
}

String? _opt(Object? raw) {
  final s = raw?.toString().trim() ?? '';
  return s.isEmpty || s == 'null' ? null : s;
}

DateTime? _parseTime(Object? raw) => switch (raw) {
  num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true),
  String s => DateTime.tryParse(s),
  _ => null,
};
