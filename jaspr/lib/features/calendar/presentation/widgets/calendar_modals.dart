import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../data/calendar_models.dart';

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

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Modal matching `BrowseAllEventsSheet` in `../eduma`: lists all events
/// sorted chronologically with `All | Notebooks | Pages | Other` filter chips.
Component browseAllEventsModal({
  required bool open,
  required List<CalendarEvent> allEvents,
  required CalendarEventKind? selectedKind,
  required ValueChanged<CalendarEventKind?> onSelectKind,
  required ValueChanged<CalendarEvent> onSelectEvent,
  required VoidCallback onClose,
}) {
  if (!open) return div([]);

  final sorted = [...allEvents]..sort((first, second) => first.startTime.compareTo(second.startTime));
  final filtered = selectedKind == null
      ? sorted
      : sorted.where((e) => CalendarScheduleLogic.kindOf(e) == selectedKind).toList();

  return div(classes: 'eduma-modal-backdrop', [
    button(
      classes: 'eduma-modal-backdrop__scrim',
      type: ButtonType.button,
      attributes: {'aria-label': 'Close all scheduled events'},
      onClick: onClose,
      [],
    ),
    section(
      classes: 'eduma-modal-sheet eduma-cal-modal',
      attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': 'All Scheduled Events'},
      [
        header(classes: 'eduma-cal-modal__head', [
          div([
            h2([.text('All Scheduled Events')]),
            p([.text('${sorted.length} ${sorted.length == 1 ? 'scheduled event' : 'scheduled events'}')]),
          ]),
          div(classes: 'eduma-cal-modal__head-right', [
            span(classes: 'eduma-cal-modal__badge-icon', [edumaIcon(EdumaIcons.calendar, size: 19)]),
            button(
              classes: 'eduma-modal-close',
              type: ButtonType.button,
              attributes: {'aria-label': 'Close'},
              onClick: onClose,
              [edumaIcon(EdumaIcons.closePlain, size: 18)],
            ),
          ]),
        ]),
        div(classes: 'eduma-cal-modal__chips', [
          _kindChip('All', selected: selectedKind == null, onTap: () => onSelectKind(null)),
          _kindChip('Notebooks', selected: selectedKind == .notebook, onTap: () => onSelectKind(.notebook)),
          _kindChip('Pages', selected: selectedKind == .page, onTap: () => onSelectKind(.page)),
          _kindChip('Other', selected: selectedKind == .other, onTap: () => onSelectKind(.other)),
        ]),
        if (filtered.isEmpty)
          div(classes: 'eduma-cal-modal__empty', [
            p([.text('No events of this kind')]),
          ])
        else
          div(classes: 'eduma-cal-modal__list', [
            for (final event in filtered) _browseEventRow(event, onTap: () => onSelectEvent(event)),
          ]),
      ],
    ),
  ]);
}

Component _kindChip(String label, {required bool selected, required VoidCallback onTap}) => button(
  classes: selected ? 'eduma-pill-button is-active' : 'eduma-pill-button',
  type: ButtonType.button,
  onClick: onTap,
  [.text(label)],
);

Component _browseEventRow(CalendarEvent event, {required VoidCallback onTap}) {
  final kind = CalendarScheduleLogic.kindOf(event);
  final tag = switch (kind) {
    .notebook => 'Notebook',
    .page => 'Page',
    .space => 'Space',
    .other => null,
  };
  final recurring = event.recurrence?.isRecurring ?? false;
  final dateLabel =
      '${_shortWeekdays[(event.startTime.weekday - 1).clamp(0, 6)]}, ${_shortMonths[event.startTime.month - 1]} ${event.startTime.day}';
  final timeLabel = '${formatShortClock(event.startTime)} – ${formatShortClock(event.endTime)}';

  return button(classes: 'eduma-cal-browse-row', type: ButtonType.button, onClick: onTap, [
    span(classes: 'eduma-cal-browse-row__bar', attributes: {'aria-hidden': 'true'}, []),
    div(classes: 'eduma-cal-browse-row__body', [
      div(classes: 'eduma-cal-browse-row__top', [
        strong([.text(event.title)]),
        if (recurring)
          span(classes: 'eduma-cal-browse-row__repeat', [edumaIcon(EdumaIcons.refresh, size: 12)]),
      ]),
      if (event.subject.isNotEmpty) span(classes: 'eduma-cal-browse-row__subject', [.text(event.subject)]),
      div(classes: 'eduma-cal-browse-row__meta', [
        if (tag != null) span(classes: 'eduma-cal-browse-row__tag', [.text(tag)]),
        span([.text('$dateLabel · $timeLabel')]),
      ]),
    ]),
    span(classes: 'eduma-cal-browse-row__chev', [edumaIcon(EdumaIcons.chevronRight, size: 15)]),
  ]);
}

