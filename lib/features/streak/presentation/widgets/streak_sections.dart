import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../data/streak_models.dart';

/// Current leaderboard request state rendered by [streakLeaderboardSection].
enum StreakLeaderboardStatus { loading, ready, unavailable, failed }

/// Top summary card matching `StreakHeroCard` (64px progress ring + flame + headline).
Component streakHeroCard(StreakSummaryData summary) {
  final done = summary.todayDone;
  final hasStreak = summary.current > 0;
  final warm = hasStreak || done;
  final todayText = done
      ? 'Done today'
      : '${summary.todayMinutes.clamp(0, summary.goalMinutes)} of ${summary.goalMinutes} min today';
  final pct = (summary.progressRatio * 100).round().clamp(0, 100);
  final activeRing = done || summary.todayMinutes > 0;

  return article(
    classes: warm ? 'eduma-streak__hero is-warm' : 'eduma-streak__hero is-idle',
    [
      div(classes: 'eduma-streak__ring-wrap', [
        progress(
          classes: activeRing ? 'eduma-streak__progress-ring is-warning' : 'eduma-streak__progress-ring',
          value: pct.toDouble(),
          max: 100,
          attributes: {'aria-label': todayText, 'aria-valuetext': todayText, 'style': '--ring-pct: $pct'},
          [],
        ),
        span(
          classes: done || hasStreak ? 'eduma-streak__ring-center is-active' : 'eduma-streak__ring-center',
          attributes: {'aria-hidden': 'true'},
          [edumaIcon(done || hasStreak ? EdumaIcons.streakSolid : EdumaIcons.streak, size: 28)],
        ),
      ]),
      div(classes: 'eduma-streak__hero-copy', [
        if (hasStreak)
          div(classes: 'eduma-streak__hero-count-row', [
            strong(
              classes: done ? 'eduma-streak__hero-num is-done' : 'eduma-streak__hero-num',
              [.text('${summary.current}')],
            ),
            span(classes: 'eduma-streak__hero-unit', [.text(summary.current == 1 ? 'day streak' : 'days streak')]),
          ])
        else
          h2(classes: 'eduma-streak__hero-headline', [.text(summary.headline)]),
        p(classes: 'eduma-streak__hero-sub', [.text(summary.subline)]),
      ]),
    ],
  );
}

/// Monday -> Sunday strip matching `StreakWeekStrip` & `StreakDayDot`.
Component streakWeekStrip(StreakSummaryData summary) {
  final week = summary.effectiveWeek;
  final milestone = summary.nextMilestoneLine;
  final todayPct = (summary.progressRatio * 100).round().clamp(0, 100);

  return article(classes: 'eduma-streak__card eduma-streak__week-card', [
    div(classes: 'eduma-streak__week-head', [
      strong([.text('This week')]),
      span([.text('${summary.weekDays} of 7 days')]),
    ]),
    div(classes: 'eduma-streak__week-dots', [
      for (final day in week)
        _weekDayDot(
          day: day,
          isToday: day.date == summary.today,
          todayPct: todayPct,
        ),
    ]),
    div(classes: 'eduma-streak__divider', attributes: {'aria-hidden': 'true'}, []),
    div(classes: 'eduma-streak__week-meta', [
      span(classes: 'eduma-streak__meta-pill', [
        span(classes: 'eduma-streak__meta-icon is-primary', [edumaIcon(EdumaIcons.moon, size: 14)]),
        span([.text(summary.restLine)]),
      ]),
      if (milestone != null)
        span(classes: 'eduma-streak__meta-pill', [
          span(classes: 'eduma-streak__meta-icon is-warning', [edumaIcon(EdumaIcons.medal, size: 14)]),
          span([.text(milestone)]),
        ]),
    ]),
  ]);
}

