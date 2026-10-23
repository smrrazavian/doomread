// Needs the compose Postgres: `docker compose up -d --wait postgres`.
// Skip it with `dart test -x postgres`.
@Tags(['postgres'])
library;

import 'dart:io';

import 'package:doomread_server/postgres.dart';
import 'package:test/test.dart';

import 'sync_store_contract.dart';

void main() {
  late PostgresStore store;

  setUpAll(() async {
    store = await PostgresStore.open(postgresEndpoint(Platform.environment));
  });
  tearDownAll(() => store.close());

  syncStoreContract(() => store, (username) async {
    await store.createAccount(username, 'hash');
    return username;
  });
}
