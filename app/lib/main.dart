import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(DoomreadApp(settings: SettingsRepository(AppDatabase.open())));
}
