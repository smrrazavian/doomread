import 'dart:convert';

import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/sync_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/domain/use_cases/sync_use_case.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/accounts.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:doomread_core/sync.dart';
import 'package:doomread_server/server.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;

/// One phone or laptop: its own database and clock, talking to the shared
/// in-memory server unless it is [offline].
class Device {
  Device(shelf.Handler server, {required this.now}) {
    final client = MockClient((request) async {
      if (offline) throw http.ClientException('offline', request.url);
      requests++;
      final response = await server(
        shelf.Request(
          request.method,
          request.url,
          headers: request.headers,
          body: request.bodyBytes,
        ),
      );
      return http.Response.bytes(
        await response.read().expand((c) => c).toList(),
        response.statusCode,
        headers: response.headers,
      );
    });
    auth = AuthRepository(db, client, server: _url);
    syncer = SyncRepository(db, client, server: _url);
    works = WorkRepository(db, clock: () => now);
    syncing = SyncUseCase(auth, syncer, works);
    sessions = SessionRepository(db, clock: () => now);
  }

  static final Uri _url = Uri.parse('http://doomread.test/');

  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  DateTime now;
  bool offline = false;
  int requests = 0;
  late final AuthRepository auth;
  late final SyncRepository syncer;
  late final WorkRepository works;
  late final SyncUseCase syncing;
  late final SessionRepository sessions;

  Future<Result<void>> sync() => syncing();

  Future<SessionRecord> last() async => (await sessions.watchAll().first).last;

  /// The Longest stretch and current Position, as the screens show them.
  Future<(Duration, int?)> numbers() async => (
    longestStretch((await sessions.watchAll().first).map((r) => r.at(now))),
    (await works.watchCurrent().first)?.position,
  );
}

