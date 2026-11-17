import 'package:drift/native.dart';
import 'package:echomap/core/constants/mood_types.dart';
import 'package:echomap/data/database/app_database.dart';
import 'package:echomap/data/repositories/memory_repository.dart';
import 'package:echomap/features/backup/services/cloud_sync_service.dart';
import 'package:echomap/features/backup/services/supabase_storage_service.dart';
import 'package:echomap/features/memories/models/memory_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Update 6: Supabase Schema Mapping & Data Integrity', () {
    test('MemoryItem correctly maps to Supabase public.memories JSON', () {
      final now = DateTime(2026, 11, 12, 10, 30);
      final memory = MemoryItem(
        id: 1,
        cloudId: '11111111-2222-3333-4444-555555555555',
        title: 'Sunset at Cox Bazar',
        description: 'Breathtaking ocean colors with friends',
        photoPath: '/local/path/to/sunset.jpg',
        dateTime: now,
        latitude: 21.4272,
        longitude: 92.0058,
        locationName: "Cox's Bazar Sea Beach",
        mood: Mood.happy,
        tags: ['beach', 'sunset', 'vacation'],
        isFavorite: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      );

      const userId = 'user-uuid-9999-8888';
      const cloudPhoto = 'user-uuid-9999-8888/11111111-2222-3333-4444-555555555555/sunset.jpg';

      final json = memory.toSupabaseJson(
        userId: userId,
        cloudPhotoPath: cloudPhoto,
      );

      // Verify all columns required by Supabase public.memories
      expect(json['id'], equals('11111111-2222-3333-4444-555555555555'));
      expect(json['user_id'], equals(userId));
      expect(json['title'], equals('Sunset at Cox Bazar'));
      expect(json['description'], equals('Breathtaking ocean colors with friends'));
      expect(json['photo_path'], equals(cloudPhoto));
      expect(json['date_time'], equals(now.toUtc().toIso8601String()));
      expect(json['latitude'], equals(21.4272));
      expect(json['longitude'], equals(92.0058));
      expect(json['location_name'], equals("Cox's Bazar Sea Beach"));
      expect(json['mood'], equals('happy'));
      expect(json['tags'], equals('beach, sunset, vacation'));
      expect(json['is_favorite'], isTrue);
      expect(json['created_at'], equals(now.subtract(const Duration(hours: 2)).toUtc().toIso8601String()));
      expect(json['updated_at'], equals(now.toUtc().toIso8601String()));
    });

    test('MemoryItem correctly parses from Supabase public.memories JSON', () {
      final cloudJson = {
        'id': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        'user_id': 'user-12345',
        'title': 'Coffee at North End',
        'description': 'Working on EchoMap v6',
        'photo_path': 'user-12345/a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d/coffee.jpg',
        'date_time': '2026-11-10T08:30:00.000Z',
        'latitude': 23.7925,
        'longitude': 90.4078,
        'location_name': 'Gulshan 2, Dhaka',
        'mood': 'excited',
        'tags': 'coffee, coding, productive',
        'is_favorite': true,
        'created_at': '2026-11-10T08:35:00.000Z',
        'updated_at': '2026-11-10T09:00:00.000Z',
      };

      final memory = MemoryItem.fromSupabaseJson(
        cloudJson,
        localPhotoPath: '/local/cache/coffee.jpg',
        localId: 42,
      );

      expect(memory.id, equals(42));
      expect(memory.cloudId, equals('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'));
      expect(memory.title, equals('Coffee at North End'));
      expect(memory.description, equals('Working on EchoMap v6'));
      expect(memory.photoPath, equals('/local/cache/coffee.jpg'));
      expect(memory.latitude, equals(23.7925));
      expect(memory.longitude, equals(90.4078));
      expect(memory.locationName, equals('Gulshan 2, Dhaka'));
      expect(memory.mood, equals(Mood.excited));
      expect(memory.tags, equals(['coffee', 'coding', 'productive']));
      expect(memory.isFavorite, isTrue);
      expect(memory.dateTime.toUtc(), equals(DateTime.parse('2026-11-10T08:30:00.000Z')));
    });

    test('SupabaseStorageService builds exact required private object path', () {
      const userId = 'usr-789';
      const memoryId = 'mem-456';
      const fileName = 'my_vacation_photo.jpg';

      final path = SupabaseStorageService.buildObjectPath(
        userId: userId,
        memoryId: memoryId,
        fileName: fileName,
      );

      // Section 5: Structure user-id/memory-id/filename.jpg
      expect(path, equals('usr-789/mem-456/my_vacation_photo.jpg'));
    });
  });

  group('Update 6: Local Mode & Offline-First Safety', () {
    late AppDatabase db;
    late MemoryRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      repo = MemoryRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Local memories can be created, edited, and queried offline without Supabase', () async {
      final now = DateTime.now();
      final memory = MemoryItem(
        id: 0,
        title: 'Offline Reflection',
        description: 'Captured in the mountains with no cell service',
        mood: Mood.peaceful,
        dateTime: now,
        tags: ['offline', 'nature'],
        isFavorite: false,
        createdAt: now,
      );

      final insertedId = await repo.insertMemory(memory);
      expect(insertedId, greaterThan(0));

      // Retrieve and verify
      final retrieved = await repo.getMemoryById(insertedId);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Offline Reflection'));
      expect(retrieved.cloudId, isNotNull); // Automatically assigned a UUID
      expect(retrieved.cloudId!.isNotEmpty, isTrue);

      // Edit offline
      final updated = retrieved.copyWith(
        title: 'Offline Reflection (Edited)',
        isFavorite: true,
      );
      await repo.updateMemory(updated);

      final reFetched = await repo.getMemoryById(insertedId);
      expect(reFetched!.title, equals('Offline Reflection (Edited)'));
      expect(reFetched.isFavorite, isTrue);
    });

    test('Deleting local memory tracks its cloudId for safe cloud synchronization', () async {
      final now = DateTime.now();
      final memory = MemoryItem(
        id: 0,
        cloudId: 'delete-me-uuid-1234',
        title: 'Soon to be removed',
        mood: Mood.neutral,
        dateTime: now,
        tags: [],
        createdAt: now,
      );

      final insertedId = await repo.insertMemory(memory);
      expect(await repo.getMemoryById(insertedId), isNotNull);

      // Delete memory
      await repo.deleteMemory(insertedId);

      // Check deleted list
      final pendingDeletes = await repo.getPendingDeletedCloudIds();
      expect(pendingDeletes, contains('delete-me-uuid-1234'));

      // Clear pending
      await repo.clearPendingDeletedCloudIds(['delete-me-uuid-1234']);
      final remaining = await repo.getPendingDeletedCloudIds();
      expect(remaining, isEmpty);
    });

    test('Sync failures do not destroy or corrupt local memories', () async {
      final now = DateTime.now();
      await repo.insertMemory(MemoryItem(
        id: 0,
        title: 'Safe Memory 1',
        mood: Mood.happy,
        dateTime: now,
        tags: ['safe'],
        createdAt: now,
      ));
      await repo.insertMemory(MemoryItem(
        id: 0,
        title: 'Safe Memory 2',
        mood: Mood.excited,
        dateTime: now,
        tags: ['safe'],
        createdAt: now,
      ));

      // Attempt sync with null client (simulating unconfigured or offline state)
      final syncService = CloudSyncService(
        localRepo: repo,
        client: null,
      );

      final result = await syncService.sync();
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Supabase is not configured'));

      // Verify all local memories remain 100% safe and intact
      final allLocal = await repo.getAllMemories();
      expect(allLocal.length, equals(2));
      expect(allLocal.any((m) => m.title == 'Safe Memory 1'), isTrue);
      expect(allLocal.any((m) => m.title == 'Safe Memory 2'), isTrue);
    });

    test('Signing out preserves all local memories and allows returning to Local Mode', () async {
      final now = DateTime.now();
      final id = await repo.insertMemory(MemoryItem(
        id: 0,
        title: 'Persistent Memory',
        description: 'Must remain after logout',
        mood: Mood.love,
        dateTime: now,
        tags: ['love', 'permanent'],
        createdAt: now,
      ));

      // Simulate sign out and switch to local mode
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cloud_backup_enabled', false);

      // Local memory is still present and intact
      final localMemory = await repo.getMemoryById(id);
      expect(localMemory, isNotNull);
      expect(localMemory!.title, equals('Persistent Memory'));
    });
  });
}

