import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/mood_types.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/memory_item.dart';
import 'database_provider.dart';

// Stream of all memories
final allMemoriesStreamProvider = StreamProvider<List<MemoryItem>>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.watchAllMemories();
});

// Stream of favorite memories
final favoriteMemoriesStreamProvider = StreamProvider<List<MemoryItem>>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.watchFavoriteMemories();
});

// Single memory provider family
final memoryByIdProvider = FutureProvider.family<MemoryItem?, int>((ref, id) {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getMemoryById(id);
});

// Filter states
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedMoodFilterProvider = StateProvider<Mood?>((ref) => null);

// --- UPDATE 2: Search, Filter & Sorting System ---

enum MemorySortOrder {
  newestFirst,
  oldestFirst,
}

class MemoryFilterState {
  final String searchQuery;
  final Mood? mood;
  final bool favoritesOnly;
  final bool hasLocationOnly;
  final bool hasPhotoOnly;
  final MemorySortOrder sortOrder;

  const MemoryFilterState({
    this.searchQuery = '',
    this.mood,
    this.favoritesOnly = false,
    this.hasLocationOnly = false,
    this.hasPhotoOnly = false,
    this.sortOrder = MemorySortOrder.newestFirst,
  });

  bool get hasActiveFilters =>
      mood != null ||
      favoritesOnly ||
      hasLocationOnly ||
      hasPhotoOnly;

  bool get isFilteringOrSearching =>
      hasActiveFilters ||
      searchQuery.trim().isNotEmpty ||
      sortOrder != MemorySortOrder.newestFirst;

  int get activeFilterCount {
    int count = 0;
    if (mood != null) count++;
    if (favoritesOnly) count++;
    if (hasLocationOnly) count++;
    if (hasPhotoOnly) count++;
    if (sortOrder != MemorySortOrder.newestFirst) count++;
    return count;
  }

  MemoryFilterState copyWith({
    String? searchQuery,
    Mood? mood,
    bool clearMood = false,
    bool? favoritesOnly,
    bool? hasLocationOnly,
    bool? hasPhotoOnly,
    MemorySortOrder? sortOrder,
  }) {
    return MemoryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      mood: clearMood ? null : (mood ?? this.mood),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      hasLocationOnly: hasLocationOnly ?? this.hasLocationOnly,
      hasPhotoOnly: hasPhotoOnly ?? this.hasPhotoOnly,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  MemoryFilterState resetAll() {
    return const MemoryFilterState();
  }

  MemoryFilterState resetFilters() {
    return MemoryFilterState(
      searchQuery: searchQuery,
      sortOrder: MemorySortOrder.newestFirst,
    );
  }
}

final memoryFilterProvider =
    StateProvider<MemoryFilterState>((ref) => const MemoryFilterState());

// Filtered and sorted memories stream provider
final filteredMemoriesProvider = Provider<List<MemoryItem>>((ref) {
  final allAsync = ref.watch(allMemoriesStreamProvider);
  final filter = ref.watch(memoryFilterProvider);

  return allAsync.maybeWhen(
    data: (memories) {
      var result = [...memories];

      // 1. Text Search across Title, Description, Location Name, and Tags
      final query = filter.searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        result = result.where((m) {
          final titleMatch = m.title.toLowerCase().contains(query);
          final descMatch =
              m.description?.toLowerCase().contains(query) ?? false;
          final locationMatch =
              m.locationName?.toLowerCase().contains(query) ?? false;
          final tagMatch =
              m.tags.any((t) => t.toLowerCase().contains(query));
          return titleMatch || descMatch || locationMatch || tagMatch;
        }).toList();
      }

      // 2. Mood Filter
      if (filter.mood != null) {
        result = result.where((m) => m.mood == filter.mood).toList();
      }

      // 3. Favorites Only
      if (filter.favoritesOnly) {
        result = result.where((m) => m.isFavorite).toList();
      }

      // 4. Has Location Only
      if (filter.hasLocationOnly) {
        result = result.where((m) =>
            m.hasLocation ||
            (m.locationName != null && m.locationName!.trim().isNotEmpty)).toList();
      }

      // 5. Has Photo Only
      if (filter.hasPhotoOnly) {
        result = result.where((m) => m.hasPhoto).toList();
      }

      // 6. Sorting
      if (filter.sortOrder == MemorySortOrder.newestFirst) {
        result.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      } else {
        result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }

      return result;
    },
    orElse: () => [],
  );
});

