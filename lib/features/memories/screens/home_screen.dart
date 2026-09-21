import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../models/memory_item.dart';
import '../providers/database_provider.dart';
import '../providers/memory_providers.dart';
import '../widgets/memory_card.dart';
import '../widgets/memory_search_bar.dart';
import '../widgets/stats_overview_card.dart';
import 'add_memory_screen.dart';
import 'memory_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToFavorites;
  final VoidCallback onNavigateToMap;

  const HomeScreen({
    super.key,
    required this.onNavigateToFavorites,
    required this.onNavigateToMap,
  });

  Future<void> _handleSurpriseMe(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(memoryRepositoryProvider);
    final randomMemory = await repo.getRandomMemory();

    if (!context.mounted) return;

    if (randomMemory == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.auto_awesome_rounded,
              size: 36, color: AppColors.primary),
          title: const Text('No Memories Yet'),
          content: const Text(
            'Create your first memory to unlock the Surprise Me nostalgia feature!',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddMemoryScreen(),
                  ),
                );
              },
              child: const Text('Capture First Memory'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoryDetailsScreen(initialMemory: randomMemory),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMemoriesAsync = ref.watch(allMemoriesStreamProvider);
    final favoriteMemoriesAsync = ref.watch(favoriteMemoriesStreamProvider);
    final stats = ref.watch(memoryStatsProvider);
    final filterState = ref.watch(memoryFilterProvider);
    final filteredMemories = ref.watch(filteredMemoriesProvider);
    final isFilteringOrSearching = filterState.isFilteringOrSearching;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar / Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.navyBlue : AppColors.deepNavy,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.brightCyan.withAlpha(120),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.explore_rounded,
                                size: 18,
                                color: AppColors.brightCyan,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your life as a living memory map',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Surprise Me Pill Button
                    FilledButton.tonalIcon(
                      onPressed: () => _handleSurpriseMe(context, ref),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Surprise Me'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // UPDATE 2: Search Bar at the top of Memories screen
            const SliverToBoxAdapter(
              child: MemorySearchBar(),
            ),

            // Active Filters Strip & Result Count (when searching or filtering)
            if (isFilteringOrSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (filterState.mood != null) ...[
                              Chip(
                                avatar: Text(
                                  filterState.mood!.emoji,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                label: Text(filterState.mood!.label),
                                onDeleted: () {
                                  ref
                                      .read(memoryFilterProvider.notifier)
                                      .update(
                                        (s) => s.copyWith(clearMood: true),
                                      );
                                },
                                deleteIconColor: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (filterState.favoritesOnly) ...[
                              Chip(
                                avatar: const Text('⭐',
                                    style: TextStyle(fontSize: 12)),
                                label: const Text('Favorites'),
                                onDeleted: () {
                                  ref
                                      .read(memoryFilterProvider.notifier)
                                      .update(
                                        (s) => s.copyWith(favoritesOnly: false),
                                      );
                                },
                                deleteIconColor: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (filterState.hasLocationOnly) ...[
                              Chip(
                                avatar: const Text('📍',
                                    style: TextStyle(fontSize: 12)),
                                label: const Text('With location'),
                                onDeleted: () {
                                  ref
                                      .read(memoryFilterProvider.notifier)
                                      .update(
                                        (s) =>
                                            s.copyWith(hasLocationOnly: false),
                                      );
                                },
                                deleteIconColor: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (filterState.hasPhotoOnly) ...[
                              Chip(
                                avatar: const Text('📷',
                                    style: TextStyle(fontSize: 12)),
                                label: const Text('With photo'),
                                onDeleted: () {
                                  ref
                                      .read(memoryFilterProvider.notifier)
                                      .update(
                                        (s) => s.copyWith(hasPhotoOnly: false),
                                      );
                                },
                                deleteIconColor: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (filterState.sortOrder ==
                                MemorySortOrder.oldestFirst) ...[
                              Chip(
                                avatar: const Icon(Icons.arrow_upward_rounded,
                                    size: 14),
                                label: const Text('Oldest first'),
                                onDeleted: () {
                                  ref
                                      .read(memoryFilterProvider.notifier)
                                      .update(
                                        (s) => s.copyWith(
                                            sortOrder:
                                                MemorySortOrder.newestFirst),
                                      );
                                },
                                deleteIconColor: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                            ],
                            ActionChip(
                              avatar: const Icon(Icons.close_rounded, size: 14),
                              label: const Text('Clear Filters'),
                              onPressed: () {
                                ref
                                    .read(memoryFilterProvider.notifier)
                                    .state = const MemoryFilterState();
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Small Result Count
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          filteredMemories.length == 1
                              ? '1 memory found'
                              : '${filteredMemories.length} memories found',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Overview sections when NOT searching or filtering
            if (!isFilteringOrSearching) ...[
              // Stats Overview Card
              SliverToBoxAdapter(
                child: StatsOverviewCard(
                  stats: stats,
                  onFavoritesTap: onNavigateToFavorites,
                ),
              ),

              // Quick Add Hero Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddMemoryScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  AppColors.navyBlue,
                                  AppColors.primaryBlue,
                                ]
                              : [
                                  AppColors.deepNavy,
                                  AppColors.primaryBlue,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepNavy.withAlpha(isDark ? 80 : 50),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brightCyan.withAlpha(40),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.brightCyan.withAlpha(80),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: AppColors.brightCyan,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record a New Memory',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Capture location, photos, mood & thoughts',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Favorite Memories Carousel Section
              favoriteMemoriesAsync.when(
                data: (favorites) {
                  if (favorites.isEmpty) return const SliverToBoxAdapter();
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.favorite_rounded,
                                      color: AppColors.favorite, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Cherished Favorites',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: onNavigateToFavorites,
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: favorites.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final memory = favorites[index];
                              return _buildFavoriteCarouselItem(
                                  context, memory, isDark);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(),
                error: (_, __) => const SliverToBoxAdapter(),
              ),

              // Memories Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Memories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (stats.placesCount > 0)
                        TextButton.icon(
                          onPressed: onNavigateToMap,
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('View on Map'),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Memories List / Empty State
            allMemoriesAsync.when(
              data: (allMemories) {
                // If there are no memories at all in the database, keep existing empty state
                if (allMemories.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyStateView(
                      icon: Icons.history_edu_rounded,
                      title: 'Your Memory Map is Fresh',
                      description:
                          'You have not recorded any memories yet. Tap the button below to capture your very first moment!',
                      actionLabel: 'Create First Memory',
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddMemoryScreen(),
                          ),
                        );
                      },
                    ),
                  );
                }

                // If user filtered/searched and no matches found
                if (filteredMemories.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: 'No memories found',
                      description:
                          'Try a different search or clear your filters.',
                      actionLabel: 'Clear Filters',
                      actionIcon: Icons.filter_alt_off_rounded,
                      onAction: () {
                        ref
                            .read(memoryFilterProvider.notifier)
                            .state = const MemoryFilterState();
                      },
                    ),
                  );
                }

                // Display filtered/sorted memories
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final memory = filteredMemories[index];
                      return MemoryCard(
                        memory: memory,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MemoryDetailsScreen(initialMemory: memory),
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
                    childCount: filteredMemories.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading memories: $err'),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCarouselItem(
      BuildContext context, MemoryItem memory, bool isDark) {
    final hasPhoto = memory.hasPhoto && File(memory.photoPath!).existsSync();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryDetailsScreen(initialMemory: memory),
          ),
        );
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or Mood Header
            SizedBox(
              height: 105,
              width: double.infinity,
              child: hasPhoto
                  ? Image.file(
                      File(memory.photoPath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: memory.mood.getBackgroundColor(isDark),
                      alignment: Alignment.center,
                      child: Text(
                        memory.mood.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(memory.mood.emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormatter.formatShortDate(memory.dateTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: AppColors.favorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    memory.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
