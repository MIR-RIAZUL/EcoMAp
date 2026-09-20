import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/memory_item.dart';

class MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = memory.hasPhoto && File(memory.photoPath!).existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Header or Mood Banner
            if (hasPhoto)
              Stack(
                children: [
                  Hero(
                    tag: 'memory_image_${memory.id}',
                    child: Image.file(
                      File(memory.photoPath!),
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackBanner(isDark),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(80),
                            Colors.transparent,
                            Colors.black.withAlpha(120),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Mood pill on top left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildMoodBadge(isDark, onPhoto: true),
                  ),
                  // Favorite button on top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildFavoriteButton(isDark, onPhoto: true),
                  ),
                  // Date on bottom left over photo
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormatter.formatShortDate(memory.dateTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMoodBadge(isDark, onPhoto: false),
                    Row(
                      children: [
                        Text(
                          DateFormatter.formatShortDate(memory.dateTime),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        _buildFavoriteButton(isDark, onPhoto: false),
                      ],
                    ),
                  ],
                ),
              ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (memory.description != null &&
                      memory.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      memory.description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Location and Tags Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (memory.locationName != null &&
                          memory.locationName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.brightCyan
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
                                child: Text(
                                  memory.locationName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...memory.tags.take(3).map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.tertiary
                                        : AppColors.tertiaryContainer)
                                    .withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.brightCyan
                                      : AppColors.tertiary,
                                ),
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

  Widget _buildFallbackBanner(bool isDark) {
    return Container(
      height: 140,
      width: double.infinity,
      color: memory.mood.getBackgroundColor(isDark),
      alignment: Alignment.center,
      child: Text(
        memory.mood.emoji,
        style: const TextStyle(fontSize: 48),
      ),
    );
  }

  Widget _buildMoodBadge(bool isDark, {required bool onPhoto}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onPhoto
            ? Colors.black.withAlpha(160)
            : memory.mood.getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: memory.mood.color.withAlpha(onPhoto ? 160 : 80),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            memory.mood.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 5),
          Text(
            memory.mood.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: onPhoto ? Colors.white : memory.mood.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(bool isDark, {required bool onPhoto}) {
    return IconButton(
      onPressed: onToggleFavorite,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          memory.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          key: ValueKey(memory.isFavorite),
          color: memory.isFavorite
              ? AppColors.favorite
              : (onPhoto
                  ? Colors.white.withAlpha(220)
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
          size: 24,
        ),
      ),
      tooltip: memory.isFavorite ? 'Remove from favorites' : 'Mark as favorite',
    );
  }
}
