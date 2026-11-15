import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../auth/logic/auth_actions.dart';
import '../../data/main_canvas.dart';
import '../../data/main_space.dart';

/// Deterministic accent trio for a Space grid card, using FNV-1a to mirror
/// `SpaceGridTints.of` in the Flutter app.
typedef SpaceAccentTrio = ({String main, String left, String right});

const _spaceAccents = [
  'var(--eduma-accent-violet)',
  'var(--eduma-accent-sky)',
  'var(--eduma-accent-teal)',
  'var(--eduma-accent-amber)',
  'var(--eduma-accent-rose)',
  'var(--eduma-accent-green)',
];

SpaceAccentTrio spaceGridAccentTrio(String id) {
  var hash = 0x811c9dc5;
  for (final codeUnit in id.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
  }
  final index = hash % _spaceAccents.length;
  return (
    main: _spaceAccents[index],
    left: _spaceAccents[(index + 2) % _spaceAccents.length],
    right: _spaceAccents[(index + 4) % _spaceAccents.length],
  );
}

String mainHomeFirstName(String? rawName) {
  final trimmed = rawName?.trim() ?? '';
  return trimmed.isEmpty ? 'Friend' : trimmed.split(RegExp(r'\s+')).first;
}

String mainHomeGreetingWord(DateTime now) => switch (now.hour) {
  < 12 => 'Good morning',
  < 17 => 'Good afternoon',
  _ => 'Good evening',
};

String? mainHomeFlutterPath(String path, {Map<String, String> query = const {}}) {
  if (!AuthActions.canOpenFlutterApp) return null;
  final base = Uri.parse(edumaFlutterAppUrl);
  final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
  final appBase = base.replace(path: basePath, query: '', fragment: '');
  final routePath = path.startsWith('/') ? path.substring(1) : path;
  return appBase
      .resolve(
        Uri(
          path: routePath,
          queryParameters: query.isEmpty ? null : query,
        ).toString(),
      )
      .toString();
}

Component mainHomeHandoffLink(
  String path,
  String classes,
  List<Component> children, {
  Map<String, String> query = const {},
  Map<String, String> attributes = const {},
}) {
  final href = mainHomeFlutterPath(path, query: query);
  if (href == null) {
    return div(
      classes: '$classes is-disabled',
      attributes: attributes,
      children,
    );
  }
  return a(
    href: href,
    classes: classes,
    attributes: attributes,
    children,
  );
}

String mainHomeMemberLabel(int count) => '$count ${count == 1 ? 'member' : 'members'}';

const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _shortRelativeActivity(String prefix, DateTime date) {
  final elapsed = DateTime.now().difference(date);
  if (elapsed.isNegative || elapsed.inMinutes < 1) return '$prefix just now';
  if (elapsed.inHours < 1) return '$prefix ${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return '$prefix ${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return '$prefix ${elapsed.inDays}d ago';
  return '$prefix ${_shortMonths[date.month - 1]} ${date.day}';
}

String mainHomeActivityLabel(
  DateTime? date,
  MainSpaceActivityType? activityType,
) {
  if (date == null || activityType == null) return '';
  return _shortRelativeActivity(activityType == .edited ? 'Edited' : 'Opened', date);
}

String mainHomeCanvasActivityLabel(MainCanvas canvas) {
  final openedAt = canvas.openedAt;
  if (openedAt == null) {
    return 'Resume ${canvas.type == .dynamicCanvas ? 'canvas' : 'note'}';
  }
  return _shortRelativeActivity('Edited', openedAt);
}

String mainHomeDateLabel(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String mainHomeInitials(String? name) {
  final parts = name?.trim().split(RegExp(r'\s+')) ?? const [];
  return parts.where((part) => part.isNotEmpty).take(2).map((part) => part[0].toUpperCase()).join();
}

String? mainHomeSafeImageUrl(Object? value) {
  final uri = Uri.tryParse(value?.toString() ?? '');
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri.toString();
}

List<MainSpace> mainHomeReplacePin(
  List<MainSpace> spaces,
  String spaceId,
  bool pinned,
) => [
  for (final item in spaces) item.id == spaceId ? item.copyWith(isPinned: pinned) : item,
];

List<MainSpace> mainHomeSyncPinnedList(
  List<MainSpace> pinnedSpaces,
  MainSpace target,
  bool pinned,
) {
  final without = pinnedSpaces.where((item) => item.id != target.id).toList();
  if (!pinned) return without;
  return [target.copyWith(isPinned: true), ...without];
}
