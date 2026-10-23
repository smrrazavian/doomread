/// The Postgres adapter for [AccountStore].
library;

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
];

class PostgresAccountStore implements AccountStore {
  PostgresAccountStore._(this._db);

  final Pool<void> _db;

  /// Connects and brings the schema up to date.
  static Future<PostgresAccountStore> open(Endpoint endpoint) async {
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
    return PostgresAccountStore._(db);
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
}
