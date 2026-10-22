# Official Flutter MVVM architecture, with provider and ChangeNotifier

The app follows Flutter's official architecture guide: views and view models in `ui/<feature>/`, repositories and services in `data/`, and `Command` plus `Result` for actions. Dependency injection uses `provider`, view models extend `ChangeNotifier`, and routing uses `go_router` (its redirect handles signed-in vs signed-out, as in the Compass sample). Domain rules live in the pure-Dart `packages/core` instead of a use-case layer.

We considered Riverpod (more built in, one big framework) and Bloc (strict events, most boilerplate). We picked the officially documented stack because the hard logic is already in `core`, so the view models stay thin. Swapping later only touches view models.
