import 'dart:io';

import 'package:flutter/services.dart';

/// Hands an image to the rest of the system. On Android a small native edge
/// (`ShareSheet.kt`, ADR 0009's pattern) writes it to the app's cache and
/// opens the share sheet with a plain ACTION_SEND through a FileProvider, so
/// no plugin and no Google services. On Linux it's saved to the user's
/// Pictures folder instead.
class ShareSheet {
  ShareSheet({Map<String, String>? environment})
    : _env = environment ?? Platform.environment;

  static const _channel = MethodChannel('doomread/share');

  final Map<String, String> _env;

  /// Whether this platform can share at all: Android, or Linux by saving.
  bool get available => Platform.isAndroid || Platform.isLinux;

  /// Shares [png] as [name]. On Android it returns null once the share sheet
  /// is up, titled [title]; on Linux it returns the path it saved to.
  Future<String?> sharePng(
    Uint8List png, {
    required String name,
    required String title,
  }) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('sharePng', {
        'png': png,
        'name': name,
        'title': title,
      });
      return null;
    }
    if (Platform.isLinux) {
      final dir = Directory(picturesDir(_env, _userDirs()));
      await dir.create(recursive: true);
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(png);
      return file.path;
    }
    throw UnsupportedError('Sharing is not supported on this platform');
  }

  String? _userDirs() {
    final config = _env['XDG_CONFIG_HOME'] ?? '${_env['HOME']}/.config';
    final file = File('$config/user-dirs.dirs');
    return file.existsSync() ? file.readAsStringSync() : null;
  }
}

/// The XDG Pictures folder: XDG_PICTURES_DIR from [userDirs] (the contents
/// of user-dirs.dirs) with \$HOME filled in, or ~/Pictures without one.
String picturesDir(Map<String, String> env, String? userDirs) {
  final home = env['HOME'] ?? '';
  final set = RegExp(
    r'^XDG_PICTURES_DIR="(.*)"\s*$',
    multiLine: true,
  ).firstMatch(userDirs ?? '')?[1];
  final dir = set?.replaceFirst(r'$HOME', home);
  // An entry pointing at home itself means "turned off" in xdg-user-dirs.
  if (dir == null || dir.isEmpty || dir == home || dir == '$home/') {
    return '$home/Pictures';
  }
  return dir;
}
