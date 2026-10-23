/// What the app and the sync server send each other to sync one account's
/// journal, Works and Notes between its devices (ADR-0006).
///
/// One round trip, `POST /sync`: the device sends what it changed and the
/// cursor it last saw, and gets back everything the server took in after
/// that cursor, its own changes included.
library;

/// What a synced row is.
enum SyncKind { event, work, note }

/// One synced row: a Session journal event, a Work or a Note.
///
/// The server stores [data] as it is and never reads it; only the app
/// does, so a Work can gain fields without a server change.
class SyncItem {
  const SyncItem({
    required this.kind,
    required this.id,
    required this.updatedAt,
    required this.data,
  });

  factory SyncItem.fromJson(Map<String, Object?> json) {
    final id = json['id']! as String;
    if (id.isEmpty || id.length > maxIdLength) {
      throw const FormatException('bad id');
    }
    return SyncItem(
      kind: SyncKind.values.byName(json['kind']! as String),
      id: id,
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(
        json['updatedAt']! as int,
        isUtc: true,
      ),
      data: json['data']! as Map<String, Object?>,
    );
  }

  static const maxIdLength = 64;

  final SyncKind kind;
  final String id;

  /// When it was last written; for an event, when it happened. Events never
  /// change, so the same rule keeps the first copy of each.
  final DateTime updatedAt;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'id': id,
    // Epoch microseconds: exact, and free of time zones.
    'updatedAt': updatedAt.microsecondsSinceEpoch,
    'data': data,
  };
}

/// Last write wins, on the server: an incoming row replaces the stored one
/// only when it was written later. On a tie the stored one stays.
bool serverTakes(DateTime incoming, DateTime stored) =>
    incoming.isAfter(stored);

/// Last write wins, on a device: the server's row replaces the local one
/// unless the local one was written later. On a tie the server's wins, so
/// every device ends up with the copy the server kept.
bool deviceTakes(DateTime fromServer, DateTime local) =>
    !fromServer.isBefore(local);

/// What a device sends: its changes, and the last cursor it saw.
class SyncRequest {
  const SyncRequest({required this.since, required this.items});

  factory SyncRequest.fromJson(Map<String, Object?> json) => SyncRequest(
    since: json['since']! as int,
    items: [
      for (final i in json['items']! as List<Object?>)
        SyncItem.fromJson(i! as Map<String, Object?>),
    ],
  );

  /// The most a device sends at once; it sends the rest in the next request.
  static const maxItems = 500;

  /// 0 for a device that has never synced.
  final int since;
  final List<SyncItem> items;

  Map<String, Object?> toJson() => {
    'since': since,
    'items': [for (final i in items) i.toJson()],
  };
}

/// What the server answers: the rows after the device's cursor, in the
/// order the server took them in, and the cursor to send next time.
class SyncResponse {
  const SyncResponse({
    required this.cursor,
    required this.more,
    required this.items,
  });

  factory SyncResponse.fromJson(Map<String, Object?> json) => SyncResponse(
    cursor: json['cursor']! as int,
    more: json['more']! as bool,
    items: [
      for (final i in json['items']! as List<Object?>)
        SyncItem.fromJson(i! as Map<String, Object?>),
    ],
  );

  /// The most the server sends at once.
  static const maxItems = 1000;

  final int cursor;

  /// Whether there are rows after [cursor] still to fetch.
  final bool more;
  final List<SyncItem> items;

  Map<String, Object?> toJson() => {
    'cursor': cursor,
    'more': more,
    'items': [for (final i in items) i.toJson()],
  };
}
