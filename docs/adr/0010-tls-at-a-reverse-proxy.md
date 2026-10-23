# Sync traffic is encrypted by TLS at a reverse proxy, and release builds only speak HTTPS

The server speaks plain HTTP and is meant to run behind a reverse proxy that terminates TLS (Caddy, nginx, or whatever the host already runs). Only the proxy faces the internet. The hops from proxy to server and from server to Postgres stay on the host or compose's private network.

The app enforces this from its side. A release build sends a password, its token or synced data only to an `https://` server (`sendsSecurely` in `auth_repository.dart`). Pointed anywhere else, it treats the server as unreachable, so a misbuilt release can't send anything in the clear. Debug and profile builds also allow `http://`, for a dev server on the LAN. The check lives in Dart because Dart's `HttpClient` ignores Android's network security config.

We chose this over TLS inside the shelf server. Certificates and their renewal are what a proxy already does well, hosts in Iran usually provide one, and the server stays a small AOT binary. This is encryption in transit only: the server can read the Notes it syncs, like any account server. End-to-end encryption would be a separate decision.