Component _weekDayDot({
  required StreakDayEntry day,
  required bool isToday,
  required int todayPct,
}) {
  final state = day.state;
  final letterClass = [
    'eduma-streak__day-letter',
    if (isToday) state == 'studied' ? 'is-today-studied' : 'is-today',
    if (!isToday && state == 'missed') 'is-missed',
  ].join(' ');

  return div(
    classes: 'eduma-streak__day-col',
    attributes: {'aria-label': '${day.weekdayShort}: $state'},
    [
      span(classes: letterClass, [.text(day.weekdayLetter)]),
      switch (state) {
        'studied' => span(classes: 'eduma-streak__dot is-studied', [edumaIcon(EdumaIcons.streakSolid, size: 16)]),
        'rest' => span(classes: 'eduma-streak__dot is-rest', [edumaIcon(EdumaIcons.moon, size: 14)]),
        'open' => span(classes: 'eduma-streak__day-ring-wrap', [
          progress(
            classes: todayPct > 0 ? 'eduma-streak__day-ring is-warning' : 'eduma-streak__day-ring',
            value: todayPct.toDouble(),
            max: 100,
            attributes: {'aria-label': "Today's streak progress", 'style': '--ring-pct: $todayPct'},
            [],
          ),
          span(
            classes: todayPct > 0 ? 'eduma-streak__day-ring-icon is-active' : 'eduma-streak__day-ring-icon',
            attributes: {'aria-hidden': 'true'},
            [edumaIcon(todayPct >= 100 ? EdumaIcons.streakSolid : EdumaIcons.streak, size: 14)],
          ),
        ]),
        'missed' => span(classes: 'eduma-streak__dot is-missed', [edumaIcon(EdumaIcons.closePlain, size: 13)]),
        _ => span(classes: 'eduma-streak__dot is-empty', []),
      },
    ],
  );
}

/// 3-column summary capsule matching `StreakStatsRow`.
Component streakStatsRow(StreakSummaryData summary) {
  return article(classes: 'eduma-streak__stats-card', [
    _statCell('${summary.best} ${summary.best == 1 ? 'day' : 'days'}', 'Best streak'),
    div(classes: 'eduma-streak__stats-sep', attributes: {'aria-hidden': 'true'}, []),
    _statCell('${summary.weekDays} ${summary.weekDays == 1 ? 'day' : 'days'}', 'This week'),
    div(classes: 'eduma-streak__stats-sep', attributes: {'aria-hidden': 'true'}, []),
    _statCell(StreakSummaryData.formatMinutes(summary.weekMinutes), 'Study time'),
  ]);
}

Component _statCell(String value, String label) {
  return div(classes: 'eduma-streak__stat-cell', [
    strong([.text(value)]),
    span([.text(label)]),
  ]);
}

/// Right-pane (desktop) / middle-section (mobile) leaderboard matching `LeaderboardSection`.
Component streakLeaderboardSection({
  required LeaderboardScope scope,
  required StreakLeaderboardStatus status,
  required LeaderboardResponseData? data,
  required bool refreshing,
  required String? error,
  required String currentUserId,
  String currentUserName = '',
  required ValueChanged<LeaderboardScope> onSelectScope,
  required VoidCallback onRetry,
}) {
  return section(classes: 'eduma-streak__leaderboard', [
    div(classes: 'eduma-streak__board-header', [
      h2(classes: 'eduma-streak__section-title', [.text('Leaderboard')]),
      if (refreshing)
        span(classes: 'eduma-streak__syncing', [.text('Updating…')])
      else
        span(classes: 'eduma-streak__board-period', [.text('This week')]),
    ]),
    div(classes: 'eduma-streak__segments', attributes: {'role': 'tablist', 'aria-label': 'Leaderboard scope'}, [
      for (final option in LeaderboardScope.values)
        button(
          classes: option == scope ? 'eduma-streak__seg-btn is-active' : 'eduma-streak__seg-btn',
          type: ButtonType.button,
          attributes: {'role': 'tab', 'aria-selected': '${option == scope}'},
          onClick: () => onSelectScope(option),
          [.text(option.label)],
        ),
    ]),
    _leaderboardBody(
      status: status,
      data: data,
      error: error,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      onRetry: onRetry,
    ),
  ]);
}

Component _leaderboardBody({
  required StreakLeaderboardStatus status,
  required LeaderboardResponseData? data,
  required String? error,
  required String currentUserId,
  required String currentUserName,
  required VoidCallback onRetry,
}) {
  return switch (status) {
    .loading => article(classes: 'eduma-streak__board-card is-skeleton', [
      for (var i = 0; i < 4; i++)
        div(classes: 'eduma-streak__board-skel-row', [
          span(classes: 'eduma-streak__skel-rank', []),
          span(classes: 'eduma-streak__skel-avatar', []),
          span(classes: 'eduma-streak__skel-name', []),
          span(classes: 'eduma-streak__skel-metric', []),
        ]),
    ]),
    .unavailable => div(classes: 'eduma-streak__board-empty', [
      span(classes: 'eduma-streak__board-empty-icon', [edumaIcon(EdumaIcons.ranking, size: 22)]),
      strong([.text('Leaderboards are on their way')]),
      p([.text('Your streak already counts. Weekly rankings appear here once they open.')]),
    ]),
    .failed => div(classes: 'eduma-streak__board-empty', [
      span(classes: 'eduma-streak__board-empty-icon is-error', [edumaIcon(EdumaIcons.infoCircle, size: 22)]),
      strong([.text("Couldn't load the leaderboard")]),
      p([.text(error ?? 'Check your connection and try again.')]),
      button(
        classes: 'eduma-streak__retry-btn',
        type: ButtonType.button,
        onClick: onRetry,
        [.text('Try again')],
      ),
    ]),
    .ready when data == null || !data.hasRows => div(classes: 'eduma-streak__board-empty', [
      span(classes: 'eduma-streak__board-empty-icon', [edumaIcon(EdumaIcons.people, size: 22)]),
      strong([.text('No one on the board yet')]),
      p([.text('Study this week and you could be the first.')]),
    ]),
    .ready => _leaderboardRowsCard(data!, currentUserId, currentUserName),
  };
}

