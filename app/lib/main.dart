import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/sync_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

void main() {
  final db = AppDatabase.open();
  final client = http.Client();
  final auth = AuthRepository(db, client);
  runApp(
    DoomreadApp(db: db, auth: auth, sync: SyncRepository(db, auth, client)),
  );
}
