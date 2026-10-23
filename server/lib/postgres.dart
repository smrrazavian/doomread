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

class PostgresAccountStore implements AccountStore {
  PostgresAccountStore._(this._db);

  final Pool<void> _db;

  /// Connects and creates the tables if they are missing.
  static Future<PostgresAccountStore> open(Endpoint endpoint) async {
    // ponytail: no TLS to Postgres; it is only reachable on compose's
    // private network. Turn sslMode on if it ever runs on another host.
    final db = Pool<void>.withEndpoints(
      [endpoint],
      settings: const PoolSettings(sslMode: SslMode.disable),
    );
    // ponytail: schema by `create if not exists`, no migrations yet.
    // Bring in versioned migrations with the first change to a table.
    await db.execute('''
      create table if not exists accounts (
        id bigint generated always as identity primary key,
        username text not null unique,
        password_hash text not null,
        created_at timestamptz not null default now()
      )''');
    await db.execute('''
      create table if not exists sessions (
        token_hash text primary key,
        account_id bigint not null references accounts on delete cascade,
        created_at timestamptz not null default now()
      )''');
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
  Future<void> createSession(String username, String tokenHash) async {
    await _db.execute(
      Sql.named(
        'insert into sessions (token_hash, account_id) '
        'select @t, id from accounts where username = @u',
      ),
      parameters: {'t': tokenHash, 'u': username},
    );
  }

  @override
  Future<bool> deleteSession(String tokenHash) async {
    final result = await _db.execute(
      Sql.named('delete from sessions where token_hash = @t'),
      parameters: {'t': tokenHash},
    );
    return result.affectedRows == 1;
  }
}
