# The sign-in token lives in platform secure storage, via flutter_secure_storage

The sign-in token and the signed-in username are kept with `flutter_secure_storage`, not in the app's SQLite settings table. On Android it encrypts them with AES-GCM under a key wrapped by the Android Keystore, which every supported phone has (minSdk 29). Its only native dependency is Google's open-source Tink library (Apache-2.0), with no Google Play services (`gradlew :app:dependencies` shows no `com.google.android.gms` or Firebase), so the APK and Cafe Bazaar builds and ADR-0002 are unaffected. A session found in the old settings table is moved over on first read and then deleted there.

Linux, a later target, goes through libsecret to the desktop's Secret Service:

- Build: `libsecret-1-dev` (pkg-config `libsecret-1>=0.18.4`), which the dev image doesn't install yet. Add it to `tool/Dockerfile` with the first Linux build.
- Run: `libsecret-1-0` and a running keyring (gnome-keyring, KWallet, or another Secret Service). Without one, reads and writes fail, and the Linux build will need to treat that as signed out.

The plugin's default `resetOnError` stays on. A backup restored to another phone can't unwrap its key, so the storage is wiped and the user signs in again, rather than the app crashing or the token moving to a new device. We chose this over encrypting the whole SQLite file (SQLCipher). That would still need a safe place for its key, which is this same keystore, and it would make the vendored SQLite build (ADR-0006) heavier.
