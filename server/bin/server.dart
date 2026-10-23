import 'dart:io';

import 'package:doomread_server/postgres.dart';
import 'package:doomread_server/server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// `server` serves on $PORT (8080). `server healthcheck` asks a running
/// server for /health and exits 0 or 1: the image has no curl.
Future<void> main(List<String> args) async {
  final env = Platform.environment;
  final port = int.parse(env['PORT'] ?? '8080');

  if (args.firstOrNull == 'healthcheck') {
    exit(await _healthy(port) ? 0 : 1);
  }

  final store = await PostgresStore.open(postgresEndpoint(env));
  // Any address, so it can be reached from outside the container.
  final server = await shelf_io.serve(
    doomreadServer(store, sync: store),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln('Doomread server on port ${server.port}');

  await Future.any([
    ProcessSignal.sigterm.watch().first,
    ProcessSignal.sigint.watch().first,
  ]);
  await server.close();
  await store.close();
}

Future<bool> _healthy(int port) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client.get('127.0.0.1', port, '/health');
    final response = await request.close();
    return response.statusCode == 200;
  } on Object {
    return false;
  } finally {
    client.close(force: true);
  }
}
