import 'dart:convert';

import 'package:doomread/data/repositories/auth_repository.dart'
    show defaultServer, sendsSecurely;
import 'package:doomread/data/repositories/work_repository.dart'
    show WorkRepository;
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:doomread_core/sync.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Why a sync didn't happen or didn't finish.
enum SyncFailure {
  /// Nobody is signed in; nothing was sent.
  signedOut,

  /// The server no longer knows the sign-in: it expired or was ended on
  /// another device. Whoever syncs signs this device out.
  signInEnded,

  /// A release build pointed at a plain HTTP server; nothing was sent.
  insecure,

  /// No answer, or a broken one: offline, or the server is down.
  unreachable,
}

class SyncException implements Exception {
  const SyncException(this.failure);

  final SyncFailure failure;

  @override
  String toString() => 'SyncException(${failure.name})';
}

/// Syncs the signed-in account's Session journal, Works and Notes with the
/// server (ADR-0006).
///
/// Each round sends what this device changed since the server last saw it,
/// and takes in everything the server took in after this device's cursor.
/// Journal events are only ever added, so they merge without conflicts.
/// Notes keep their last write ([deviceTakes]); so do Works, except that a
/// Work's Position keeps its own last write ([_takeWork]).
class SyncRepository {
  SyncRepository(
    this._db,
    this._client, {
    Uri? server,
    this._release = kReleaseMode,
  }) : _server = server ?? defaultServer;

  final AppDatabase _db;
  final http.Client _client;
  final Uri _server;
  final bool _release;

  /// As for signing in: a blackholed connection never errors on its own.
  static const _timeout = Duration(seconds: 12);

  static const _cursorKey = 'sync.cursor';
  static const _accountKey = 'sync.account';