// Recent memories (top 5)
final recentMemoriesProvider = Provider<List<MemoryItem>>((ref) {
  final allAsync = ref.watch(allMemoriesStreamProvider);
  return allAsync.maybeWhen(
    data: (memories) => memories.take(5).toList(),
    orElse: () => [],
  );
});

// Memory statistics data class
class MemoryStats {
  final int totalCount;
  final int favoriteCount;
  final int placesCount;
  final int photoCount;
  final Mood? topMood;
  final Map<Mood, int> moodCounts;

  const MemoryStats({
    required this.totalCount,
    required this.favoriteCount,
    required this.placesCount,
    required this.photoCount,
    this.topMood,
    required this.moodCounts,
  });
}

// Stats provider
final memoryStatsProvider = Provider<MemoryStats>((ref) {
  final allAsync = ref.watch(allMemoriesStreamProvider);
  return allAsync.maybeWhen(
    data: (memories) {
      final total = memories.length;
      final favorites = memories.where((m) => m.isFavorite).length;
      final places = memories
          .where((m) =>
              m.hasLocation ||
              (m.locationName != null && m.locationName!.trim().isNotEmpty))
          .length;
      final withPhotos = memories.where((m) => m.hasPhoto).length;

      final Map<Mood, int> moodMap = {};
      for (final m in memories) {
        moodMap[m.mood] = (moodMap[m.mood] ?? 0) + 1;
      }

      Mood? dominantMood;
      int maxCount = 0;
      moodMap.forEach((mood, count) {
        if (count > maxCount) {
          maxCount = count;
          dominantMood = mood;
        }
      });

      return MemoryStats(
        totalCount: total,
        favoriteCount: favorites,
        placesCount: places,
        photoCount: withPhotos,
        topMood: dominantMood,
        moodCounts: moodMap,
      );
    },
    orElse: () => const MemoryStats(
      totalCount: 0,
      favoriteCount: 0,
      placesCount: 0,
      photoCount: 0,
      moodCounts: {},
    ),
  );
});

// Timeline structure: Year -> Month -> Date -> Memories
class TimelineDayGroup {
  final DateTime dayDate;
  final String dayLabel; // e.g. "19 Sep"
  final String weekdayLabel; // e.g. "Fri, 19 Sep"
  final List<MemoryItem> memories;

  TimelineDayGroup({
    required this.dayDate,
    required this.dayLabel,
    required this.weekdayLabel,
    required this.memories,
  });
}

class TimelineMonthGroup {
  final String monthName;
  final int monthNumber;
  final List<TimelineDayGroup> days;

  TimelineMonthGroup({
    required this.monthName,
    required this.monthNumber,
    required this.days,
  });

  List<MemoryItem> get allMemories =>
      days.expand((day) => day.memories).toList();
}

class TimelineYearGroup {
  final String year;
  final int yearNumber;
  final List<TimelineMonthGroup> months;

  TimelineYearGroup({
    required this.year,
    required this.yearNumber,
    required this.months,
  });

  int get totalMemories =>
      months.fold(0, (sum, m) => sum + m.allMemories.length);
}

