import 'package:doomread_core/sync.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 22, 21, 0, 5, 123, 456);
  final work = SyncItem(
    kind: SyncKind.work,
    id: 'w1',
    updatedAt: at,
    data: const {
      'title': 'Dune',
      'checkpoints': [10, 20],
    },
  );

  test('a request and a response survive a trip through JSON', () {
    final request = SyncRequest.fromJson(
      SyncRequest(since: 7, items: [work]).toJson(),
    );
    expect(request.since, 7);
    final item = request.items.single;
    expect((item.kind, item.id, item.data), (SyncKind.work, 'w1', work.data));
    expect(item.updatedAt, at);

    final response = SyncResponse.fromJson(
      SyncResponse(cursor: 9, more: true, items: [work]).toJson(),
    );
    expect((response.cursor, response.more), (9, true));
    expect(response.items.single.updatedAt, at);
  });

  test('times travel as exact UTC, whatever the sending zone', () {
    final local = DateTime(2026, 10, 22, 21);
    final item = SyncItem.fromJson(
      SyncItem(
        kind: SyncKind.event,
        id: 'e',
        updatedAt: local,
        data: const {},
      ).toJson(),
    );
    expect(item.updatedAt.isUtc, isTrue);
    expect(item.updatedAt.isAtSameMomentAs(local), isTrue);
  });

  test('refuses unknown kinds and missing or overlong ids', () {
    for (final json in <Map<String, Object?>>[
      {...work.toJson(), 'kind': 'friend'},
      {...work.toJson(), 'id': ''},
      {...work.toJson(), 'id': 'x' * 65},
      {...work.toJson()}..remove('id'),
    ]) {
      expect(() => SyncItem.fromJson(json), throwsA(anything), reason: '$json');
    }
  });

  group('last write wins', () {
    final earlier = DateTime.utc(2026, 10, 22, 21);
    final later = earlier.add(const Duration(seconds: 1));

    test('the later write wins on both sides', () {
      expect(serverTakes(later, earlier), isTrue);
      expect(serverTakes(earlier, later), isFalse);
      expect(deviceTakes(later, earlier), isTrue);
      expect(deviceTakes(earlier, later), isFalse);
    });

    test('on a tie the server keeps its copy and devices take it', () {
      expect(serverTakes(earlier, earlier), isFalse);
      expect(deviceTakes(earlier, earlier), isTrue);
    });
  });
}
