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

// Timeline structure
class TimelineMonthGroup {
  final String monthName;
  final List<MemoryItem> memories;

  TimelineMonthGroup({required this.monthName, required this.memories});
}

class TimelineYearGroup {
  final String year;
  final List<TimelineMonthGroup> months;

  TimelineYearGroup({required this.year, required this.months});
}

// Timeline grouped memories provider with search and mood filtering
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

      // Group by Year -> Month (preserve sorted order — insertion order = newest first)
      final Map<String, Map<String, List<MemoryItem>>> grouped =
          {};

      for (final memory in filtered) {
        final year = DateFormatter.formatYear(memory.dateTime);
        final month = DateFormatter.formatMonth(memory.dateTime);

        grouped.putIfAbsent(year, () => {});
        grouped[year]!.putIfAbsent(month, () => []);
        grouped[year]![month]!.add(memory);
      }

      final List<TimelineYearGroup> result = [];
      grouped.forEach((year, monthsMap) {
        final List<TimelineMonthGroup> monthGroups = [];
        monthsMap.forEach((month, items) {
          monthGroups.add(TimelineMonthGroup(monthName: month, memories: items));
        });
        result.add(TimelineYearGroup(year: year, months: monthGroups));
      });

      return result;
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
