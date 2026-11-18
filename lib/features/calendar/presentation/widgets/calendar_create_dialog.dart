import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../auth/data/auth_api.dart';
import '../../../main/data/main_space.dart';
import '../../../main/logic/main_actions.dart';
import '../../../main/presentation/widgets/main_home_icons.dart';
import '../../../main/presentation/widgets/web_dialog_helper.dart';
import '../../logic/calendar_actions.dart';

/// Native modal `<dialog>` for scheduling a new event (`POST /events`).
class CalendarCreateDialog extends StatefulComponent {
  const CalendarCreateDialog({
    required this.open,
    required this.initialDate,
    this.editingEvent,
    required this.onClose,
    required this.onCreated,
    super.key,
  });

  final bool open;
  final DateTime initialDate;
  final CalendarEvent? editingEvent;
  final VoidCallback onClose;
  final ValueChanged<CalendarEvent?> onCreated;

  @override
  State<CalendarCreateDialog> createState() => _CalendarCreateDialogState();
}

class _CalendarCreateDialogState extends State<CalendarCreateDialog> {
  static const _dialogId = 'eduma-create-event-dialog';

  String _title = '';
  String _subject = '';
  String _description = '';
  String _dateValue = '';
  String _startTimeValue = '09:00';
  String _endTimeValue = '10:00';
  String _spaceId = '';
  List<MainSpace> _spaces = const [];
  CalendarRecurrenceFrequency _repeat = .none;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _syncInitialDate();
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  @override
  void didUpdateComponent(covariant CalendarCreateDialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!oldComponent.open && component.open) {
      setState(() {
        final editing = component.editingEvent;
        if (editing != null) {
          _title = editing.title;
          _subject = editing.subject;
          _description = editing.description ?? '';
          _dateValue = calendarDayKey(editing.startTime);
          _startTimeValue = _clockValue(editing.startTime);
          _endTimeValue = _clockValue(editing.endTime);
          _spaceId = editing.spaceId ?? '';
          _repeat = editing.recurrence?.frequency ?? .none;
        } else {
          _title = '';
          _subject = '';
          _description = '';
          _syncInitialDate();
          _spaceId = '';
          _repeat = .none;
        }
        _submitting = false;
        _error = null;
      });
      unawaited(_ensureSpacesLoaded());
    }
    WebDialogHelper.syncOpen(_dialogId, component.open);
  }

  Future<void> _ensureSpacesLoaded() async {
    final cached = EdumaMemoryCache.instance.home?.spaces;
    if (cached != null && cached.isNotEmpty) {
      if (mounted) setState(() => _spaces = cached);
      return;
    }
    try {
      final page = await MainActions.loadSpaces(page: 1);
      if (mounted) setState(() => _spaces = page.spaces);
    } catch (_) {}
  }

  static String _clockValue(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _syncInitialDate() {
    _dateValue = calendarDayKey(component.initialDate);
    final hour = component.initialDate.hour;
    if (hour > 0 && hour < 23) {
      _startTimeValue = '${hour.toString().padLeft(2, '0')}:00';
      _endTimeValue = '${(hour + 1).clamp(1, 23).toString().padLeft(2, '0')}:00';
    } else {
      _startTimeValue = '09:00';
      _endTimeValue = '10:00';
    }
  }

  void _dismiss() {
    if (_submitting) return;
    WebDialogHelper.resetReturnValue(_dialogId);
    component.onClose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final cleanTitle = _title.trim();
    if (cleanTitle.isEmpty) {
      setState(() => _error = 'Enter a session title.');
      return;
    }

    final start = DateTime.tryParse('$_dateValue $_startTimeValue:00');
    final end = DateTime.tryParse('$_dateValue $_endTimeValue:00');
    if (start == null || end == null) {
      setState(() => _error = 'Choose a valid date and time range.');
      return;
    }
    if (!end.isAfter(start)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final input = CreateCalendarEventInput(
        title: cleanTitle,
        subject: _subject,
        description: _description,
        startTime: start,
        endTime: end,
        recurrence: _repeat == .none ? null : CalendarEventRecurrence(frequency: _repeat),
        spaceId: _spaceId.trim().isEmpty ? null : _spaceId.trim(),
      );
      final editing = component.editingEvent;
      final saved = editing != null
          ? await CalendarActions.updateEvent(editing.id, input)
          : await CalendarActions.createEvent(input);
      if (!mounted) return;
      WebDialogHelper.resetReturnValue(_dialogId);
      component.onClose();
      component.onCreated(saved);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not schedule this session. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Component build(BuildContext context) => dialog(
    id: _dialogId,
    classes: 'eduma-modal',
    attributes: {
      ...WebDialogHelper.openAttr(component.open),
      'closedby': 'any',
      'aria-labelledby': 'eduma-create-event-title',
    },
    events: {
      'close': (_) {
        if (component.open) _dismiss();
      },
    },
    [
      div(classes: 'eduma-modal__header', [
        div(classes: 'eduma-modal__title', [
          h2(
            id: 'eduma-create-event-title',
            [.text(component.editingEvent != null ? 'Edit event' : 'Schedule study event')],
          ),
          p([
            .text(
              component.editingEvent != null
                  ? 'Update the title, time range, or repeat schedule.'
                  : 'Block focused study time and keep your streak on track.',
            ),
          ]),
        ]),
        button(
          classes: 'eduma-modal__close',
          type: ButtonType.button,
          attributes: {'aria-label': 'Close dialog'},
          onClick: _dismiss,
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
              label(htmlFor: 'eduma-event-title', [.text('Session title')]),
              input<String>(
                id: 'eduma-event-title',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _title,
                disabled: _submitting,
                attributes: {
                  'placeholder': 'e.g. Organic Chemistry Practice',
                  'maxlength': '100',
                  'autofocus': 'true',
                },
                onInput: (value) => setState(() {
                  _title = value;
                  _error = null;
                }),
              ),
            ]),
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'eduma-event-subject', [.text('Subject (optional)')]),
              input<String>(
                id: 'eduma-event-subject',
                classes: 'eduma-modal__input',
                type: InputType.text,
                value: _subject,
                disabled: _submitting,
                attributes: {'placeholder': 'e.g. Chemistry', 'maxlength': '60'},
                onInput: (value) => setState(() => _subject = value),
              ),
            ]),
            div(classes: 'eduma-calendar__dialog-row', [
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-event-date', [.text('Date')]),
                input<String>(
                  id: 'eduma-event-date',
                  classes: 'eduma-modal__input',
                  type: InputType.date,
                  value: _dateValue,
                  disabled: _submitting,
                  onInput: (value) => setState(() {
                    _dateValue = value;
                    _error = null;
                  }),
                ),
              ]),
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-event-start', [.text('Start')]),
                input<String>(
                  id: 'eduma-event-start',
                  classes: 'eduma-modal__input',
                  type: InputType.time,
                  value: _startTimeValue,
                  disabled: _submitting,
                  onInput: (value) => setState(() {
                    _startTimeValue = value;
                    _error = null;
                  }),
                ),
              ]),
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-event-end', [.text('End')]),
                input<String>(
                  id: 'eduma-event-end',
                  classes: 'eduma-modal__input',
                  type: InputType.time,
                  value: _endTimeValue,
                  disabled: _submitting,
                  onInput: (value) => setState(() {
                    _endTimeValue = value;
                    _error = null;
                  }),
                ),
              ]),
            ]),
            if (_spaces.isNotEmpty)
              div(classes: 'eduma-modal__field', [
                label(htmlFor: 'eduma-event-space', [.text('Space (optional)')]),
                select(
                  id: 'eduma-event-space',
                  classes: 'eduma-modal__input',
                  disabled: _submitting,
                  onChange: (values) => setState(() => _spaceId = values.isEmpty ? '' : values.first),
                  [
                    option(value: '', selected: _spaceId.isEmpty, [.text('Personal / None')]),
                    for (final s in _spaces) option(value: s.id, selected: _spaceId == s.id, [.text(s.title)]),
                  ],
                ),
              ]),
            div(classes: 'eduma-modal__field', [
              label([.text('Repeat')]),
              div(classes: 'eduma-filter-pills', [
                for (final freq in CalendarRecurrenceFrequency.values)
                  button(
                    classes: _repeat == freq ? 'eduma-pill-button is-active' : 'eduma-pill-button',
                    type: ButtonType.button,
                    onClick: () => setState(() => _repeat = freq),
                    [.text(CalendarEventRecurrence(frequency: freq).label)],
                  ),
              ]),
            ]),
            div(classes: 'eduma-modal__field', [
              label(htmlFor: 'eduma-event-notes', [.text('Notes (optional)')]),
              textarea(
                id: 'eduma-event-notes',
                classes: 'eduma-modal__textarea',
                disabled: _submitting,
                attributes: {
                  'placeholder': 'Topics, chapters, or goals for this session',
                  'maxlength': '400',
                },
                onInput: (value) => setState(() => _description = value),
                [.text(_description)],
              ),
            ]),
            if (_error case final message?)
              p(classes: 'eduma-modal__error', attributes: {'role': 'alert'}, [.text(message)]),
          ]),
          div(classes: 'eduma-modal__footer', [
            button(
              classes: 'eduma-modal__btn',
              type: ButtonType.button,
              disabled: _submitting,
              onClick: _dismiss,
              [.text('Cancel')],
            ),
            button(
              classes: 'eduma-modal__btn eduma-modal__btn--primary',
              type: ButtonType.submit,
              disabled: _submitting,
              [
                .text(
                  _submitting ? 'Saving…' : (component.editingEvent != null ? 'Save changes' : 'Save event'),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}
