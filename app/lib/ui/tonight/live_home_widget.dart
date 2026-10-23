import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/home_widget.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/work_text.dart';
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

  /// What was last sent, so nothing is sent when it is unchanged.
  HomeWidgetContent? _last;

  void _sync() {
    final (road,) = _road ?? (null,);
    final all = _all;
    if (_road == null || all == null) return;
    final content = homeWidgetContent(
      road: road,
      history: all,
      now: _sessions.now(),
      locale: _settings.locale,
    );
    if (content == _last) return;
    _last = content;
    unawaited(_widget.update(content));
  }

  /// The Session the widget's Start opens: one still open if the widget was
  /// out of date, whatever its Work, or else a new one with [workId].
  Future<String> start(String workId) async {
    final now = _sessions.now();
    final all = _all ?? await _sessions.watchAll().first;
    for (final r in all.reversed) {
      final s = r.at(now);
      if (s.startedAt != null && !s.stopped) return r.id;
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
HomeWidgetContent homeWidgetContent({
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
  final evenings = eveningsLeftOn(road, measured(mine, now));
  return (
    title: work.title,
    road: positionOf(l10n, locale, road),
    evenings: evenings == null ? null : l10n.widgetEvenings(evenings),
    lit: common.lit,
    dark: common.dark,
    litUntil: common.litUntil,
    button: open == null
        ? l10n.startWork(work.kind.name)
        : l10n.backToWork(work.kind.name),
    sessionId: open,
    workId: open == null ? work.id : null,
    rtl: common.rtl,
  );
}
