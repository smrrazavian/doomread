import 'package:doomread_server/server.dart';

import 'account_store_contract.dart';

void main() {
  final store = InMemoryAccountStore();
  accountStoreContract(() => store);
}
