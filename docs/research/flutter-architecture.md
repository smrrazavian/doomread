# Flutter architecture research for Doomread

Researched 2026-10-22 against primary sources. The docs.flutter.dev pages are stamped for Flutter 3.47. pub.dev versions are as listed today.

## 1. The official app architecture guide

- **Layers.** The UI layer has *views* and *view models*, in a one-to-one pair (MVVM). The data layer has *repositories* and *services*.
  - A **repository** is the source of truth for one type of data. It handles caching, retry and errors, and it "should never be aware of" other repositories.
  - A **service** is a stateless wrapper, one per data source, that returns `Future` or `Stream`.
  - Data flows up from services to the view. Events flow down through *commands*.
  - The guide calls itself "guidelines, not steadfast rules".
  - Source: [guide](https://docs.flutter.dev/app-architecture/guide)
- **Domain layer (use-cases) is optional.** Add it only when logic merges several repositories, is complex, or is reused: "add use-cases only when needed". [guide](https://docs.flutter.dev/app-architecture/guide)
- **Strength levels.** From the [recommendations page](https://docs.flutter.dev/app-architecture/recommendations) (updated 2026-05-05):

| Strongly recommend | Recommend | Conditional |
|---|---|---|
| Separate data and UI layers. Use the repository pattern. Use MVVM. Keep logic out of widgets. Use unidirectional data flow. Use immutable models. Use dependency injection. Use abstract repositories. Test layers separately and together. Write fakes. | Use `Command`. Use `freezed` or `built_value`. Use `go_router`. Use role-based names (`HomeViewModel`, shared widgets in `ui/core/`). | Use `ChangeNotifier`/`Listenable`. Add a domain layer. Keep API models separate from domain models. |

- **Dependency injection.** The guide uses `provider`: "teams at Google recommend using `package:provider` to implement dependency injection".
  - Services and repositories go into a root `MultiProvider`.
  - View models are built in the `go_router` route builders with `context.read()`.
  - Injected dependencies are kept private.
  - Source: [DI case study](https://docs.flutter.dev/app-architecture/case-study/dependency-injection)
- **Command.** A `ChangeNotifier` that wraps an action and exposes `running`, `error` and `completed`. It ignores a call while one is already running, and it comes as `Command0` and `Command1`. The page points to `command_it` as a ready-made package. [command](https://docs.flutter.dev/app-architecture/design-patterns/command)
- **Result.** A sealed `Result<T>` with `Ok` and `Error`. Services create it, repositories pass it on, and view models `switch` over it. The page points to `result_dart` and `multiple_result` as packages. [result](https://docs.flutter.dev/app-architecture/design-patterns/result)
- **Compass app layout.** This is the only official word on feature-first vs layer-first, and it uses both. ([case study](https://docs.flutter.dev/app-architecture/case-study), [repo](https://github.com/flutter/samples/tree/main/compass_app/app/lib))
  - `lib/ui/core/` and `lib/ui/<feature>/{view_models,widgets}`: **grouped by feature**.
  - `lib/data/{repositories,services,model}`: **grouped by type**, because repositories are shared.
  - `lib/domain/models`, plus `config/`, `routing/` and `utils/`.
  - Entry points: `main.dart`, `main_development.dart` and `main_staging.dart`.
  - `test/` mirrors `lib/`, and the fakes live in `testing/`.

## 2. Other official guidance

- **State management.** The [options page](https://docs.flutter.dev/data-and-backend/state-mgmt/options) is neutral. It lists `setState`, `ValueNotifier`, `InheritedWidget` and "community packages", without naming any. The guide's own code uses `ChangeNotifier` with `ListenableBuilder`, but rates that only "Conditional".
- **Offline-first.** From the [offline-first pattern page](https://docs.flutter.dev/app-architecture/design-patterns/offline-first):
  - The repository is the only place where data changes.
  - Reads: fall back to local data, stream the local value and then the remote one, or read locally only with a `sync()`.
  - Writes: online-only, or local-first with a per-record `synchronized` flag.
  - Sync: `Timer.periodic`, `workmanager`, or a push from the server, with a warning about battery.
  - It does not cover event logs.
- **Persistence.**
  - The [SQL recipe](https://docs.flutter.dev/app-architecture/design-patterns/sql) uses `sqflite`, plus `sqflite_common_ffi` on desktop, and says `drift` works the same way.
  - [Choose a database](https://docs.flutter.dev/data-and-backend/persistence/choose-a-database) (updated 2026-10-13) describes drift as "type-safe Dart queries, reactive streams, and schema migrations". Its cloud defaults are Firebase, which ADR-0002 excludes.
- **Testing.**
  - Aim for "many unit and widget tests … plus enough integration tests". `integration_test` can't reach native UI such as permission dialogs or notifications, so the docs recommend **`patrol`**. [overview](https://docs.flutter.dev/testing/overview)
  - Compass tests view models as plain Dart with fakes and reuses those fakes in widget tests. [testing case study](https://docs.flutter.dev/app-architecture/case-study/testing)
  - Golden tests use `--update-goldens`. They render with the Ahem font unless real fonts are loaded, and results differ across OS and Flutter versions. [matchesGoldenFile](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)
- **Flavors.**
  - Android: Gradle `productFlavors` with `--flavor`, and the `appFlavor` constant. pubspec supports per-flavor assets and a `default-flavor`. With AGP 9, don't use `resValue` for `app_name`. [Android](https://docs.flutter.dev/deployment/flavors)
  - **Linux: `--flavor` works as of Flutter 3.47.** CMake receives `FLUTTER_APP_FLAVOR`. Icons and `.desktop` files come from the packaging format. [Linux](https://docs.flutter.dev/deployment/flavors-linux)
- **i18n.**
  - Setup: `flutter_localizations` plus `intl`, `generate: true`, and `l10n.yaml` (`arb-dir: lib/l10n`, template `app_en.arb`), with ICU plural and select.
  - `GlobalWidgetsLocalizations` sets the text direction, so RTL follows the locale.
  - The page has nothing specific to Persian.
  - Source: [i18n](https://docs.flutter.dev/ui/internationalization)

## 3. Pub workspaces

- **How they work.** Available since Dart 3.6 (globs since 3.11). The root pubspec lists `workspace:` paths, and each member sets `resolution: workspace`. The repo gets one lockfile and one resolution. [workspaces](https://dart.dev/tools/pub/workspaces)
- **Limits.**
  - One version of each dependency for the whole repo.
  - `dependency_overrides` go only in the root.
  - A stray non-member pubspec between the root and a member breaks `pub get`.
  - Source: [workspaces](https://dart.dev/tools/pub/workspaces)
- **melos** 8.9.0 is now built on workspaces, with its config in the root pubspec. It adds scripts, `exec` across packages, package filters and versioning. [melos](https://pub.dev/packages/melos)

## 4. Very Good CLI boilerplate

- **`very_good_cli` 1.5.0** offers `flutter_app`, `dart_package`, `flutter_plugin`, `app_ui_package` and other templates. The Flutter recommendations page links to it. [pub](https://pub.dev/packages/very_good_cli), [recs](https://docs.flutter.dev/app-architecture/recommendations)
- **What `very_good_core` generates** ([template](https://github.com/VeryGoodOpenSource/very_good_templates/tree/main/very_good_core)):
  - It is **feature-first**: `lib/app`, `lib/<feature>/{cubit,view}`, `lib/l10n/arb` and `bootstrap.dart`.
  - Three entry points: `main_{development,staging,production}.dart`.
  - Bloc for state, and a target of 100% line coverage with a shared `test/helpers/pump_app.dart`.
  - GitHub Actions CI.
- **Lints.** `very_good_analysis` 11.0.0 is VGV's strict lint set, and you can pin a version of it. [pub](https://pub.dev/packages/very_good_analysis)

## 5. Local database for the event log

| | drift | sqflite | Isar | ObjectBox |
|---|---|---|---|---|
| Status | 2.35.2, 14 days ago. Repo pushed 2026-10-21 ([pub](https://pub.dev/packages/drift), [API](https://api.github.com/repos/simolus3/drift)) | 2.4.5, about a day ago ([pub](https://pub.dev/packages/sqflite)) | 3.1.0+1, "3 years ago". Last commit 2025-06-14. README: v4 "NOT READY FOR PRODUCTION" ([pub](https://pub.dev/packages/isar), [repo](https://github.com/isar/isar)). Fork `isar_community` 3.4.1 does v3 bug fixes ([pub](https://pub.dev/packages/isar_community)) | 5.3.2, 5 months ago ([pub](https://pub.dev/packages/objectbox)) |
| Licence | MIT | BSD-2 | Apache-2.0 | The Dart binding's Apache licence covers "the code in this repository only". The core is unverified (see open questions). |
| Linux | `NativeDatabase` ([platforms](https://drift.simonbinder.eu/platforms/)) | Only through `sqflite_common_ffi` | Yes | Yes |
| Reactive | Any query can be a stream | Not documented | — | — |

- **Migrations.** `dart run drift_dev make-migrations` snapshots each `schemaVersion` and generates `stepByStep` helpers and migration tests. Hand-written migrations are called "error-prone". [migrations](https://drift.simonbinder.eu/migrations/)
- **Testing.** Use `NativeDatabase.memory()`, and `closeStreamsSynchronously: true` in widget tests. [testing](https://drift.simonbinder.eu/testing/)
- **Native SQLite and F-Droid.** drift uses `sqlite3` 3.x build hooks.
  - **By default the hook downloads prebuilt SQLite binaries from GitHub releases**. They are sha256-checked and carry SLSA attestations.
  - Alternatives: `hooks: user_defines: sqlite3: source: source` compiles a vendored `sqlite3.c`. `source: system` dlopens the OS library. `url_pattern` points at a mirror.
  - Source: [sqlite3 hook docs](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md)
  - On Android, set sqlite3's temp directory. [platforms](https://drift.simonbinder.eu/platforms/)

## 6. Riverpod, Bloc, or ChangeNotifier with DI

- **ChangeNotifier with provider or get_it.**
  - This is the official guide's own stack ([DI](https://docs.flutter.dev/app-architecture/case-study/dependency-injection)).
  - `provider` 6.1.5+1 is a mature "wrapper around InheritedWidget", last published about 14 months ago ([pub](https://pub.dev/packages/provider)).
  - The alternative is the `get_it` 9.3.0 service locator, with optional `watch_it` and `command_it` ([pub](https://pub.dev/packages/get_it)).
  - It has no built-in async or caching helpers.
- **Riverpod.**
  - `flutter_riverpod` 3.4.3, 48 days ago, MIT. It calls itself "a reactive caching and data-binding framework" and claims compile safety, built-in loading and error states, lints, and pure-Dart use ([pub](https://pub.dev/packages/flutter_riverpod), [site](https://riverpod.dev/)).
  - It also does DI, so it replaces `provider`.
  - Its offline persistence is **experimental** and "not designed to fully replace code for interacting with a database" ([offline](https://riverpod.dev/docs/concepts2/offline)).
  - Its `AsyncValue` overlaps with the guide's `Command` and `Result` (inference).
- **Bloc.**
  - `flutter_bloc` 9.1.1, last published 17 months ago. The repo was pushed today ([pub](https://pub.dev/packages/flutter_bloc), [API](https://api.github.com/repos/felangel/bloc)).
  - Its layers are data provider, repository, business logic and presentation. "No bloc should know about any other bloc", and repositories come in through constructors ([architecture](https://bloclibrary.dev/architecture/)).
  - It maps closely onto the guide, with a bloc or cubit in the view-model role. It is the VGV default.
- **Tradeoffs (inference).**
  - ChangeNotifier: zero framework and docs-identical, but more hand-written async state.
  - Riverpod: the most built-in features, but one large framework that touches DI, state and caching.
  - Bloc: explicit events and states, and easy to trace and test, but the most boilerplate.
  - Doomread's derived state is a pure reducer in plain Dart under any of the three, which narrows the impact of this choice.

## 7. Dart server options

- **Shelf** 1.4.3, published 5 days ago by tools.dart.dev, BSD-3. "Web server middleware". [pub](https://pub.dev/packages/shelf)
- **Dart Frog** 1.2.6, last published 11 months ago, MIT.
  - It is built on Shelf ([dart.dev/server](https://dart.dev/server)).
  - The repo moved to the `dart-frog-dev` org ("originally developed by" VGV) and was pushed 2026-10-01.
  - `dart_frog build` emits a Dockerfile.
  - Sources: [pub](https://pub.dev/packages/dart_frog), [repo](https://github.com/dart-frog-dev/dart_frog)
- **Serverpod** 4.0.4, 15 days ago. It generates client code and models, and runs on PostgreSQL with optional Redis ([pub](https://pub.dev/packages/serverpod)).
  - **The core `serverpod` package is SSPL-1.0** ([LICENSE](https://github.com/serverpod/serverpod/blob/main/packages/serverpod/LICENSE)). Its other packages are BSD-3.
- **Docker.** The official `dart` image recommends AOT-compiling the server, then `FROM scratch` with `COPY /runtime/`, for an image of about 10 MB. [image docs](https://github.com/docker-library/docs/blob/master/dart/content.md)
- **Code sharing.** dart.dev suggests a monorepo with a `shared` package for models, JSON and validation. [dart.dev/server](https://dart.dev/server)

## Implications for Doomread (inference)

1. **Follow the official layering.**
   - MVVM views and view models over abstract repositories and services, with fakes in `testing/`.
   - Use Compass's mixed layout: `ui/<feature>/` by feature, `data/` by type.
   - Put each Kotlin edge (accessibility, widget, notifications) behind its own service.
2. **Use a pub workspace from day one.**
   - `app/` (Flutter) and `packages/core/` (pure Dart: event types, the reducer for derived state, sync DTOs, Result).
   - Later, `server/` (Shelf or Dart Frog, AOT-built in Docker).
   - `core` runs under `dart test` with no Flutter.
   - Skip melos until CI needs cross-package scripts.
3. **Use drift for the event log.** It is the only candidate here that is active, permissively licensed, available on Linux, and has both streams and migration tooling.
   - Sync: push events newer than a cursor, with idempotent IDs. This goes beyond the official dirty-flag pattern.
   - **Verify before committing:** the `fdroid` build must not rely on the default binary download. Plan on `source: source` with a vendored `sqlite3.c`, and test it in an F-Droid-style offline build early.
   - Avoid Isar (the original is stalled, and only a fork is active) and ObjectBox (doubts about the core licence).
4. **Flavors.** Use the ADR-0004 names (`fdroid`, `play`, `bazaar`, `apk`) as Android `productFlavors`, read through `appFlavor`. Linux can use `--flavor` as of 3.47. VGV's dev/staging/prod split is optional.
5. **Quality gates.**
   - `gen-l10n` with `app_en.arb` and `app_fa.arb`.
   - RTL golden tests with real fonts, on one pinned CI OS.
   - `patrol` for permission flows.
   - `very_good_analysis` or `flutter_lints`.
6. **State management stays open** (see section 6). ChangeNotifier with provider diverges least from the docs.

## Open questions / unverified

- **ObjectBox core licence.** A search snippet of the ObjectBox FAQ says the core is not open source, but the page didn't load. F-Droid's anti-feature treatment is unconfirmed ([Izzy issue](https://gitlab.com/IzzyOnDroid/repo/-/issues/884), unanswered).
- **drift on F-Droid.** Does `sqlite3` `source: source` work with flavor-specific config? `user_defines` live in pubspec, not per flavor. Does F-Droid accept it?
- **Workspaces in Flutter apps.** The Flutter version that supports `resolution: workspace` is unconfirmed. Flutter 3.27 shipped Dart 3.6, per secondary sources only.
- **Dart Frog maintainer.** Who maintains it long-term after the move to `dart-frog-dev`?
- **Bloc's publish gap.** Is 17 months without a release stability or a slowdown?
- **Plugin dependencies.** Do `home_widget`, `patrol`, `workmanager` and similar plugins pull in Google dependencies that would affect the `fdroid` flavor? Not checked.
