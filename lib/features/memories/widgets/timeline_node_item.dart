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
            width: 48,
            child: Column(
              children: [
                // Top line
                Container(
                  width: 2.5,
                  height: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                // Mood Circle
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: memory.mood.getBackgroundColor(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: memory.mood.color,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: memory.mood.color.withAlpha(isDark ? 50 : 80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    memory.mood.emoji,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                // Bottom line
                Expanded(
                  child: Container(
                    width: isLast ? 0 : 2.5,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ],
            ),
          ),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16, left: 4),
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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Favorite Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormatter.formatDateTime(memory.dateTime),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            if (memory.isFavorite)
                              const Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: AppColors.favorite,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),

                        // Description
                        if (memory.description != null &&
                            memory.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            memory.description!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
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
                            child: Image.file(
                              File(memory.photoPath!),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],

                        // Location & tags
                        if ((memory.locationName != null &&
                                memory.locationName!.isNotEmpty) ||
                            memory.tags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (memory.locationName != null &&
                                  memory.locationName!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.place_rounded,
                                        size: 13, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      memory.locationName!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ...memory.tags.take(2).map(
                                    (tag) => Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.brightCyan
                                            : AppColors.tertiary,
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
