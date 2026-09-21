import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/mood_types.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/memory_providers.dart';

class MemoryFilterSheet extends ConsumerStatefulWidget {
  const MemoryFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MemoryFilterSheet(),
    );
  }

  @override
  ConsumerState<MemoryFilterSheet> createState() => _MemoryFilterSheetState();
}

class _MemoryFilterSheetState extends ConsumerState<MemoryFilterSheet> {
  late Mood? _selectedMood;
  late bool _favoritesOnly;
  late bool _hasLocationOnly;
  late bool _hasPhotoOnly;
  late MemorySortOrder _sortOrder;

  @override
  void initState() {
    super.initState();
    final current = ref.read(memoryFilterProvider);
    _selectedMood = current.mood;
    _favoritesOnly = current.favoritesOnly;
    _hasLocationOnly = current.hasLocationOnly;
    _hasPhotoOnly = current.hasPhotoOnly;
    _sortOrder = current.sortOrder;
  }

  bool get _hasAnyFilters =>
      _selectedMood != null ||
      _favoritesOnly ||
      _hasLocationOnly ||
      _hasPhotoOnly ||
      _sortOrder != MemorySortOrder.newestFirst;

  void _resetAll() {
    setState(() {
      _selectedMood = null;
      _favoritesOnly = false;
      _hasLocationOnly = false;
      _hasPhotoOnly = false;
      _sortOrder = MemorySortOrder.newestFirst;
    });
    ref.read(memoryFilterProvider.notifier).update(
          (state) => state.copyWith(
            clearMood: true,
            favoritesOnly: false,
            hasLocationOnly: false,
            hasPhotoOnly: false,
            sortOrder: MemorySortOrder.newestFirst,
          ),
        );
  }

  void _applyAndClose() {
    ref.read(memoryFilterProvider.notifier).update(
          (state) => state.copyWith(
            mood: _selectedMood,
            clearMood: _selectedMood == null,
            favoritesOnly: _favoritesOnly,
            hasLocationOnly: _hasLocationOnly,
            hasPhotoOnly: _hasPhotoOnly,
            sortOrder: _sortOrder,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Reset Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 22, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Filter & Sort',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_hasAnyFilters)
                      TextButton(
                        onPressed: _resetAll,
                        child: const Text('Clear Filters'),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 1. Mood Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Mood',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Mood.values.map((mood) {
                    final isSelected = _selectedMood == mood;
                    return FilterChip(
                      selected: isSelected,
                      avatar: Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      label: Text(mood.label),
                      selectedColor: mood.getBackgroundColor(isDark),
                      checkmarkColor:
                          isDark ? Colors.white : AppColors.lightTextPrimary,
                      onSelected: (selected) {
                        setState(() {
                          _selectedMood = selected ? mood : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // 2. Other Filters Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Other Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      selected: _favoritesOnly,
                      avatar: const Text('⭐', style: TextStyle(fontSize: 14)),
                      label: const Text('Favorites only'),
                      selectedColor: isDark ? AppColors.darkElevated : AppColors.lightCyan,
                      onSelected: (selected) {
                        setState(() => _favoritesOnly = selected);
                      },
                    ),
                    FilterChip(
                      selected: _hasLocationOnly,
                      avatar: const Text('📍', style: TextStyle(fontSize: 14)),
                      label: const Text('Memories with location'),
                      selectedColor: isDark ? AppColors.darkElevated : AppColors.lightCyan,
                      onSelected: (selected) {
                        setState(() => _hasLocationOnly = selected);
                      },
                    ),
                    FilterChip(
                      selected: _hasPhotoOnly,
                      avatar: const Text('📷', style: TextStyle(fontSize: 14)),
                      label: const Text('Memories with photo'),
                      selectedColor: isDark ? AppColors.darkElevated : AppColors.lightCyan,
                      onSelected: (selected) {
                        setState(() => _hasPhotoOnly = selected);
                      },
                    ),
                  ],
                ),
              ),

              // 3. Sorting Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<MemorySortOrder>(
                  segments: const [
                    ButtonSegment(
                      value: MemorySortOrder.newestFirst,
                      icon: Icon(Icons.arrow_downward_rounded, size: 16),
                      label: Text('Newest first'),
                    ),
                    ButtonSegment(
                      value: MemorySortOrder.oldestFirst,
                      icon: Icon(Icons.arrow_upward_rounded, size: 16),
                      label: Text('Oldest first'),
                    ),
                  ],
                  selected: {_sortOrder},
                  onSelectionChanged: (set) {
                    setState(() => _sortOrder = set.first);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (_hasAnyFilters) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetAll,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Clear Filters'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _applyAndClose,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? AppColors.brightCyan : AppColors.primaryBlue,
                          foregroundColor: isDark ? AppColors.darkNavy : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Show Memories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
