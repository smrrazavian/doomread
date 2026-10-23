// Needs the compose Postgres: `docker compose up -d --wait postgres`.
// Skip it with `dart test -x postgres`.
@Tags(['postgres'])
library;

import 'dart:io';
import 'dart:math';

import 'package:doomread_server/postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'account_store_contract.dart';

void main() {
  final endpoint = postgresEndpoint(Platform.environment);
  late PostgresAccountStore store;

  setUpAll(() async {
    store = await PostgresAccountStore.open(endpoint);
  });
  tearDownAll(() => store.close());

  accountStoreContract(() => store);

  group('on a database made before migrations', () {
    final name = 'migrate_${Random().nextInt(1 << 32).toRadixString(36)}';
    final scratch = Endpoint(
      host: endpoint.host,
      port: endpoint.port,
      database: name,
      username: endpoint.username,
      password: endpoint.password,
    );
    Future<void> admin(String sql) async {
      final c = await Connection.open(
        endpoint,
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
      await c.execute(sql);
      await c.close();
    }

    setUp(() => admin('create database $name'));
    tearDown(() => admin('drop database $name with (force)'));

    test('upgrades in place and keeps its accounts', () async {
      final old = await Connection.open(
        scratch,
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
      // The schema exactly as the code before migrations created it.
      await old.execute('''
        create table if not exists accounts (
          id bigint generated always as identity primary key,
          username text not null unique,
          password_hash text not null,
          created_at timestamptz not null default now()
        )''');
      await old.execute('''
        create table if not exists sign_ins (
          token_hash text primary key,
          account_id bigint not null references accounts on delete cascade,
          created_at timestamptz not null default now()
        )''');
      await old.execute(
        "insert into accounts (username, password_hash) values ('sara', 'h')",
      );
      await old.execute(
        "insert into sign_ins (token_hash, account_id) values ('tok', 1)",
      );
      await old.close();

      // Twice: opening an up-to-date database changes nothing.
      for (var i = 0; i < 2; i++) {
        final upgraded = await PostgresAccountStore.open(scratch);
        expect(await upgraded.passwordHash('sara'), 'h');
        expect(await upgraded.createAccount('sara', 'other'), isFalse);
        expect(await upgraded.useSignIn('tok', DateTime.now()), 'sara');
        await upgraded.close();
      }
      final c = await Connection.open(
        scratch,
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
      final versions = await c.execute('select version from schema_migrations');
      await c.close();
      expect(versions, hasLength(2));
    });
  });
}
