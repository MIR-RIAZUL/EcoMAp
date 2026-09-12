import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'add_memory_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'memory_map_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

class MainNavScaffold extends ConsumerStatefulWidget {
  const MainNavScaffold({super.key});

  @override
  ConsumerState<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends ConsumerState<MainNavScaffold> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onNavigateToFavorites: () => _navigateToTab(3),
        onNavigateToMap: () => _navigateToTab(1),
      ),
      const MemoryMapScreen(),
      const TimelineScreen(),
      const FavoritesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 1
          // Floating Action Button on Map screen for quick add
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddMemoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add Memory'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon:
                Icon(Icons.timeline_rounded, color: AppColors.primary),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon:
                Icon(Icons.favorite_rounded, color: AppColors.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon:
                Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
