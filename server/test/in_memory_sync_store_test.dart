import 'package:doomread_server/server.dart';

import 'sync_store_contract.dart';

void main() {
  final store = InMemorySyncStore();
  syncStoreContract(() => store, (username) async => username);
}
