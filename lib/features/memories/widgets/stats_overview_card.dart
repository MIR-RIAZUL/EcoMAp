import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/memory_providers.dart';

class StatsOverviewCard extends StatelessWidget {
  final MemoryStats stats;
  final VoidCallback? onFavoritesTap;

  const StatsOverviewCard({
    super.key,
    required this.stats,
    this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0C234E),
                  const Color(0xFF071A3D),
                ]
              : [
                  const Color(0xFFE8F4FD),
                  const Color(0xFFF4F8FC),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withAlpha(50)
              : AppColors.primary.withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Memory Capsule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (stats.topMood != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stats.topMood!.getBackgroundColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: stats.topMood!.color.withAlpha(90),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(stats.topMood!.emoji,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        'Mostly ${stats.topMood!.label}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: stats.topMood!.color,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatItem(
                context,
                title: 'Memories',
                count: stats.totalCount.toString(),
                icon: Icons.bookmark_added_rounded,
                color: AppColors.primary,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildStatItem(
                context,
                title: 'Favorites',
                count: stats.favoriteCount.toString(),
                icon: Icons.favorite_rounded,
                color: AppColors.favorite,
                isDark: isDark,
                onTap: onFavoritesTap,
              ),
              _buildDivider(isDark),
              _buildStatItem(
                context,
                title: 'Places',
                count: stats.placesCount.toString(),
                icon: Icons.place_rounded,
                color: AppColors.tertiary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 36,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