// Timeline grouped memories provider with search and mood filtering (Year -> Month -> Date)
final timelineGroupsProvider = Provider<List<TimelineYearGroup>>((ref) {
  final allAsync = ref.watch(allMemoriesStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final moodFilter = ref.watch(selectedMoodFilterProvider);

  return allAsync.maybeWhen(
    data: (memories) {
      // Sort newest first
      var filtered = [...memories]
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (query.isNotEmpty) {
        filtered = filtered.where((m) {
          final titleMatch = m.title.toLowerCase().contains(query);
          final descMatch =
              m.description?.toLowerCase().contains(query) ?? false;
          final locationMatch =
              m.locationName?.toLowerCase().contains(query) ?? false;
          final tagMatch =
              m.tags.any((t) => t.toLowerCase().contains(query));
          return titleMatch || descMatch || locationMatch || tagMatch;
        }).toList();
      }

      if (moodFilter != null) {
        filtered = filtered.where((m) => m.mood == moodFilter).toList();
      }

      // Group by Year -> Month -> Date (preserve sorted order — insertion order = newest first)
      final Map<int, Map<int, Map<int, List<MemoryItem>>>> grouped = {};

      for (final memory in filtered) {
        final year = memory.dateTime.year;
        final month = memory.dateTime.month;
        final day = memory.dateTime.day;

        grouped.putIfAbsent(year, () => {});
        grouped[year]!.putIfAbsent(month, () => {});
        grouped[year]![month]!.putIfAbsent(day, () => []);
        grouped[year]![month]![day]!.add(memory);
      }

      final List<TimelineYearGroup> result = [];

      // Sort years descending
      final sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      for (final year in sortedYears) {
        final monthsMap = grouped[year]!;
        final sortedMonths = monthsMap.keys.toList()..sort((a, b) => b.compareTo(a));
        final List<TimelineMonthGroup> monthGroups = [];

        for (final month in sortedMonths) {
          final daysMap = monthsMap[month]!;
          final sortedDays = daysMap.keys.toList()..sort((a, b) => b.compareTo(a));
          final List<TimelineDayGroup> dayGroups = [];

          String monthName = '';
          for (final day in sortedDays) {
            final items = daysMap[day]!;
            final firstDate = items.first.dateTime;
            monthName = DateFormatter.formatMonth(firstDate);

            dayGroups.add(
              TimelineDayGroup(
                dayDate: firstDate,
                dayLabel: DateFormatter.formatDayMonth(firstDate),
                weekdayLabel: DateFormatter.formatWeekdayDay(firstDate),
                memories: items,
              ),
            );
          }

          monthGroups.add(
            TimelineMonthGroup(
              monthName: monthName.isNotEmpty
                  ? monthName
                  : DateFormatter.formatMonth(DateTime(year, month)),
              monthNumber: month,
              days: dayGroups,
            ),
          );
        }

        result.add(
          TimelineYearGroup(
            year: year.toString(),
            yearNumber: year,
            months: monthGroups,
          ),
        );
      }

      return result;
    },
    orElse: () => [],
  );
});

// --- On This Day Feature ---

class OnThisDayMemory {
  final MemoryItem memory;
  final int yearsAgo;
  final String yearsAgoLabel;

  const OnThisDayMemory({
    required this.memory,
    required this.yearsAgo,
    required this.yearsAgoLabel,
  });
}

// Provider to find all memories from previous years matching today's month and day
final onThisDayMemoriesProvider = Provider<List<OnThisDayMemory>>((ref) {
  final allAsync = ref.watch(allMemoriesStreamProvider);
  final now = DateTime.now();

  return allAsync.maybeWhen(
    data: (memories) {
      final matches = memories.where((m) {
        return m.dateTime.month == now.month &&
            m.dateTime.day == now.day &&
            m.dateTime.year < now.year;
      }).toList();

      matches.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return matches.map((m) {
        final years = now.year - m.dateTime.year;
        final label = years == 1 ? '1 year ago' : '$years years ago';
        return OnThisDayMemory(
          memory: m,
          yearsAgo: years,
          yearsAgoLabel: label,
        );
      }).toList();
    },
    orElse: () => [],
  );
});

// Memories with valid coordinates for the Map view
final mapMemoriesProvider = Provider<List<MemoryItem>>((ref) {
  final allAsync = ref.watch(allMemoriesStreamProvider);
  final moodFilter = ref.watch(selectedMoodFilterProvider);

  return allAsync.maybeWhen(
    data: (memories) {
      var withCoords = memories.where((m) => m.hasLocation).toList();
      if (moodFilter != null) {
        withCoords = withCoords.where((m) => m.mood == moodFilter).toList();
      }
      return withCoords;
    },
    orElse: () => [],
  );
});
