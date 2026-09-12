import 'package:drift/native.dart';
import 'package:echomap/core/constants/mood_types.dart';
import 'package:echomap/data/database/app_database.dart';
import 'package:echomap/data/repositories/memory_repository.dart';
import 'package:echomap/features/memories/models/memory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MemoryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = MemoryRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Insert and retrieve memory', () async {
    final now = DateTime.now();
    final memory = MemoryItem(
      id: 0,
      title: 'First day at university',
      description: 'I was nervous but excited about my first presentation.',
      mood: Mood.excited,
      dateTime: now,
      latitude: 23.7985,
      longitude: 90.4497,
      locationName: 'United International University',
      tags: ['University', 'Excited'],
      isFavorite: true,
      createdAt: now,
    );

    final insertedId = await repository.insertMemory(memory);
    expect(insertedId, greaterThan(0));

    final retrieved = await repository.getMemoryById(insertedId);
    expect(retrieved, isNotNull);
    expect(retrieved!.title, equals('First day at university'));
    expect(retrieved.mood, equals(Mood.excited));
    expect(retrieved.isFavorite, isTrue);
    expect(retrieved.locationName, equals('United International University'));
    expect(retrieved.tags, contains('University'));
  });

  test('Toggle favorite on memory', () async {
    final now = DateTime.now();
    final memory = MemoryItem(
      id: 0,
      title: 'Coffee with friends',
      description: 'Relaxing afternoon',
      mood: Mood.happy,
      dateTime: now,
      tags: ['Coffee'],
      isFavorite: false,
      createdAt: now,
    );

    final id = await repository.insertMemory(memory);
    await repository.toggleFavorite(id, false);

    final updated = await repository.getMemoryById(id);
    expect(updated!.isFavorite, isTrue);

    final favorites = await repository.getFavoriteMemories();
    expect(favorites.length, equals(1));
    expect(favorites.first.id, equals(id));
  });

  test('Get random memory', () async {
    final now = DateTime.now();
    final memory1 = MemoryItem(
      id: 0,
      title: 'Memory 1',
      mood: Mood.peaceful,
      dateTime: now,
      tags: [],
      createdAt: now,
    );
    final memory2 = MemoryItem(
      id: 0,
      title: 'Memory 2',
      mood: Mood.love,
      dateTime: now,
      tags: [],
      createdAt: now,
    );

    await repository.insertMemory(memory1);
    await repository.insertMemory(memory2);

    final random = await repository.getRandomMemory();
    expect(random, isNotNull);
    expect(['Memory 1', 'Memory 2'], contains(random!.title));
  });

  test('Delete memory', () async {
    final now = DateTime.now();
    final memory = MemoryItem(
      id: 0,
      title: 'Temporary moment',
      mood: Mood.neutral,
      dateTime: now,
      tags: [],
      createdAt: now,
    );

    final id = await repository.insertMemory(memory);
    expect(await repository.getMemoryById(id), isNotNull);

    await repository.deleteMemory(id);
    expect(await repository.getMemoryById(id), isNull);
  });
}
