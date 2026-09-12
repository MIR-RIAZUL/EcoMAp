import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/database_provider.dart';
import '../providers/memory_providers.dart';
import '../widgets/memory_card.dart';
import 'add_memory_screen.dart';
import 'memory_details_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteMemoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.favorite, size: 22),
            SizedBox(width: 8),
            Text('Cherished Memories'),
          ],
        ),
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'No Favorites Yet',
              description:
                  'Memories that hold a special place in your heart will appear here. Tap the heart icon on any memory to favorite it!',
              actionLabel: 'Explore Memories',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddMemoryScreen(),
                  ),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final memory = favorites[index];
              return MemoryCard(
                memory: memory,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MemoryDetailsScreen(initialMemory: memory),
                    ),
                  );
                },
                onToggleFavorite: () {
                  ref
                      .read(memoryRepositoryProvider)
                      .toggleFavorite(memory.id, memory.isFavorite);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
