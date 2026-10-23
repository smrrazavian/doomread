import 'package:doomread_core/sync.dart';

/// Where each account's synced rows live. Postgres in production, memory in
/// tests.
///
/// Every row the store takes in gets the next number in a sequence, and a
/// device's cursor is the last number it has seen, so a pull returns exactly
/// what that device hasn't seen yet. The rows' data is never read.
abstract interface class SyncStore {
  /// Takes in [items] for [username], in order, by last write wins
  /// ([serverTakes]); then returns up to [limit] rows numbered after
  /// [since], in order.
  Future<SyncResponse> sync(
    String username,
    int since,
    List<SyncItem> items, {
    int limit = SyncResponse.maxItems,
  });
}

class InMemorySyncStore implements SyncStore {
  final _rows = <String, Map<(SyncKind, String), (int, SyncItem)>>{};
  var _seq = 0;

  @override
  Future<SyncResponse> sync(
    String username,
    int since,
    List<SyncItem> items, {
    int limit = SyncResponse.maxItems,
  }) async {
    final rows = _rows.putIfAbsent(username, () => {});
    for (final item in items) {
      final stored = rows[(item.kind, item.id)];
      if (stored == null || serverTakes(item.updatedAt, stored.$2.updatedAt)) {
        rows[(item.kind, item.id)] = (++_seq, item);
      }
    }
    final after = rows.values.where((r) => r.$1 > since).toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    final page = after.take(limit).toList();
    return SyncResponse(
      cursor: page.isEmpty ? since : page.last.$1,
      more: after.length > limit,
      items: [for (final r in page) r.$2],
    );
  }

  @override
  // Counts only: the rows are private to their accounts.
  String toString() => 'InMemorySyncStore(${_rows.length} accounts)';
}
