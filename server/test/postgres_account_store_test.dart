// Needs the compose Postgres: `docker compose up -d --wait postgres`.
// Skip it with `dart test -x postgres`.
@Tags(['postgres'])
library;

import 'dart:io';

import 'package:doomread_server/postgres.dart';
import 'package:test/test.dart';

import 'account_store_contract.dart';

void main() {
  late PostgresAccountStore store;

  setUpAll(() async {
    store = await PostgresAccountStore.open(
      postgresEndpoint(Platform.environment),
    );
  });
  tearDownAll(() => store.close());

  accountStoreContract(() => store);
}
