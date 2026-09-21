import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/memory_providers.dart';
import 'memory_filter_sheet.dart';

class MemorySearchBar extends ConsumerStatefulWidget {
  const MemorySearchBar({super.key});

  @override
  ConsumerState<MemorySearchBar> createState() => _MemorySearchBarState();
}

class _MemorySearchBarState extends ConsumerState<MemorySearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(memoryFilterProvider).searchQuery;
    _controller = TextEditingController(text: initialQuery);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(memoryFilterProvider.notifier).update(
          (state) => state.copyWith(searchQuery: ''),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(memoryFilterProvider);

    // Sync controller if search query was cleared externally (e.g. Clear Filters)
    if (_controller.text != filterState.searchQuery) {
      _controller.value = TextEditingValue(
        text: filterState.searchQuery,
        selection: TextSelection.collapsed(offset: filterState.searchQuery.length),
      );
    }

    final hasActiveFilter = filterState.hasActiveFilters;
    final activeCount = filterState.activeFilterCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search Input Bar
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 25 : 8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Search memories...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary.withAlpha(160)
                              : AppColors.lightTextSecondary.withAlpha(160),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      onChanged: (val) {
                        ref.read(memoryFilterProvider.notifier).update(
                              (state) => state.copyWith(searchQuery: val),
                            );
                      },
                    ),
                  ),
                  if (filterState.searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
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
          const SizedBox(width: 10),

          // Filter Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => MemoryFilterSheet.show(context),
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasActiveFilter
                      ? (isDark ? AppColors.brightCyan : AppColors.primaryBlue)
                      : (isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: hasActiveFilter
                        ? (isDark ? AppColors.brightCyan : AppColors.primaryBlue)
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasActiveFilter
                          ? (isDark ? AppColors.brightCyan : AppColors.primaryBlue).withAlpha(80)
                          : Colors.black.withAlpha(isDark ? 25 : 8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: hasActiveFilter
                          ? (isDark ? AppColors.darkNavy : Colors.white)
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    ),
                    if (hasActiveFilter)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkNavy : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$activeCount',
                            style: TextStyle(
                              color: isDark ? AppColors.brightCyan : AppColors.primaryBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
