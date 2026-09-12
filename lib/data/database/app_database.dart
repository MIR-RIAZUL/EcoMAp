import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/memories_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'echomap_db'));

  @override
  int get schemaVersion => 1;

  // Stream all memories ordered by dateTime descending
  Stream<List<Memory>> watchAllMemories() {
    return (select(memories)
          ..orderBy([
            (m) => OrderingTerm(expression: m.memoryDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get all memories ordered by dateTime descending
  Future<List<Memory>> getAllMemories() {
    return (select(memories)
          ..orderBy([
            (m) => OrderingTerm(expression: m.memoryDate, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // Get memory by ID
  Future<Memory?> getMemoryById(int id) {
    return (select(memories)..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  // Insert a new memory
  Future<int> insertMemory(MemoriesCompanion memory) {
    return into(memories).insert(memory);
  }

  // Update existing memory
  Future<bool> updateMemory(MemoriesCompanion memory) {
    return update(memories).replace(memory);
  }

  // Delete memory by ID
  Future<int> deleteMemoryById(int id) {
    return (delete(memories)..where((m) => m.id.equals(id))).go();
  }

  // Delete all memories
  Future<int> deleteAllMemories() {
    return delete(memories).go();
  }

  // Watch favorite memories
  Stream<List<Memory>> watchFavoriteMemories() {
    return (select(memories)
          ..where((m) => m.isFavorite.equals(true))
          ..orderBy([
            (m) => OrderingTerm(expression: m.memoryDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get favorite memories
  Future<List<Memory>> getFavoriteMemories() {
    return (select(memories)
          ..where((m) => m.isFavorite.equals(true))
          ..orderBy([
            (m) => OrderingTerm(expression: m.memoryDate, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // Get a random memory
  Future<Memory?> getRandomMemory() async {
    final all = await getAllMemories();
    if (all.isEmpty) return null;
    all.shuffle();
    return all.first;
  }
}
