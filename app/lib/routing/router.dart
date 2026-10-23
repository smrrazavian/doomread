import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/section_placeholder.dart';
import 'package:doomread/ui/settings/widgets/settings_screen.dart';
import 'package:doomread/ui/tonight/widgets/tonight_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/tonight',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _NavShell(shell: shell),
      branches: [
        _branch('/tonight', (_) => const TonightScreen()),
        _branch(
          '/books',
          (c) => SectionPlaceholder(title: AppLocalizations.of(c).navBooks),
        ),
        _branch(
          '/building',
          (c) => SectionPlaceholder(title: AppLocalizations.of(c).navBuilding),
        ),
        _branch(
          '/friends',
          (c) => SectionPlaceholder(title: AppLocalizations.of(c).navFriends),
        ),
      ],
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
  ],
);

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