Component _leaderboardRowsCard(
  LeaderboardResponseData data,
  String currentUserId,
  String currentUserName,
) {
  final me = data.me;
  final showSeparateMe = me != null && !data.entries.any((e) => e.userId == me.userId);
  return article(classes: 'eduma-streak__board-card', [
    for (final entry in data.entries)
      _leaderboardRow(
        entry,
        isMe: entry.isMe || entry.userId == currentUserId,
        currentUserName: currentUserName,
      ),
    if (showSeparateMe) ...[
      div(classes: 'eduma-streak__board-gap', attributes: {'aria-hidden': 'true'}, [
        edumaIcon(EdumaIcons.moreHorizontal, size: 18),
      ]),
      _leaderboardRow(me, isMe: true, currentUserName: currentUserName),
    ],
  ]);
}

Component _leaderboardRow(
  LeaderboardEntryData entry, {
  required bool isMe,
  required String currentUserName,
}) {
  final rawName = entry.name.trim();
  final trimmedName = (isMe && (rawName.isEmpty || rawName == 'Student') && currentUserName.isNotEmpty)
      ? currentUserName
      : rawName;
  final initial = trimmedName.isEmpty ? 'S' : trimmedName[0].toUpperCase();
  return div(classes: isMe ? 'eduma-streak__board-row is-me' : 'eduma-streak__board-row', [
    span(classes: entry.rank <= 3 ? 'eduma-streak__row-rank is-top' : 'eduma-streak__row-rank', [
      .text('${entry.rank}'),
    ]),
    if (entry.avatarUrl != null)
      img(src: entry.avatarUrl!, alt: trimmedName, classes: 'eduma-streak__row-avatar')
    else
      span(classes: 'eduma-streak__row-avatar is-initial', [.text(initial)]),
    span(classes: 'eduma-streak__row-name', [.text(isMe ? '$trimmedName (you)' : trimmedName)]),
    div(classes: 'eduma-streak__row-metrics', [
      strong([.text('${entry.days} ${entry.days == 1 ? 'day' : 'days'}')]),
      span([.text(StreakSummaryData.formatMinutes(entry.minutes))]),
    ]),
  ]);
}

/// Bottom privacy toggle + rule caption matching `StreakSettingsSection`.
Component streakSettingsSection({
  required bool showLeaderboardToggle,
  required bool leaderboardVisible,
  required bool savingVisibility,
  required ValueChanged<bool> onToggleVisibility,
}) {
  const note =
      'A day counts after 5 minutes of reading, writing or practice, or one '
      'finished quiz. Miss a day and your weekly rest day keeps the streak going.';

  return section(classes: 'eduma-streak__settings', [
    if (showLeaderboardToggle) ...[
      span(classes: 'eduma-streak__group-caption', [.text('PRIVACY')]),
      div(classes: 'eduma-streak__privacy-card', [
        button(
          classes: 'eduma-streak__privacy-tile',
          type: ButtonType.button,
          disabled: savingVisibility,
          attributes: {'role': 'switch', 'aria-checked': '$leaderboardVisible'},
          onClick: () => onToggleVisibility(!leaderboardVisible),
          [
            span(classes: 'eduma-streak__privacy-icon', [edumaIcon(EdumaIcons.ranking, size: 18)]),
            div(classes: 'eduma-streak__privacy-copy', [
              strong([.text('Show me on leaderboards')]),
              span([.text("Others see your name and this week's study time.")]),
            ]),
            span(
              classes: leaderboardVisible ? 'eduma-streak__switch is-on' : 'eduma-streak__switch',
              attributes: {'aria-hidden': 'true'},
              [span(classes: 'eduma-streak__switch-thumb', [])],
            ),
          ],
        ),
      ]),
    ],
    p(classes: 'eduma-streak__rules-note', [.text(note)]),
  ]);
}