void main() {
  // Each device has its own in-memory database; they never share one.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late shelf.Handler server;
  late Device a;
  late Device b;
  final evening = DateTime(2026, 10, 22, 21);
  const sara = Credentials(username: 'sara', password: 'correct horse');

  setUp(() async {
    // Both devices share the faked secure storage; they sign in to the
    // same account, so only the token differs, and either works.
    FlutterSecureStorage.setMockInitialValues({});
    server = doomreadServer(
      InMemoryAccountStore(),
      sync: InMemorySyncStore(),
      passwords: const Passwords.cheapForTests(),
    );
    a = Device(server, now: evening);
    b = Device(server, now: evening);
    expect(await a.auth.signUp(sara), isA<Ok<String>>());
    expect(await b.auth.signIn(sara), isA<Ok<String>>());
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  Future<void> syncAll(List<Device> order) async {
    for (final d in order) {
      d.offline = false;
      expect(await d.sync(), isA<Ok<void>>());
    }
  }

  /// A Session on [d] that ends at page [to], [minute]s into the evening.
  Future<void> read(
    Device d,
    String id, {
    required int to,
    required int minute,
    bool offline = false,
  }) async {
    d
      ..offline = offline
      ..now = evening.add(Duration(minutes: minute));
    await d.sessions.start(id);
    await d.sessions.add(await d.last(), SessionEventKind.stop);
    await d.sessions.end(await d.last(), page: to);
  }

  Future<String> addDune(Device d) => d.works.add(
    title: 'Dune',
    author: 'Frank Herbert',
    totalPages: 412,
    checkpoints: const [40, 80],
  );

  test('a Session recorded offline on one device shows up on the other, '
      'with the same Longest stretch and Position', () async {
    a.offline = true;
    final workId = await addDune(a);
    await a.sessions.start(workId);
    a.now = a.now.add(const Duration(minutes: 12));
    await a.sessions.add(await a.last(), SessionEventKind.pause);
    // A double tap: two Pauses in the same second, then the rest.
    await a.sessions.add(await a.last(), SessionEventKind.pause);
    a.now = a.now.add(const Duration(minutes: 2));
    await a.sessions.add(await a.last(), SessionEventKind.resume);
    a.now = a.now.add(const Duration(minutes: 7));
    await a.sessions.add(await a.last(), SessionEventKind.stop);
    await a.sessions.end(await a.last(), page: 40, note: 'Paul leaves.');

    expect(await a.sync(), isA<Error<void>>());
    a.offline = false;
    expect(await a.sync(), isA<Ok<void>>());
    expect(await b.sync(), isA<Ok<void>>());

    final there = await b.last();
    expect(there.id, (await a.last()).id);
    expect(there.road.work.title, 'Dune');
    expect(there.road.work.checkpoints, [40, 80]);
    expect(
      there.events.map((e) => e.kind),
      (await a.last()).events.map((e) => e.kind),
    );
    expect(there.note, 'Paul leaves.');
    expect(there.pages, (from: 0, to: 40));

    b.now = a.now;
    expect(await b.numbers(), (const Duration(minutes: 12), 40));
    expect(await b.numbers(), await a.numbers());
  });

  test(
    "a podcast's kind and timestamp Position reach the other device",
    () async {
      final id = await a.works.add(
        title: 'Radio Marz',
        author: '',
        totalPages: 9660,
        checkpoints: const [2550, 4500],
        kind: WorkKind.podcast,
      );
      await a.sessions.start(id);
      a.now = a.now.add(const Duration(minutes: 20));
      await a.sessions.add(await a.last(), SessionEventKind.stop);
      await a.sessions.end(await a.last(), page: 4340);
      expect(await a.sync(), isA<Ok<void>>());
      expect(await b.sync(), isA<Ok<void>>());

      final there = (await b.works.watchCurrent().first)!;
      expect(there.work.kind, WorkKind.podcast);
      expect(there.work.checkpoints, [2550, 4500]);
      expect(there.position, 4340);
    },
  );

  test('Sessions recorded on both devices meet on both', () async {
    final workId = await addDune(a);
    await a.sync();
    await b.sync();
    await a.sessions.start(workId);
    b.now = evening.add(const Duration(days: 1));
    await b.sessions.start(workId);

    for (final d in [a, b, a]) {
      expect(await d.sync(), isA<Ok<void>>());
    }
    for (final d in [a, b]) {
      expect(await d.sessions.watchAll().first, hasLength(2));
    }
  });

  group('conflicting edits to a Work keep the last write', () {
    late String id;
    setUp(() async {
      id = await addDune(a);
      await a.sync();
      await b.sync();
    });

    Future<void> rename(Device d, String title, int minute) {
      d
        ..offline = true
        ..now = evening.add(Duration(minutes: minute));
      return d.works.edit(
        id,
        title: title,
        author: 'Frank Herbert',
        totalPages: 412,
        checkpoints: const [40, 80],
      );
    }

    Future<List<String>> titles() async => [
      for (final d in [a, b]) (await d.works.watchAll().first).single.title,
    ];

    test('when the earlier edit syncs first', () async {
      await rename(a, 'Dune (earlier)', 1);
      await rename(b, 'Dune (later)', 2);
      await syncAll([a, b, a]);
      expect(await titles(), ['Dune (later)', 'Dune (later)']);
    });

    test('when the later edit syncs first', () async {
      await rename(a, 'Dune (earlier)', 1);
      await rename(b, 'Dune (later)', 2);
      await syncAll([b, a, b]);
      expect(await titles(), ['Dune (later)', 'Dune (later)']);
    });

    test(
      'in the same second, both keep what reached the server first',
      () async {
        await rename(a, 'Dune (a)', 1);
        await rename(b, 'Dune (b)', 1);
        await syncAll([b, a, b]);
        expect(await titles(), ['Dune (b)', 'Dune (b)']);
      },
    );

    test('an edit made while a sync is out is still sent', () async {
      await rename(a, 'Dune (sent)', 1);
      a.offline = false;
      await a.sync();
      await rename(a, 'Dune (after)', 2);
      await syncAll([a, b]);
      expect(await titles(), ['Dune (after)', 'Dune (after)']);
    });
  });

  group('the Position keeps its own last write', () {
    late String id;
    setUp(() async {
      id = await addDune(a);
      await read(a, id, to: 100, minute: 1);
      await syncAll([a, b]);
    });

    Future<void> rename(Device d, int minute) {
      d
        ..offline = true
        ..now = evening.add(Duration(minutes: minute));
      return d.works.edit(
        id,
        title: 'Dune (renamed)',
        author: 'Frank Herbert',
        totalPages: 412,
        checkpoints: const [40, 80],
      );
    }

    Future<List<(String, int)>> both() async => [
      for (final d in [a, b])
        (
          (await d.works.watchAll().first).single.title,
          (await d.works.watchRoad(id).first)!.position,
        ),
    ];

    // A ends a Session at p.150; B, still at p.100, renames the Work later.
    test('through a later rename, when the reader syncs first', () async {
      await read(a, id, to: 150, minute: 2, offline: true);
      await rename(b, 3);
      await syncAll([a, b, a, b]);
      expect(await both(), [('Dune (renamed)', 150), ('Dune (renamed)', 150)]);
    });

    test('through a later rename, when the renamer syncs first', () async {
      await read(a, id, to: 150, minute: 2, offline: true);
      await rename(b, 3);
      await syncAll([b, a, b]);
      expect(await both(), [('Dune (renamed)', 150), ('Dune (renamed)', 150)]);
    });

    test(
      'an app from before positionAt moved it with its last write',
      () async {
        final old = SyncItem(
          kind: SyncKind.work,
          id: id,
          updatedAt: evening.add(const Duration(minutes: 5)).toUtc(),
          data: const {
            'title': 'Dune',
            'author': 'Frank Herbert',
            'kind': 'paperBook',
            'totalPages': 412,
            'checkpoints': [40, 80],
            'position': 200,
          },
        );
        final response = await server(
          shelf.Request(
            'POST',
            Device._url.resolve('sync'),
            headers: {
              'authorization': 'Bearer ${await a.auth.token()}',
              'content-type': 'application/json',
            },
            body: jsonEncode(SyncRequest(since: 0, items: [old]).toJson()),
          ),
        );
        expect(response.statusCode, 200);
        await syncAll([b]);
        expect((await b.works.watchRoad(id).first)!.position, 200);
      },
    );

    test('a later, lower Position still wins', () async {
      await read(a, id, to: 150, minute: 2, offline: true);
      // B never saw p.150, and moves the Position back to 120 later on.
      await read(b, id, to: 120, minute: 3, offline: true);
      await syncAll([a, b, a]);
      expect(await both(), [('Dune', 120), ('Dune', 120)]);
    });
  });

  test('a sync with nothing new takes one request', () async {
    await addDune(a);
    await a.sync();
    final before = a.requests;
    await a.sync();
    expect(a.requests, before + 1);
    expect(await a.db.select(a.db.works).get(), hasLength(1));
  });

  test('the first Work to arrive becomes current on the new device', () async {
    await addDune(a);
    await a.sync();
    expect(await b.works.watchCurrent().first, isNull);
    await b.sync();
    expect((await b.works.watchCurrent().first)!.work.title, 'Dune');
  });

  test('a Work deleted on one device leaves the other too', () async {
    final id = await addDune(a);
    await syncAll([a, b]);
    a.now = evening.add(const Duration(minutes: 1));
    await a.works.delete(id);
    await syncAll([a, b]);
    expect(await b.works.watchAll().first, isEmpty);
    expect(await b.works.watchCurrent().first, isNull);
  });

  test('a deleted current Work hands current to another on sync', () async {
    final dune = await addDune(a);
    b.now = evening.add(const Duration(minutes: 1));
    await b.works.add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 272,
      checkpoints: const [],
    );
    await syncAll([a, b, a]);
    expect((await a.works.watchCurrent().first)!.work.id, dune);
    b.now = evening.add(const Duration(minutes: 2));
    await b.works.delete(dune);
    await syncAll([b, a]);
    expect((await a.works.watchCurrent().first)!.work.title, 'Piranesi');
  });

  test('pulls a long journal in pages', () async {
    final workId = await addDune(a);
    // More than one request's worth each way.
    for (var i = 0; i < 1100; i++) {
      await a.sessions.start(workId);
      a.now = a.now.add(const Duration(minutes: 1));
    }
    await a.sync();
    await b.sync();
    expect(await b.sessions.watchAll().first, hasLength(1100));
  });

  test('does nothing when signed out', () async {
    await a.auth.signOut();
    final before = a.requests;
    final result = await a.sync();
    expect(
      (result as Error<void>).error,
      isA<SyncException>().having(
        (e) => e.failure,
        'failure',
        SyncFailure.signedOut,
      ),
    );
    expect(a.requests, before);
  });

  test('an expired sign-in signs the device out', () async {
    final expired = doomreadServer(
      InMemoryAccountStore(),
      sync: InMemorySyncStore(),
      passwords: const Passwords.cheapForTests(),
    );
    final c = Device(expired, now: evening);
    addTearDown(c.db.close);
    // The shared storage holds a's token, which this server never issued.
    expect(await c.auth.username(), 'sara');
    final result = await c.sync();
    expect(
      ((result as Error<void>).error as SyncException).failure,
      SyncFailure.signInEnded,
    );
    expect(await c.auth.username(), isNull);
  });

  test('a release build never syncs over plain HTTP', () async {
    final release = SyncRepository(
      a.db,
      MockClient((_) async => fail('nothing may be sent')),
      server: Uri.parse('http://doomread.test/'),
      release: true,
    );
    final result = await release.sync(username: 'sara', token: 'a token');
    expect(
      ((result as Error<void>).error as SyncException).failure,
      SyncFailure.insecure,
    );
  });

  test('rows written before sync existed are sent on the first sync', () async {
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE settings (key TEXT NOT NULL PRIMARY KEY, '
            'value TEXT NOT NULL)',
          )
          ..execute(
            'CREATE TABLE works (id TEXT NOT NULL PRIMARY KEY, '
            'title TEXT NOT NULL, author TEXT NOT NULL, '
            'total_pages INTEGER NOT NULL, checkpoints TEXT NOT NULL, '
            'position INTEGER NOT NULL DEFAULT 0, '
            'updated_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE session_events (id TEXT NOT NULL PRIMARY KEY, '
            'session_id TEXT NOT NULL, work_id TEXT NOT NULL, '
            'kind TEXT NOT NULL, at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE notes (id TEXT NOT NULL PRIMARY KEY, '
            'session_id TEXT NOT NULL UNIQUE, work_id TEXT NOT NULL, '
            'from_page INTEGER NOT NULL, to_page INTEGER NOT NULL, '
            'body TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          )
          ..execute(
            "INSERT INTO works VALUES ('w1', 'Dune', 'Frank Herbert', "
            "412, '40,80', 30, 1761150000)",
          )
          ..execute(
            "INSERT INTO session_events VALUES ('e1', 's1', 'w1', 'start', "
            '1761150000)',
          )
          ..execute(
            "INSERT INTO notes VALUES ('n1', 's1', 'w1', 0, 30, 'Sand.', "
            '1761150000)',
          )
          ..execute('PRAGMA user_version = 3'),
      ),
    );
    addTearDown(old.close);
    final client = MockClient((request) async {
      final response = await server(
        shelf.Request(
          request.method,
          request.url,
          headers: request.headers,
          body: request.bodyBytes,
        ),
      );
      return http.Response(await response.readAsString(), response.statusCode);
    });
    final syncing = SyncUseCase(
      AuthRepository(old, client, server: Device._url),
      SyncRepository(old, client, server: Device._url),
      WorkRepository(old),
    );
    expect(await syncing(), isA<Ok<void>>());

    expect(await b.sync(), isA<Ok<void>>());
    final there = await b.last();
    expect(there.road.work.title, 'Dune');
    expect(there.road.position, 30);
    expect(there.note, 'Sand.');
    expect(there.road.work.kind, WorkKind.paperBook);
  });
}
