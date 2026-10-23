import 'dart:math';

import 'package:doomread_core/sync.dart';
import 'package:doomread_server/server.dart';
import 'package:test/test.dart';

/// What every SyncStore adapter must do. [newAccount] makes an account and
/// returns its username; names are unique per run, so the Postgres adapter
/// can share a database with other runs.
void syncStoreContract(
  SyncStore Function() store,
  Future<String> Function(String username) newAccount,
) {
  final run = Random().nextInt(1 << 32).toRadixString(36);
  var n = 0;
  Future<String> fresh() => newAccount('s${run}_${n++}');

  final t0 = DateTime.utc(2026, 10, 22, 21);
  SyncItem item(
    SyncKind kind,
    String id, [
    int second = 0,
    Map<String, Object?> data = const {},
  ]) => SyncItem(
    kind: kind,
    id: id,
    updatedAt: t0.add(Duration(seconds: second)),
    data: data,
  );
  List<String> ids(SyncResponse r) => [for (final i in r.items) i.id];

  test('a fresh account has nothing to pull', () async {
    final u = await fresh();
    final r = await store().sync(u, 0, []);
    expect((r.cursor, r.more), (0, false));
    expect(r.items, isEmpty);
  });

  test('returns what was pushed, in order, with its data', () async {
    final u = await fresh();
    final pushed = [
      item(SyncKind.work, 'w1', 0, {'title': 'Dune', 'pages': 412}),
      item(SyncKind.event, 'e1', 1, {'kind': 'start'}),
      item(SyncKind.note, 'n1', 2, {'body': 'Paul leaves.'}),
    ];
    final r = await store().sync(u, 0, pushed);
    expect(ids(r), ['w1', 'e1', 'n1']);
    expect(r.items.first.data, {'title': 'Dune', 'pages': 412});
    expect(r.items.first.kind, SyncKind.work);
    expect(r.items.last.updatedAt, t0.add(const Duration(seconds: 2)));
    expect(r.more, isFalse);
  });

  test('a cursor returns only what came in after it', () async {
    final u = await fresh();
    final first = await store().sync(u, 0, [item(SyncKind.event, 'e1')]);
    final second = await store().sync(u, first.cursor, [
      item(SyncKind.event, 'e2'),
    ]);
    expect(ids(second), ['e2']);
    expect(second.cursor, greaterThan(first.cursor));
    final none = await store().sync(u, second.cursor, []);
    expect(none.cursor, second.cursor);
    expect(none.items, isEmpty);
  });

  test('keeps the later write of a Work, whichever arrives first', () async {
    final u = await fresh();
    await store().sync(u, 0, [
      item(SyncKind.work, 'w', 5, {'title': 'later'}),
    ]);
    final r = await store().sync(u, 0, [
      item(SyncKind.work, 'w', 3, {'title': 'earlier'}),
    ]);
    expect(r.items.single.data, {'title': 'later'});

    final newer = await store().sync(u, r.cursor, [
      item(SyncKind.work, 'w', 9, {'title': 'latest'}),
    ]);
    expect(newer.items.single.data, {'title': 'latest'});
  });

  test('keeps the stored copy on a tie, and an event only once', () async {
    final u = await fresh();
    final first = await store().sync(u, 0, [
      item(SyncKind.note, 'n', 1, {'body': 'first'}),
      item(SyncKind.event, 'e', 1, {'kind': 'start'}),
    ]);
    final again = await store().sync(u, first.cursor, [
      item(SyncKind.note, 'n', 1, {'body': 'second'}),
      item(SyncKind.event, 'e', 1, {'kind': 'start'}),
    ]);
    expect(again.items, isEmpty);
    final all = await store().sync(u, 0, []);
    expect(all.items.map((i) => i.data), [
      {'body': 'first'},
      {'kind': 'start'},
    ]);
  });

  test('the same id in another kind is another row', () async {
    final u = await fresh();
    final r = await store().sync(u, 0, [
      item(SyncKind.work, 'x'),
      item(SyncKind.note, 'x'),
    ]);
    expect(r.items.map((i) => i.kind), [SyncKind.work, SyncKind.note]);
  });

  test('pages long pulls', () async {
    final u = await fresh();
    await store().sync(u, 0, [
      for (var i = 0; i < 5; i++) item(SyncKind.event, 'e$i', i),
    ]);
    final first = await store().sync(u, 0, [], limit: 3);
    expect(ids(first), ['e0', 'e1', 'e2']);
    expect(first.more, isTrue);
    final rest = await store().sync(u, first.cursor, [], limit: 3);
    expect(ids(rest), ['e3', 'e4']);
    expect(rest.more, isFalse);
  });

  test("one account never sees another's rows", () async {
    final a = await fresh();
    final b = await fresh();
    await store().sync(a, 0, [item(SyncKind.event, 'e')]);
    expect((await store().sync(b, 0, [])).items, isEmpty);
    // The same id in another account is that account's own row.
    await store().sync(b, 0, [
      item(SyncKind.event, 'e', 0, {'who': 'b'}),
    ]);
    expect((await store().sync(a, 0, [])).items.single.data, isEmpty);
  });
}
