import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/memory_item.dart';

class TimelineNodeItem extends StatelessWidget {
  final MemoryItem memory;
  final bool isLast;
  final VoidCallback onTap;

  const TimelineNodeItem({
    super.key,
    required this.memory,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = memory.hasPhoto && File(memory.photoPath!).existsSync();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line and Mood Node
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Top vertical connector line
                Container(
                  width: 2,
                  height: 14,
                  color: isDark ? AppColors.navyBlue : AppColors.lightBorder,
                ),
                // Mood Circle Indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: memory.mood.getBackgroundColor(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.brightCyan : memory.mood.color,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.brightCyan : memory.mood.color)
                            .withAlpha(isDark ? 60 : 70),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    memory.mood.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // Bottom vertical connector line
                Expanded(
                  child: Container(
                    width: isLast ? 0 : 2,
                    color: isDark ? AppColors.navyBlue : AppColors.lightBorder,
                  ),
                ),
              ],
            ),
          ),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14, right: 8, left: 4),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time, Mood Label & Favorite
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.brightCyan
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatTime(memory.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.lightCyan
                                        : AppColors.deepNavy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: memory.mood.getBackgroundColor(isDark),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    memory.mood.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: memory.mood.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (memory.isFavorite)
                              const Icon(
                                Icons.favorite_rounded,
                                size: 15,
                                color: AppColors.favorite,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),

                        // Description preview
                        if (memory.description != null &&
                            memory.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            memory.description!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],

                        // Photo preview if available
                        if (hasPhoto) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Hero(
                              tag: 'memory_image_${memory.id}',
                              child: Image.file(
                                File(memory.photoPath!),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],

                        // Location & tags
                        if ((memory.locationName != null &&
                                memory.locationName!.isNotEmpty) ||
                            memory.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (memory.locationName != null &&
                                  memory.locationName!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.place_rounded,
                                      size: 13,
                                      color: isDark
                                          ? AppColors.brightCyan
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        memory.locationName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ...memory.tags.take(3).map(
                                    (tag) => Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.brightCyan
                                            : AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
