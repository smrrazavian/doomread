import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/home_widget.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// Keeps the home screen widget in step with the current Work's Road, the
/// journal and the app language, and starts the Session its button asks for.
class LiveHomeWidget {
  LiveHomeWidget(this._works, this._sessions, this._settings, this._widget) {
    _subs = [
      _works.watchCurrent().listen((r) {
        _road = (r,);
        _sync();
      }),
      _sessions.watchAll().listen((all) {
        _all = all;
        _sync();
      }),
    ];
    _settings.addListener(_sync);
  }

  final WorkRepository _works;
  final SessionRepository _sessions;
  final SettingsViewModel _settings;
  final HomeWidget _widget;
  late final List<StreamSubscription<Object?>> _subs;

  /// The current Work's Road once loaded (a record, since null means none).
  (Road?,)? _road;
  List<SessionRecord>? _all;

  /// What was last sent, so an unchanged state sends nothing.
  HomeWidgetState? _last;

  void _sync() {
    final (road,) = _road ?? (null,);
    final all = _all;
    if (_road == null || all == null) return;
    final state = homeWidgetState(
      road: road,
      history: all,
      now: _sessions.now(),
      locale: _settings.locale,
    );
    if (state == _last) return;
    _last = state;
    unawaited(_widget.update(state));
  }

  /// The Session the widget's Start opens: the one still open with [workId]
  /// if the widget was out of date, or a new one.
  Future<String> start(String workId) async {
    final now = _sessions.now();
    final all = _all ?? await _sessions.watchAll().first;
    for (final r in all.reversed) {
      if (r.road.work.id == workId && !r.at(now).stopped) return r.id;
    }
    return await _sessions.start(workId);
  }

  void dispose() {
    _settings.removeListener(_sync);
    for (final s in _subs) {
      unawaited(s.cancel());
    }
  }
}

/// What the widget shows for [road], the current Work, given every Session
/// so far, in [locale].
HomeWidgetState homeWidgetState({
  required Road? road,
  required List<SessionRecord> history,
  required DateTime now,
  required Locale locale,
}) {
  final l10n = lookupAppLocalizations(locale);
  final lang = locale.languageCode;
  final tonight = eveningOf(now);
  final lit = ReadingWeek(
    now: now,
    firstDay: firstDayOfWeek(lang),
    sessionStarts: [for (final r in history) ?r.at(now).startedAt],
  ).isLit(tonight);
  final common = (
    lit: l10n.widgetLit,
    dark: l10n.widgetDark,
    // The evening turns over at 4 in the morning (see eveningOf).
    litUntil: lit
        ? DateTime(tonight.year, tonight.month, tonight.day + 1, 4)
        : null,
    rtl: Bidi.isRtlLanguage(lang),
  );
  if (road == null) {
    return (
      title: l10n.appTitle,
      road: l10n.tonightEmpty,
      evenings: null,
      lit: common.lit,
      dark: common.dark,
      litUntil: common.litUntil,
      button: l10n.tonightAddBook,
      sessionId: null,
      workId: null,
      rtl: common.rtl,
    );
  }

  final work = road.work;
  final mine = history.where((r) => r.road.work.id == work.id);
  final open = mine.where((r) => !r.at(now).stopped).lastOrNull?.id;
  // ponytail: the same pace as TonightViewModel.evenings; share one once
  // #12 brings Works measured in episodes and minutes.
  final evenings = eveningsLeft(
    pagesLeft: work.totalPages - road.position,
    sittings: [
      for (final r in mine)
        if ((r.pages, r.at(now).startedAt) case (final p?, final at?))
          (startedAt: at, pages: p.to - p.from),
    ],
  );
  return (
    title: work.title,
    road: roadText(road, l10n),
    evenings: evenings == null ? null : l10n.widgetEvenings(evenings),
    lit: common.lit,
    dark: common.dark,
    litUntil: common.litUntil,
    button: open == null ? l10n.startReading : l10n.backToReading,
    sessionId: open,
    workId: open == null ? work.id : null,
    rtl: common.rtl,
  );
}

/// The Position on the Road in words: "Page 156 of 245".
String roadText(Road road, AppLocalizations l10n) =>
    l10n.pageOf(road.position, road.work.totalPages);
