import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/mood_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/memory_providers.dart';
import '../widgets/timeline_node_item.dart';
import 'add_memory_screen.dart';
import 'memory_details_screen.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yearGroups = ref.watch(timelineGroupsProvider);
    final selectedMood = ref.watch(selectedMoodFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search memories, places, tags...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
              )
            : const Text('Memory Timeline'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mood Filter Horizontal Chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All Moods'),
                  selected: selectedMood == null,
                  onSelected: (_) {
                    ref.read(selectedMoodFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
                ...Mood.values.map((mood) {
                  final isSelected = selectedMood == mood;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Text(mood.emoji, style: const TextStyle(fontSize: 12)),
                      label: Text(mood.label),
                      selected: isSelected,
                      selectedColor: mood.getBackgroundColor(isDark),
                      onSelected: (val) {
                        ref.read(selectedMoodFilterProvider.notifier).state =
                            val ? mood : null;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Timeline Content
          Expanded(
            child: yearGroups.isEmpty
                ? EmptyStateView(
                    icon: Icons.timeline_rounded,
                    title: 'No Timeline Memories',
                    description:
                        'No memories found matching your search or filters. Capture a new moment to add to your story!',
                    actionLabel: 'Add Memory',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddMemoryScreen(),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: yearGroups.length,
                    itemBuilder: (context, yearIndex) {
                      final yearGroup = yearGroups[yearIndex];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Year Header Badge
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              yearGroup.year,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Month Groups
                          ...yearGroup.months.map((monthGroup) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Month Subheader with Memory Count
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, top: 12, bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.brightCyan
                                            : AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        monthGroup.monthName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.brightCyan
                                              : AppColors.primary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.navyBlue.withAlpha(160)
                                              : AppColors.primary.withAlpha(25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${monthGroup.allMemories.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.lightCyan
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Day Groups within Month
                                ...monthGroup.days.map((dayGroup) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Day Header Pill
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20, top: 8, bottom: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.brightCyan,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.brightCyan
                                                        .withAlpha(120),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              dayGroup.weekdayLabel,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.lightCyan
                                                    : AppColors.deepNavy,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Memories on this Date
                                      ...dayGroup.memories.asMap().entries.map(
                                        (entry) {
                                          final index = entry.key;
                                          final memory = entry.value;
                                          final isLast = index ==
                                              dayGroup.memories.length - 1;

                                          return TimelineNodeItem(
                                            memory: memory,
                                            isLast: isLast,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      MemoryDetailsScreen(
                                                    initialMemory: memory,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
