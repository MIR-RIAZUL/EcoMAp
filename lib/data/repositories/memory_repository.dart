import 'dart:async';
import 'package:drift/drift.dart' as drift;
import '../../core/utils/file_helper.dart';
import '../../features/memories/models/memory_item.dart';
import '../database/app_database.dart';

abstract class MemoryRepository {
  Stream<List<MemoryItem>> watchAllMemories();
  Future<List<MemoryItem>> getAllMemories();
  Future<MemoryItem?> getMemoryById(int id);
  Future<int> insertMemory(MemoryItem memory);
  Future<bool> updateMemory(MemoryItem memory);
  Future<void> deleteMemory(int id, {String? photoPath});
  Future<void> deleteAllMemories();
  Future<void> toggleFavorite(int id, bool currentStatus);
  Stream<List<MemoryItem>> watchFavoriteMemories();
  Future<List<MemoryItem>> getFavoriteMemories();
  Future<MemoryItem?> getRandomMemory();
}

class MemoryRepositoryImpl implements MemoryRepository {
  final AppDatabase _db;

  MemoryRepositoryImpl(this._db);

  @override
  Stream<List<MemoryItem>> watchAllMemories() {
    return _db.watchAllMemories().map(
          (rows) => rows.map((r) => MemoryItem.fromDb(r)).toList(),
        );
  }

  @override
  Future<List<MemoryItem>> getAllMemories() async {
    final rows = await _db.getAllMemories();
    return rows.map((r) => MemoryItem.fromDb(r)).toList();
  }

  @override
  Future<MemoryItem?> getMemoryById(int id) async {
    final row = await _db.getMemoryById(id);
    if (row == null) return null;
    return MemoryItem.fromDb(row);
  }

  @override
  Future<int> insertMemory(MemoryItem memory) async {
    final companion = memory.toCompanion(forInsert: true);
    return await _db.insertMemory(companion);
  }

  @override
  Future<bool> updateMemory(MemoryItem memory) async {
    final companion = memory.toCompanion(forInsert: false);
    return await _db.updateMemory(companion);
  }

  @override
  Future<void> deleteMemory(int id, {String? photoPath}) async {
    await _db.deleteMemoryById(id);
    if (photoPath != null) {
      await FileHelper.deleteImageFile(photoPath);
    }
  }

  @override
  Future<void> deleteAllMemories() async {
    final all = await getAllMemories();
    await _db.deleteAllMemories();
    for (final m in all) {
      if (m.photoPath != null) {
        await FileHelper.deleteImageFile(m.photoPath);
      }
    }
  }

  @override
  Future<void> toggleFavorite(int id, bool currentStatus) async {
    final companion = MemoriesCompanion(
      id: drift.Value(id),
      isFavorite: drift.Value(!currentStatus),
    );
    await (_db.update(_db.memories)..where((t) => t.id.equals(id))).write(companion);
  }

  @override
  Stream<List<MemoryItem>> watchFavoriteMemories() {
    return _db.watchFavoriteMemories().map(
          (rows) => rows.map((r) => MemoryItem.fromDb(r)).toList(),
        );
  }

  @override
  Future<List<MemoryItem>> getFavoriteMemories() async {
    final rows = await _db.getFavoriteMemories();
    return rows.map((r) => MemoryItem.fromDb(r)).toList();
  }

  @override
  Future<MemoryItem?> getRandomMemory() async {
    final row = await _db.getRandomMemory();
    if (row == null) return null;
    return MemoryItem.fromDb(row);
  }
}
