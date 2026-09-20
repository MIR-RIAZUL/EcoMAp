import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/memory_item.dart';

class MemoryPreviewSheet extends StatelessWidget {
  final MemoryItem memory;
  final VoidCallback onViewDetails;

  const MemoryPreviewSheet({
    super.key,
    required this.memory,
    required this.onViewDetails,
  });

  static void show(
    BuildContext context, {
    required MemoryItem memory,
    required VoidCallback onViewDetails,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryPreviewSheet(
        memory: memory,
        onViewDetails: () {
          Navigator.of(context).pop();
          onViewDetails();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = memory.hasPhoto && File(memory.photoPath!).existsSync();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail if photo exists, else mood box
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 84,
                  height: 84,
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
                            style: const TextStyle(fontSize: 34),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: memory.mood.getBackgroundColor(isDark),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: memory.mood.color.withAlpha(80),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(memory.mood.emoji,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                memory.mood.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: memory.mood.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (memory.isFavorite) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: AppColors.favorite,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      memory.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatFullDate(memory.dateTime),
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
            ],
          ),

          if (memory.locationName != null &&
              memory.locationName!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    memory.locationName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Open Full Details Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text('View Full Memory Details'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