  /// Fires after any local change to what sync carries, sync's own
  /// writes included.
  Stream<void> get localChanges => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_db.works, _db.sessionEvents, _db.notes]),
  );

  /// One sync round trip after another until both sides have everything,
  /// for [username]'s account with its sign-in [token].
  /// Safe to call at any time; a call while one runs waits for that one.
  Future<Result<void>> sync({
    required String username,
    required String token,
  }) => _running ??= _sync(username, token).whenComplete(() => _running = null);
  Future<Result<void>>? _running;

  Future<Result<void>> _sync(String username, String token) async {
    if (!sendsSecurely(_server, release: _release)) {
      return const Result.error(SyncException(SyncFailure.insecure));
    }
    await _startAccount(username);
    try {
      while (true) {
        final outgoing = await _outgoing();
        final since = int.parse(await _db.setting(_cursorKey) ?? '0');
        final response = await _client
            .post(
              _server.resolve('sync'),
              headers: {
                'authorization': 'Bearer $token',
                'content-type': 'application/json',
              },
              body: jsonEncode(
                SyncRequest(since: since, items: outgoing).toJson(),
              ),
            )
            .timeout(_timeout);
        if (response.statusCode == 401) {
          return const Result.error(SyncException(SyncFailure.signInEnded));
        }
        if (response.statusCode != 200) {
          return const Result.error(SyncException(SyncFailure.unreachable));
        }
        final answer = SyncResponse.fromJson(
          jsonDecode(response.body) as Map<String, Object?>,
        );
        final merged = await _db.transaction(() async {
          await _markSent(outgoing);
          final merged = await _take(answer.items);
          await _setCursor(answer.cursor);
          return merged;
        });
        if (!answer.more && outgoing.length < SyncRequest.maxItems && !merged) {
          break;
        }
      }
    } on Object {
      // Offline, a timeout, or an answer that isn't the protocol.
      return const Result.error(SyncException(SyncFailure.unreachable));
    }
    return const Result.ok(null);
  }

  /// A device signed in to another account than last time starts over: its
  /// cursor was the old account's, and every row now goes to the new one.
  Future<void> _startAccount(String username) async {
    if (await _db.setting(_accountKey) == username) return;
    await _db.transaction(() async {
      await _db
          .update(_db.works)
          .write(const WorksCompanion(syncedAt: Value(null)));
      await _db
          .update(_db.notes)
          .write(const NotesCompanion(syncedAt: Value(null)));
      await _db
          .update(_db.sessionEvents)
          .write(const SessionEventsCompanion(synced: Value(false)));
      await _setCursor(0);
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: _accountKey, value: username),
          );
    });
  }

  Future<void> _setCursor(int cursor) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _cursorKey, value: '$cursor'),
      );

  /// What the server hasn't seen yet, at most one request's worth. Events
  /// go in the order they were written, so same-second ones keep it.
  Future<List<SyncItem>> _outgoing() async {
    var room = SyncRequest.maxItems;
    final works =
        await (_db.select(_db.works)
              ..where((w) => w.syncedAt.isNotExp(w.updatedAt))
              ..limit(room))
            .get();
    room -= works.length;
    final events =
        await (_db.select(_db.sessionEvents)
              ..where((e) => e.synced.not())
              ..orderBy([
                (_) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
              ])
              ..limit(room))
            .get();
    room -= events.length;
    final notes =
        await (_db.select(_db.notes)
              ..where((n) => n.syncedAt.isNotExp(n.updatedAt))
              ..limit(room))
            .get();
    return [
      ...works.map(_workItem),
      ...events.map(_eventItem),
      ...notes.map(_noteItem),
    ];
  }

  /// Marks what the server now has, unless it changed again meanwhile.
  Future<void> _markSent(List<SyncItem> sent) async {
    for (final item in sent) {
      switch (item.kind) {
        case SyncKind.event:
          await (_db.update(_db.sessionEvents)
                ..where((e) => e.id.equals(item.id)))
              .write(const SessionEventsCompanion(synced: Value(true)));
        case SyncKind.work:
          await (_db.update(_db.works)..where(
                (w) =>
                    w.id.equals(item.id) & w.updatedAt.equals(item.updatedAt),
              ))
              .write(WorksCompanion(syncedAt: Value(item.updatedAt)));
        case SyncKind.note:
          await (_db.update(_db.notes)..where(
                (n) =>
                    n.id.equals(item.id) & n.updatedAt.equals(item.updatedAt),
              ))
              .write(NotesCompanion(syncedAt: Value(item.updatedAt)));
      }
    }
  }

  /// Takes in the server's rows, in the server's order. Returns whether a
  /// merge left a Work the server must be sent back.
  Future<bool> _take(List<SyncItem> items) async {
    var merged = false;
    for (final item in items) {
      switch (item.kind) {
        case SyncKind.event:
          final event = _eventRow(item);
          // ponytail: an event kind from a newer app version is skipped
          // for good; it comes back only after a full resync.
          if (event == null) continue;
          await _db
              .into(_db.sessionEvents)
              .insert(
                event,
                onConflict: DoUpdate(
                  (_) => const SessionEventsCompanion(synced: Value(true)),
                ),
              );
        case SyncKind.work:
          if (await _takeWork(item)) merged = true;
        case SyncKind.note:
          final note = _noteRow(item);
          // A Session has one Note; if two devices each ended it, the later
          // Note is kept, under its own id.
          final locals =
              await (_db.select(_db.notes)..where(
                    (n) =>
                        n.id.equals(item.id) |
                        n.sessionId.equals(note.sessionId.value),
                  ))
                  .get();
          if (locals.any((n) => !deviceTakes(item.updatedAt, n.updatedAt))) {
            continue;
          }
          await (_db.delete(_db.notes)..where(
                (n) =>
                    n.sessionId.equals(note.sessionId.value) &
                    n.id.equals(item.id).not(),
              ))
              .go();
          await _db.into(_db.notes).insertOnConflictUpdate(note);
      }
    }
    return merged;
  }

  /// Takes in the server's copy of a Work. The row keeps its last write,
  /// but the Position keeps its own (`positionAt`): a rename made elsewhere
  /// after this device moved the Position must not move it back. Neither
  /// is the highest page wins, so a Position can still be corrected down.
  ///
  /// When each side has the later half, the merge is a new write, sent
  /// back so the server and every other device get it. It is stamped a
  /// second after both halves: rows keep whole seconds, and on a tie the
  /// server keeps what it has. Returns whether there was such a merge.
  Future<bool> _takeWork(SyncItem item) async {
    final incoming = _workRow(item);
    final local = await (_db.select(
      _db.works,
    )..where((w) => w.id.equals(item.id))).getSingleOrNull();
    if (local == null) {
      await _db.into(_db.works).insert(incoming);
      return false;
    }
    final rowFromServer = deviceTakes(item.updatedAt, local.updatedAt);
    final localPositionAt = local.positionAt ?? local.updatedAt;
    final (
      position,
      positionAt,
    ) = deviceTakes(incoming.positionAt.value!, localPositionAt)
        ? (incoming.position.value, incoming.positionAt.value!)
        : (local.position, localPositionAt);
    if (rowFromServer && position == incoming.position.value) {
      await _db.into(_db.works).insertOnConflictUpdate(incoming);
      return false;
    }
    if (!rowFromServer && position == local.position) return false;
    final later = item.updatedAt.isAfter(local.updatedAt)
        ? item.updatedAt
        : local.updatedAt;
    final row = rowFromServer ? incoming : local.toCompanion(false);
    await _db
        .into(_db.works)
        .insertOnConflictUpdate(
          row.copyWith(
            position: Value(position),
            positionAt: Value(positionAt),
            updatedAt: Value(later.add(const Duration(seconds: 1))),
            syncedAt: const Value(null),
          ),
        );
    return true;
  }

  // How each row travels. The server never reads `data`, so a Work can
  // gain fields by changing only these two Work functions.

  static SyncItem _workItem(WorkRow w) => SyncItem(
    kind: SyncKind.work,
    id: w.id,
    updatedAt: w.updatedAt,
    data: {
      'title': w.title,
      'author': w.author,
      'kind': w.kind.name,
      'totalPages': w.totalPages,
      'checkpoints': WorkRepository.toWork(w).checkpoints,
      'position': w.position,
      'positionAt': (w.positionAt ?? w.updatedAt).microsecondsSinceEpoch,
    },
  );

  static WorksCompanion _workRow(SyncItem i) => WorksCompanion.insert(
    id: i.id,
    title: i.data['title']! as String,
    author: i.data['author']! as String,
    // Devices from before kinds only had paper books.
    kind: Value(
      WorkKind.values.asNameMap()[i.data['kind']] ?? WorkKind.paperBook,
    ),
    totalPages: i.data['totalPages']! as int,
    checkpoints: (i.data['checkpoints']! as List<Object?>).join(','),
    position: Value(i.data['position']! as int),
    // Devices from before positionAt moved the Position with every write.
    positionAt: Value(switch (i.data['positionAt']) {
      final int us => DateTime.fromMicrosecondsSinceEpoch(us, isUtc: true),
      _ => i.updatedAt,
    }),
    updatedAt: i.updatedAt,
    syncedAt: Value(i.updatedAt),
  );

  static SyncItem _eventItem(SessionEventRow e) => SyncItem(
    kind: SyncKind.event,
    id: e.id,
    updatedAt: e.at,
    data: {'sessionId': e.sessionId, 'workId': e.workId, 'kind': e.kind.name},
  );

  static SessionEventsCompanion? _eventRow(SyncItem i) {
    final kind = SessionEventKind.values.asNameMap()[i.data['kind']];
    if (kind == null) return null;
    return SessionEventsCompanion.insert(
      id: i.id,
      sessionId: i.data['sessionId']! as String,
      workId: i.data['workId']! as String,
      kind: kind,
      at: i.updatedAt,
      synced: const Value(true),
    );
  }

  static SyncItem _noteItem(NoteRow n) => SyncItem(
    kind: SyncKind.note,
    id: n.id,
    updatedAt: n.updatedAt,
    data: {
      'sessionId': n.sessionId,
      'workId': n.workId,
      'fromPage': n.fromPage,
      'toPage': n.toPage,
      'body': n.body,
    },
  );

  static NotesCompanion _noteRow(SyncItem i) => NotesCompanion.insert(
    id: i.id,
    sessionId: i.data['sessionId']! as String,
    workId: i.data['workId']! as String,
    fromPage: i.data['fromPage']! as int,
    toPage: i.data['toPage']! as int,
    body: i.data['body']! as String,
    updatedAt: i.updatedAt,
    syncedAt: Value(i.updatedAt),
  );
}
