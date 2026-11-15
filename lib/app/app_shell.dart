import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation: Accueil · Explorer · Favoris · Messages · Profil.
/// The map is no longer a tab: it opens from Explorer, so while the map
/// branch (index 2) is active the "Explorer" tab stays highlighted.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  // Tab position -> router branch index (0 home, 1 search, 2 map, 3 favorites, 4 profile, 5 messages)
  static const _branches = [0, 1, 3, 5, 4];

  @override
  Widget build(BuildContext context) {
    final i = _branches.indexOf(shell.currentIndex);
    final selected = i == -1 ? 1 : i;

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (tab) {
          final branch = _branches[tab];
          shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorer'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoris'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}