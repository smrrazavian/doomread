/// The Postgres adapter for [AccountStore] and [SyncStore].
library;

import 'dart:convert';

import 'package:doomread_core/sync.dart';
import 'package:doomread_server/server.dart';
import 'package:postgres/postgres.dart';

export 'package:postgres/postgres.dart' show Endpoint;

/// Where Postgres is, from the usual PG* variables. The defaults match
/// docker-compose.yml, so tests and `dart run` work against it as is.
Endpoint postgresEndpoint(Map<String, String> env) => Endpoint(
  host: env['PGHOST'] ?? 'localhost',
  port: int.parse(env['PGPORT'] ?? '5432'),
  database: env['PGDATABASE'] ?? 'doomread',
  username: env['PGUSER'] ?? 'doomread',
  password: env['PGPASSWORD'] ?? 'doomread',
);

/// Any constant; it keeps two servers from migrating at once.
const _migrationLock = 0x646f6f6d; // "doom"

/// The schema, one step per version, applied in order in one transaction
/// at open. Never edit a step that has shipped; add a new one.
const _migrations = <List<String>>[
  // 1: the tables as they were before migrations, kept `if not exists` so
  // databases made by that code upgrade cleanly.
  [
    '''
    create table if not exists accounts (
      id bigint generated always as identity primary key,
      username text not null unique,
      password_hash text not null,
      created_at timestamptz not null default now()
    )''',
    '''
    create table if not exists sign_ins (
      token_hash text primary key,
      account_id bigint not null references accounts on delete cascade,
      created_at timestamptz not null default now()
    )''',
  ],
  // 2: sign-ins expire when unused (signInIdleLimit). Existing ones count
  // as used now, so nobody is signed out by the upgrade.
  [
    '''
    alter table sign_ins
      add column last_used_at timestamptz not null default now()''',
  ],
  // 3: each account's synced journal events, Works and Notes. The data is
  // the app's JSON, kept as sent; updated_at is in epoch microseconds.
  [
    'create sequence synced_rows_seq',
    '''
    create table synced_rows (
      account_id bigint not null references accounts on delete cascade,
      kind text not null,
      id text not null,
      updated_at bigint not null,
      data text not null,
      seq bigint not null,
      primary key (account_id, kind, id)
    )''',
    'create index synced_rows_by_seq on synced_rows (account_id, seq)',
  ],
];

class PostgresStore implements AccountStore, SyncStore {
  PostgresStore._(this._db);

  final Pool<void> _db;

  /// Connects and brings the schema up to date.
  static Future<PostgresStore> open(Endpoint endpoint) async {
    // ponytail: no TLS to Postgres; it is only reachable on compose's
    // private network. Turn sslMode on if it ever runs on another host.
    final db = Pool<void>.withEndpoints([
      endpoint,
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    await db.runTx((tx) async {
      // One server at a time: concurrent `create if not exists` can collide.
      await tx.execute('select pg_advisory_xact_lock($_migrationLock)');
      await tx.execute('''
        create table if not exists schema_migrations (
          version integer primary key,
          applied_at timestamptz not null default now()
        )''');
      final applied = await tx.execute(
        'select coalesce(max(version), 0) from schema_migrations',
      );
      for (
        var v = (applied.single.single! as int) + 1;
        v <= _migrations.length;
        v++
      ) {
        for (final statement in _migrations[v - 1]) {
          await tx.execute(statement);
        }
        await tx.execute(
          Sql.named('insert into schema_migrations (version) values (@v)'),
          parameters: {'v': v},
        );
      }
    });
    return PostgresStore._(db);
  }

  Future<void> close() => _db.close();

  @override
  Future<bool> createAccount(String username, String passwordHash) async {
    final result = await _db.execute(
      Sql.named(
        'insert into accounts (username, password_hash) values (@u, @h) '
        'on conflict (username) do nothing',
      ),
      parameters: {'u': username, 'h': passwordHash},
    );
    return result.affectedRows == 1;
  }

  @override
  Future<String?> passwordHash(String username) async {
    final rows = await _db.execute(
      Sql.named('select password_hash from accounts where username = @u'),
      parameters: {'u': username},
    );
    return rows.isEmpty ? null : rows.single.single! as String;
  }

  @override
  Future<void> createSignIn(
    String username,
    String tokenHash,
    DateTime now,
  ) async {
    await _db.execute(
      Sql.named(
        'insert into sign_ins (token_hash, account_id, created_at, '
        'last_used_at) '
        'select @t, id, @now:timestamptz, @now:timestamptz '
        'from accounts where username = @u',
      ),
      parameters: {'t': tokenHash, 'u': username, 'now': now.toUtc()},
    );
  }

  @override
  Future<String?> useSignIn(String tokenHash, DateTime now) async {
    final rows = await _db.execute(
      Sql.named(
        'update sign_ins s set last_used_at = @now:timestamptz '
        'from accounts a '
        'where s.token_hash = @t and a.id = s.account_id '
        'and s.last_used_at > @cutoff:timestamptz '
        'returning a.username',
      ),
      parameters: {
        't': tokenHash,
        'now': now.toUtc(),
        'cutoff': now.subtract(signInIdleLimit).toUtc(),
      },
    );
    return rows.isEmpty ? null : rows.single.single! as String;
  }

  @override
  Future<bool> deleteSignIn(String tokenHash) async {
    final result = await _db.execute(
      Sql.named('delete from sign_ins where token_hash = @t'),
      parameters: {'t': tokenHash},
    );
    return result.affectedRows == 1;
  }

  @override
  Future<SyncResponse> sync(
    String username,
    int since,
    List<SyncItem> items, {
    int limit = SyncResponse.maxItems,
  }) => _db.runTx((tx) async {
    // Locking the account row runs its syncs one at a time. Otherwise a
    // pull could see a later number commit before an earlier one, move its
    // cursor past both, and never see the earlier row.
    final account = await tx.execute(
      Sql.named(
        'select id from accounts where username = @u for no key update',
      ),
      parameters: {'u': username},
    );
    final id = account.single.single! as int;
    for (final item in items) {
      await tx.execute(
        Sql.named(
          'insert into synced_rows (account_id, kind, id, updated_at, data, '
          "seq) values (@a, @k, @i, @t, @d, nextval('synced_rows_seq')) "
          'on conflict (account_id, kind, id) do update set '
          'updated_at = excluded.updated_at, data = excluded.data, '
          'seq = excluded.seq '
          // serverTakes: only a later write replaces the stored row.
          'where excluded.updated_at > synced_rows.updated_at',
        ),
        parameters: {
          'a': id,
          'k': item.kind.name,
          'i': item.id,
          't': item.updatedAt.microsecondsSinceEpoch,
          'd': jsonEncode(item.data),
        },
      );
    }
    final rows = await tx.execute(
      Sql.named(
        'select kind, id, updated_at, data, seq from synced_rows '
        'where account_id = @a and seq > @since order by seq limit @n',
      ),
      parameters: {'a': id, 'since': since, 'n': limit + 1},
    );
    final page = rows.take(limit).toList();
    return SyncResponse(
      cursor: page.isEmpty ? since : page.last[4]! as int,
      more: rows.length > limit,
      items: [
        for (final r in page)
          SyncItem(
            kind: SyncKind.values.byName(r[0]! as String),
            id: r[1]! as String,
            updatedAt: DateTime.fromMicrosecondsSinceEpoch(
              r[2]! as int,
              isUtc: true,
            ),
            data: jsonDecode(r[3]! as String) as Map<String, Object?>,
          ),
      ],
    );
  });
}
