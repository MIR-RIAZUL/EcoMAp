import 'package:drift/native.dart';
import 'package:echomap/core/constants/mood_types.dart';
import 'package:echomap/core/utils/date_formatter.dart';
import 'package:echomap/data/database/app_database.dart';
import 'package:echomap/data/repositories/memory_repository.dart';
import 'package:echomap/features/memories/models/memory_item.dart';
import 'package:echomap/features/memories/providers/database_provider.dart';
import 'package:echomap/features/memories/providers/memory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MemoryRepository repo;
  late ProviderContainer container;

  final now = DateTime.now();

  // Dates for On This Day: same month+day, previous years
  final oneYearAgoToday = DateTime(now.year - 1, now.month, now.day, 10, 30);
  final twoYearsAgoToday = DateTime(now.year - 2, now.month, now.day, 15, 0);
  // Two memories on the same day last month (same year, same month, same day, different time)
  final lastMonth = now.month == 1 ? 12 : now.month - 1;
  final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
  final sameDayMorning = DateTime(lastMonthYear, lastMonth, 10, 9, 0);
  final sameDayEvening = DateTime(lastMonthYear, lastMonth, 10, 18, 0);

  // Memory templates (IDs will be auto-assigned by Drift)
  final memOneYearAgoTemplate = MemoryItem(
    id: 0,
    title: 'Trip to Paris 1 Year Ago',
    description: 'Eiffel Tower view',
    mood: Mood.excited,
    dateTime: oneYearAgoToday,
    locationName: 'Paris, France',
    latitude: 48.8566,
    longitude: 2.3522,
    tags: ['paris', 'travel'],
    isFavorite: true,
    createdAt: oneYearAgoToday,
  );

  final memTwoYearsAgoTemplate = MemoryItem(
    id: 0,
    title: 'Beach Day 2 Years Ago',
    description: 'Golden hour sunset',
    mood: Mood.happy,
    dateTime: twoYearsAgoToday,
    locationName: "Cox's Bazar",
    latitude: 21.4272,
    longitude: 92.0058,
    tags: ['beach', 'sunset'],
    isFavorite: false,
    createdAt: twoYearsAgoToday,
  );

  final memLastMonth1Template = MemoryItem(
    id: 0,
    title: 'Morning Coffee',
    description: 'Espresso shot',
    mood: Mood.peaceful,
    dateTime: sameDayMorning,
    tags: ['coffee'],
    isFavorite: true,
    createdAt: sameDayMorning,
  );

  final memLastMonth2Template = MemoryItem(
    id: 0,
    title: 'Evening Walk',
    description: 'Strolling in park',
    mood: Mood.peaceful,
    dateTime: sameDayEvening,
    tags: ['walk', 'relax'],
    isFavorite: false,
    createdAt: sameDayEvening,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemoryRepositoryImpl(db);

    await repo.insertMemory(memOneYearAgoTemplate);
    await repo.insertMemory(memTwoYearsAgoTemplate);
    await repo.insertMemory(memLastMonth1Template);
    await repo.insertMemory(memLastMonth2Template);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        memoryRepositoryProvider.overrideWithValue(repo),
      ],
    );

    await container.read(allMemoriesStreamProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Update 5: On This Day Provider', () {
    test('Correctly identifies and calculates memories occurring on this date in past years', () {
      final onThisDayList = container.read(onThisDayMemoriesProvider);

      expect(onThisDayList.length, equals(2));

      // Sorted by newest year first (1 year ago before 2 years ago)
      expect(onThisDayList[0].yearsAgo, equals(1));
      expect(onThisDayList[0].yearsAgoLabel, equals('1 year ago'));
      expect(onThisDayList[0].memory.title, equals('Trip to Paris 1 Year Ago'));

      expect(onThisDayList[1].yearsAgo, equals(2));
      expect(onThisDayList[1].yearsAgoLabel, equals('2 years ago'));
      expect(onThisDayList[1].memory.title, equals('Beach Day 2 Years Ago'));
    });

    test('Does NOT include current year memories in On This Day', () {
      final onThisDayList = container.read(onThisDayMemoriesProvider);
      // None of the sameDayMorning or sameDayEvening memories should appear
      // because they are from lastMonth (different day), not today
      for (final item in onThisDayList) {
        expect(item.memory.dateTime.year < now.year, isTrue);
      }
    });
  });

  group('Update 5: Timeline Hierarchical Grouping (Year -> Month -> Day -> Memories)', () {
    test('Groups memories chronologically into Year -> Month -> Day structure', () {
      final yearGroups = container.read(timelineGroupsProvider);

      expect(yearGroups.isNotEmpty, isTrue);

      // Check year ordering (newest year first)
      final years = yearGroups.map((g) => int.parse(g.year)).toList();
      for (int i = 0; i < years.length - 1; i++) {
        expect(years[i] >= years[i + 1], isTrue,
            reason: 'Years should be in descending order');
      }
    });

    test('Two memories on the same day are grouped under the same day node', () {
      final yearGroups = container.read(timelineGroupsProvider);

      bool foundSameDayGroup = false;
      for (final yg in yearGroups) {
        for (final mg in yg.months) {
          for (final dg in mg.days) {
            if (dg.memories.any((m) => m.title == 'Morning Coffee') &&
                dg.memories.any((m) => m.title == 'Evening Walk')) {
              foundSameDayGroup = true;
              expect(dg.memories.length, equals(2));
            }
          }
        }
      }
      expect(foundSameDayGroup, isTrue,
          reason: 'Same-day memories must share a single day group');
    });

    test('All 4 inserted memories appear in the timeline', () {
      final yearGroups = container.read(timelineGroupsProvider);
      final allMemoriesInTimeline = yearGroups
          .expand((y) => y.months)
          .expand((m) => m.days)
          .expand((d) => d.memories)
          .toList();

      expect(allMemoriesInTimeline.length, equals(4));
    });
  });

  group('Update 5: DateFormatter Methods', () {
    test('formatDayMonth, formatWeekdayDay, formatDayNumber, and formatYearsAgo format as expected', () {
      final sampleDate = DateTime(2025, 9, 21, 14, 30);

      expect(DateFormatter.formatDayMonth(sampleDate), equals('21 Sep'));
      expect(DateFormatter.formatWeekdayDay(sampleDate), contains('21 Sep'));
      expect(DateFormatter.formatDayNumber(sampleDate), equals('21'));

      // formatYearsAgo takes a DateTime (the memory's date) and computes years from now
      final oneYearAgo = DateTime(DateTime.now().year - 1, DateTime.now().month, DateTime.now().day);
      final threeYearsAgo = DateTime(DateTime.now().year - 3, DateTime.now().month, DateTime.now().day);
      expect(DateFormatter.formatYearsAgo(oneYearAgo), equals('1 year ago'));
      expect(DateFormatter.formatYearsAgo(threeYearsAgo), equals('3 years ago'));
    });
  });
}
