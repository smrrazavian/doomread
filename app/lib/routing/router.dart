import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/account/view_models/account_view_model.dart';
import 'package:doomread/ui/account/widgets/account_screen.dart';
import 'package:doomread/ui/book/widgets/book_screen.dart';
import 'package:doomread/ui/books/widgets/books_screen.dart';
import 'package:doomread/ui/books/widgets/work_form_screen.dart';
import 'package:doomread/ui/building/widgets/building_screen.dart';
import 'package:doomread/ui/building/widgets/finish_screen.dart';
import 'package:doomread/ui/core/section_placeholder.dart';
import 'package:doomread/ui/evening/widgets/evening_screen.dart';
import 'package:doomread/ui/planned_break/widgets/planned_break_screen.dart';
import 'package:doomread/ui/reading/widgets/reading_screen.dart';
import 'package:doomread/ui/settings/widgets/settings_screen.dart';
import 'package:doomread/ui/tone/widgets/tone_screen.dart';
import 'package:doomread/ui/tonight/widgets/tonight_screen.dart';
import 'package:doomread/ui/watch/widgets/watched_apps_screen.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter buildRouter() {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/tonight',
    routes: _routes(root),
  );
}

List<RouteBase> _routes(GlobalKey<NavigatorState> root) => [
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => _NavShell(shell: shell),
    branches: [
      _branch('/tonight', (_) => const TonightScreen()),
      _branch('/books', (_) => const BooksScreen()),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/building',
            builder: (_, _) => const BuildingScreen(),
            routes: [
              // Over the whole app, without the nav bar; back lands on the
              // Building with its new floor.
              GoRoute(
                path: 'finish/:id',
                parentNavigatorKey: root,
                builder: (_, state) =>
                    FinishScreen(workId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      _branch(
        '/friends',
        (c) => SectionPlaceholder(title: AppLocalizations.of(c).navFriends),
      ),
    ],
  ),
  GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
  GoRoute(path: '/tone', builder: (_, _) => const ToneScreen()),
  GoRoute(path: '/watched', builder: (_, _) => const WatchedAppsScreen()),
  GoRoute(path: '/work/new', builder: (_, _) => const WorkFormScreen()),
  // ponytail: the Work travels as `extra`, so this route can't be
  // deep-linked; load it by id once something needs to link here.
  GoRoute(
    path: '/work/edit',
    builder: (_, state) => WorkFormScreen(editing: state.extra! as Work),
  ),
  GoRoute(
    path: '/reading/:id',
    builder: (_, state) =>
        ReadingScreen(sessionId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/break/:id',
    builder: (_, state) =>
        PlannedBreakScreen(sessionId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/evening/:id',
    builder: (_, state) =>
        EveningScreen(sessionId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/book/:id',
    builder: (_, state) => BookScreen(workId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/account',
    builder: (_, _) => ChangeNotifierProvider(
      create: (c) => AccountViewModel(c.read()),
      child: const AccountScreen(),
    ),
  ),
];

StatefulShellBranch _branch(String path, WidgetBuilder screen) =>
    StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (c, _) => screen(c))],
    );

class _NavShell extends StatelessWidget {
  const _NavShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.nightlight_outlined),
            label: l10n.navTonight,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            label: l10n.navBooks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.apartment_outlined),
            label: l10n.navBuilding,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            label: l10n.navFriends,
          ),
        ],
      ),
    );
  }
}
