# The sync and accounts server is Dart + shelf, shipped as an AOT binary with docker compose

The server is plain Dart on `shelf`, AOT-compiled into a small scratch image, with Postgres and ntfy alongside it in `docker-compose.yml`. It shares `packages/core` with the app, so both sides agree on events and sync types. We rejected Serverpod because its core package is SSPL-1.0, and Dart Frog because its maintenance has been uncertain since it moved to a new org.
