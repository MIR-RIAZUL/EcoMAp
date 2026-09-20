import 'package:flutter/material.dart';
import '../../../core/constants/mood_types.dart';
import '../../../core/theme/app_colors.dart';

class MoodSelector extends StatelessWidget {
  final Mood selectedMood;
  final ValueChanged<Mood> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How did you feel?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Mood.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final mood = Mood.values[index];
              final isSelected = mood == selectedMood;

              return GestureDetector(
                onTap: () => onMoodSelected(mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 74,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? mood.getBackgroundColor(isDark)
                        : (isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? mood.color
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: mood.color.withAlpha(isDark ? 50 : 70),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? mood.color
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
