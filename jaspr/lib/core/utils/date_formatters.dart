/// Shared date and time formatting helpers safe for Dart VM tests and web UI.
String formatShortDate(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  const months = [
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
  final month = months[date.month - 1];
  return date.year == current.year
      ? '$month ${date.day}'
      : '$month ${date.day}, ${date.year}';
}

String formatShortClock(DateTime dt) {
  final hour24 = dt.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

String formatRelativeTimeLabel(DateTime? timestamp, {DateTime? now}) {
  if (timestamp == null) return '';
  final current = now ?? DateTime.now();
  final diff = current.difference(timestamp);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatShortDate(timestamp, now: current);
}