/// Event detail modal matching `EventDetailSheet` in `../eduma`.
Component calendarEventDetailModal({
  required CalendarEvent? event,
  required bool deleting,
  required VoidCallback onClose,
  required ValueChanged<CalendarEvent> onEdit,
  required ValueChanged<CalendarEvent> onDelete,
}) {
  if (event == null) return div([]);
  final kind = CalendarScheduleLogic.kindOf(event);
  final kindLabel = switch (kind) {
    .notebook => 'NOTEBOOK',
    .page => 'PAGE',
    .space => 'SPACE',
    .other => 'EVENT',
  };
  final kindIcon = switch (kind) {
    .notebook => EdumaIcons.playSolid,
    .page => EdumaIcons.note,
    .space => EdumaIcons.people,
    .other => EdumaIcons.calendar,
  };
  final dateLabel =
      '${_shortWeekdays[(event.startTime.weekday - 1).clamp(0, 6)]}, ${_shortMonths[event.startTime.month - 1]} ${event.startTime.day}, ${event.startTime.year}';
  final timeLabel = '${formatShortClock(event.startTime)} – ${formatShortClock(event.endTime)}';
  final recurringLabel = (event.recurrence?.isRecurring ?? false) ? event.recurrence!.label : null;

  return div(classes: 'eduma-modal-backdrop', [
    button(
      classes: 'eduma-modal-backdrop__scrim',
      type: ButtonType.button,
      attributes: {'aria-label': 'Close event details'},
      onClick: onClose,
      [],
    ),
    section(
      classes: 'eduma-modal-sheet eduma-cal-detail-modal',
      attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': event.title},
      [
        div(classes: 'eduma-cal-detail__top', [
          span(classes: 'eduma-cal-detail__kind-badge', [
            edumaIcon(kindIcon, size: 13),
            span([.text(kindLabel)]),
          ]),
          button(
            classes: 'eduma-modal-close',
            type: ButtonType.button,
            attributes: {'aria-label': 'Close'},
            onClick: onClose,
            [edumaIcon(EdumaIcons.closePlain, size: 18)],
          ),
        ]),
        h2(classes: 'eduma-cal-detail__title', [.text(event.title)]),
        if (event.subject.isNotEmpty) p(classes: 'eduma-cal-detail__subject', [.text(event.subject)]),
        div(classes: 'eduma-cal-detail__time-card', [
          div(classes: 'eduma-cal-detail__time-row', [
            span(classes: 'eduma-cal-detail__time-icon', [edumaIcon(EdumaIcons.clock, size: 18)]),
            div([
              strong([.text(dateLabel)]),
              p([.text('$timeLabel · ${event.durationMinutes} min')]),
            ]),
          ]),
          if (recurringLabel != null)
            span(classes: 'eduma-cal-detail__recurrence-pill', [
              edumaIcon(EdumaIcons.refresh, size: 12),
              span([.text(recurringLabel)]),
            ]),
        ]),
        if (event.description case final notes? when notes.trim().isNotEmpty)
          div(classes: 'eduma-cal-detail__notes', [
            span(classes: 'eduma-cal-detail__notes-label', [.text('Notes')]),
            p([.text(notes)]),
          ]),
        div(classes: 'eduma-cal-detail__actions', [
          if (event.spaceId case final spaceId? when spaceId.trim().isNotEmpty)
            edumaLink(
              to: '/spaceDetail?id=${Uri.encodeQueryComponent(spaceId)}',
              classes: 'eduma-desktop-pill eduma-desktop-pill--primary eduma-cal-detail__cta',
              children: [edumaIcon(EdumaIcons.layer, size: 16), span([.text('Open space')])],
            ),
          button(
            classes: 'eduma-desktop-pill eduma-desktop-pill--outlined',
            type: ButtonType.button,
            disabled: deleting,
            onClick: () => onEdit(event),
            [
              edumaIcon(EdumaIcons.edit, size: 16),
              span([.text('Edit')]),
            ],
          ),
          button(
            classes: 'eduma-cal-detail__delete-btn',
            type: ButtonType.button,
            disabled: deleting,
            onClick: () => onDelete(event),
            [
              edumaIcon(EdumaIcons.delete, size: 16),
              span([.text(deleting ? 'Removing…' : 'Delete session')]),
            ],
          ),
        ]),
      ],
    ),
  ]);
}
