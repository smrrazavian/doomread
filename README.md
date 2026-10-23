# Doomread · باز گوشی؟!

Doomscroll later. Doomread now.

Doomread helps you finish the book, series, film or podcast you started. It works by adding company, planned breaks, and a visible road to the last page. It doesn't ban Instagram or TikTok, it just makes them wait for your break.

Android first, then Linux, then iOS. Built offline-first, with no Google services, so it works inside Iran. English and Persian (RTL).

- Design: [`docs/superpowers/specs/2026-10-22-attention-span-design.md`](docs/superpowers/specs/2026-10-22-attention-span-design.md)
- Mockups: [`docs/mockups/`](docs/mockups/)
- Domain language: [`CONTEXT.md`](CONTEXT.md)
- Decisions: [`docs/adr/`](docs/adr/)

Licensed under [GPL-3.0](LICENSE).

## Development

Everything runs in a Docker dev container, so the laptop needs only Docker. `tool/dev <command>` runs a command inside it. The first run pulls the prebuilt image from `ghcr.io/smrrazavian/doomread-dev`, which CI publishes whenever `tool/Dockerfile` changes. If that fails, it builds the image locally from pinned, checksummed official downloads (Flutter 3.47.7 and the Android SDK). If you're behind an HTTP proxy, set `HTTPS_PROXY`; `tool/dev` passes it on to pub and Gradle. Inside Iran, Google's Maven repositories answer 404, so also set `MAVEN_MIRROR=https://maven.myket.ir`. Gradle then tries that mirror first, and nothing in the project's build files changes.

```sh
tool/dev flutter pub get
tool/dev sh -c 'cd app && flutter test'              # unit, widget and golden tests
tool/dev sh -c 'cd app && flutter run --flavor apk'  # on your phone, with hot reload
```

Flavours: `apk` (direct download), `play` (Google Play) and `bazaar` (Cafe Bazaar). See ADR-0004.

### Connect your phone (Android 11+, wireless debugging)

1. On the phone: **Settings → System → Developer options → Wireless debugging → on**, and keep the phone on the same Wi-Fi as the laptop.
2. Tap **Pair device with pairing code**, then run `tool/dev adb pair <ip>:<pairing-port> <code>`.
3. Run `tool/dev adb connect <ip>:<port>`, using the port shown on the Wireless debugging screen (not the pairing port).
4. Each `tool/dev` run starts a fresh adb server, so chain the commands: `tool/dev sh -c 'adb connect <ip>:<port> && flutter run --flavor apk'`. Pairing keys are remembered between runs.

### Or connect over USB

`tool/dev` hands the USB bus to the container. To let your user (not only root) reach the phone, add a udev rule once on the host. `05c6` is the vendor ID of the Nothing Phone 4a's Qualcomm chip; check yours with `lsusb`.

```sh
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", MODE="0660", TAG+="uaccess"' \
  | sudo tee /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Replug the phone, accept "Allow USB debugging", and `tool/dev adb devices` lists it.

VS Code users can also "Reopen in Container" with `.devcontainer/`.

### The server

The sync and accounts server (`server/`, ADR-0007) runs with Postgres and ntfy under docker compose:

```sh
docker compose up -d --wait                          # server on :8080, ntfy on :8090
tool/dev sh -c 'cd server && dart test'              # needs the compose Postgres
tool/dev sh -c 'cd server && dart test -x postgres'  # without it
```

Compose can't build on the host network, so if your proxy listens on the host's localhost, build the server image yourself first: `docker build --network host --build-arg HTTPS_PROXY -t doomread-server -f server/Dockerfile .`

The app talks to `http://localhost:8080` by default. A phone can't reach your laptop's localhost, so pass your laptop's address: `flutter run --flavor apk --dart-define=DOOMREAD_SERVER=http://192.168.1.20:8080`. The app works fully without an account.

Golden screenshots are rendered inside the container. To update them, run `tool/dev sh -c 'cd app && flutter test --update-goldens'`.
