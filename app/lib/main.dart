import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

void main() {
  final db = AppDatabase.open();
  runApp(DoomreadApp(db: db, auth: AuthRepository(db, http.Client())));
}
