import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/memory_providers.dart';
import '../screens/memory_details_screen.dart';

class OnThisDayCard extends StatelessWidget {
  final List<OnThisDayMemory> memories;

  const OnThisDayCard({super.key, required this.memories});

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.navyBlue : AppColors.deepNavy,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.brightCyan.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 16,
                    color: AppColors.brightCyan,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'On This Day',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brightCyan.withAlpha(isDark ? 40 : 30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${memories.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brightCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Memories List / Carousel
          if (memories.length == 1)
            _buildSingleCard(context, memories.first, isDark)
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: memories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildCarouselCard(context, memories[index], isDark);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleCard(
      BuildContext context, OnThisDayMemory item, bool isDark) {
    final memory = item.memory;
    final hasPhoto = memory.hasPhoto && File(memory.photoPath!).existsSync();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.navyBlue.withAlpha(160),
                ]
              : [
                  AppColors.cyanSurface,
                  AppColors.secondaryContainer.withAlpha(120),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.brightCyan.withAlpha(80) : AppColors.primary.withAlpha(60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkNavy : AppColors.primary)
                .withAlpha(isDark ? 80 : 30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MemoryDetailsScreen(initialMemory: memory),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Photo thumbnail or Mood icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: hasPhoto
                        ? Hero(
                            tag: 'memory_image_${memory.id}',
                            child: Image.file(
                              File(memory.photoPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            color: memory.mood.getBackgroundColor(isDark),
                            alignment: Alignment.center,
                            child: Text(
                              memory.mood.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "X years ago" badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.brightCyan.withAlpha(40)
                              : AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: isDark
                                  ? AppColors.brightCyan
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.yearsAgoLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.brightCyan
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${DateFormatter.formatYear(memory.dateTime)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        memory.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Location if available
                      if (memory.locationName != null &&
                          memory.locationName!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 13,
                              color: isDark
                                  ? AppColors.brightCyan
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                memory.locationName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (memory.description != null &&
                          memory.description!.isNotEmpty)
                        Text(
                          memory.description!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.brightCyan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselCard(
      BuildContext context, OnThisDayMemory item, bool isDark) {
    final memory = item.memory;
    final hasPhoto = memory.hasPhoto && File(memory.photoPath!).existsSync();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.navyBlue : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MemoryDetailsScreen(initialMemory: memory),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image or Mood Header
            Stack(
              children: [
                SizedBox(
                  height: 95,
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
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                ),
                // Badge overlay
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.yearsAgoLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brightCyan,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(memory.mood.emoji,
                          style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          memory.locationName ??
                              DateFormatter.formatFullDate(memory.dateTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
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
