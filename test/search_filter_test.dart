import 'package:drift/native.dart';
import 'package:echomap/core/constants/mood_types.dart';
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

  final memory1 = MemoryItem(
    id: 1,
    title: 'First day at University',
    description: 'Nervous presentation',
    mood: Mood.excited,
    dateTime: now.subtract(const Duration(days: 10)),
    locationName: 'United International University',
    latitude: 23.79,
    longitude: 90.44,
    tags: ['university', 'campus'],
    isFavorite: true,
    createdAt: now.subtract(const Duration(days: 10)),
  );

  final memory2 = MemoryItem(
    id: 2,
    title: 'Coffee in the rain',
    description: 'Lovely cafe vibes',
    mood: Mood.happy,
    dateTime: now.subtract(const Duration(days: 5)),
    locationName: 'North End Cafe',
    latitude: 23.78,
    longitude: 90.42,
    tags: ['coffee', 'rain'],
    isFavorite: true,
    photoPath: '/path/to/photo.jpg',
    createdAt: now.subtract(const Duration(days: 5)),
  );

  final memory3 = MemoryItem(
    id: 3,
    title: 'Sad departure',
    description: 'Saying goodbye',
    mood: Mood.sad,
    dateTime: now.subtract(const Duration(days: 1)),
    tags: ['farewell'],
    isFavorite: false,
    createdAt: now.subtract(const Duration(days: 1)),
  );

  final memory4 = MemoryItem(
    id: 4,
    title: 'Quiet park meditation',
    description: 'Found inner peace',
    mood: Mood.peaceful,
    dateTime: now,
    tags: ['peace', 'relax'],
    isFavorite: false,
    photoPath: '/path/to/park.jpg',
    createdAt: now,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemoryRepositoryImpl(db);

    await repo.insertMemory(memory1);
    await repo.insertMemory(memory2);
    await repo.insertMemory(memory3);
    await repo.insertMemory(memory4);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        memoryRepositoryProvider.overrideWithValue(repo),
      ],
    );

    // Warm up the allMemoriesStreamProvider
    await container.read(allMemoriesStreamProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Update 2: Search Functionality', () {
    test('Search by title (case-insensitive)', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(searchQuery: 'uNiVeRsItY'));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(1));
      expect(results.first.title, equals('First day at University'));
    });

    test('Search by description', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(searchQuery: 'presentation'));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(1));
      expect(results.first.id, equals(1));
    });

    test('Search by location name', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(searchQuery: 'north end'));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(1));
      expect(results.first.title, equals('Coffee in the rain'));
    });

    test('Search by tag', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(searchQuery: 'campus'));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(1));
      expect(results.first.id, equals(1));
    });
  });

  group('Update 2: Filter Functionality', () {
    test('Filter by mood', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(mood: Mood.happy));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(1));
      expect(results.first.mood, equals(Mood.happy));
    });

    test('Filter by favorites only', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(favoritesOnly: true));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(2));
      expect(results.every((m) => m.isFavorite), isTrue);
    });

    test('Filter by memories with location', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(hasLocationOnly: true));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(2));
      expect(results.every((m) => m.hasLocation), isTrue);
    });

    test('Filter by memories with photo', () {
      container
          .read(memoryFilterProvider.notifier)
          .update((s) => s.copyWith(hasPhotoOnly: true));

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(2));
      expect(results.every((m) => m.hasPhoto), isTrue);
    });

    test('Combined filters: Happy + Favorites', () {
      container.read(memoryFilterProvider.notifier).update(
            (s) => s.copyWith(mood: Mood.happy, favoritesOnly: true),
          );

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(1));
      expect(results.first.title, equals('Coffee in the rain'));
    });

    test('Combined filters with search: Favorites + location + search "coffee"', () {
      container.read(memoryFilterProvider.notifier).update(
            (s) => s.copyWith(
              searchQuery: 'coffee',
              favoritesOnly: true,
              hasLocationOnly: true,
            ),
          );

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(1));
      expect(results.first.title, equals('Coffee in the rain'));
    });
  });

  group('Update 2: Sorting Functionality', () {
    test('Default sorting is newest first', () {
      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(4));
      // Memory 4 is now, Memory 3 is 1 day ago, etc.
      expect(results[0].id, equals(4));
      expect(results[1].id, equals(3));
      expect(results[2].id, equals(2));
      expect(results[3].id, equals(1));
    });

    test('Oldest first sorting', () {
      container.read(memoryFilterProvider.notifier).update(
            (s) => s.copyWith(sortOrder: MemorySortOrder.oldestFirst),
          );

      final results = container.read(filteredMemoriesProvider);
      expect(results.length, equals(4));
      expect(results[0].id, equals(1));
      expect(results[1].id, equals(2));
      expect(results[2].id, equals(3));
      expect(results[3].id, equals(4));
    });
  });

  group('Update 2: Clear Filters', () {
    test('Reset all filters restores state and default sorting', () {
      container.read(memoryFilterProvider.notifier).update(
            (s) => s.copyWith(
              searchQuery: 'something',
              mood: Mood.angry,
              favoritesOnly: true,
              hasLocationOnly: true,
              hasPhotoOnly: true,
              sortOrder: MemorySortOrder.oldestFirst,
            ),
          );

      expect(container.read(memoryFilterProvider).isFilteringOrSearching, isTrue);

      container.read(memoryFilterProvider.notifier).state = const MemoryFilterState();

      final state = container.read(memoryFilterProvider);
      expect(state.searchQuery, isEmpty);
      expect(state.mood, isNull);
      expect(state.favoritesOnly, isFalse);
      expect(state.hasLocationOnly, isFalse);
      expect(state.hasPhotoOnly, isFalse);
      expect(state.sortOrder, equals(MemorySortOrder.newestFirst));
      expect(state.isFilteringOrSearching, isFalse);
    });
  });
}
