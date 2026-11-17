import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/file_helper.dart';
import '../../features/memories/models/memory_item.dart';
import '../database/app_database.dart';

abstract class MemoryRepository {
  Stream<List<MemoryItem>> watchAllMemories();
  Future<List<MemoryItem>> getAllMemories();
  Future<MemoryItem?> getMemoryById(int id);
  Future<MemoryItem?> getMemoryByCloudId(String cloudId);
  Future<int> insertMemory(MemoryItem memory);
  Future<bool> updateMemory(MemoryItem memory);
  Future<void> deleteMemory(int id, {String? photoPath});
  Future<void> deleteAllMemories();
  Future<void> toggleFavorite(int id, bool currentStatus);
  Stream<List<MemoryItem>> watchFavoriteMemories();
  Future<List<MemoryItem>> getFavoriteMemories();
  Future<MemoryItem?> getRandomMemory();

  // Cloud sync deletion tracking
  Future<List<String>> getPendingDeletedCloudIds();
  Future<void> clearPendingDeletedCloudIds(List<String> ids);
}

class MemoryRepositoryImpl implements MemoryRepository {
  static const String _deletedCloudIdsKey = 'pending_deleted_cloud_ids';
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
  Future<MemoryItem?> getMemoryByCloudId(String cloudId) async {
    final row = await _db.getMemoryByCloudId(cloudId);
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
    // Record cloudId for sync deletion before deleting locally
    final existing = await getMemoryById(id);
    if (existing?.cloudId != null && existing!.cloudId!.isNotEmpty) {
      await _recordDeletedCloudId(existing.cloudId!);
    }

    await _db.deleteMemoryById(id);
    if (photoPath != null) {
      await FileHelper.deleteImageFile(photoPath);
    }
  }

  @override
  Future<void> deleteAllMemories() async {
    final all = await getAllMemories();
    for (final m in all) {
      if (m.cloudId != null && m.cloudId!.isNotEmpty) {
        await _recordDeletedCloudId(m.cloudId!);
      }
      if (m.photoPath != null) {
        await FileHelper.deleteImageFile(m.photoPath);
      }
    }
    await _db.deleteAllMemories();
  }

  @override
  Future<void> toggleFavorite(int id, bool currentStatus) async {
    final companion = MemoriesCompanion(
      id: drift.Value(id),
      isFavorite: drift.Value(!currentStatus),
      updatedAt: drift.Value(DateTime.now()),
    );
    await (_db.update(_db.memories)..where((t) => t.id.equals(id)))
        .write(companion);
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

  Future<void> _recordDeletedCloudId(String cloudId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(_deletedCloudIdsKey) ?? [];
      if (!currentList.contains(cloudId)) {
        currentList.add(cloudId);
        await prefs.setStringList(_deletedCloudIdsKey, currentList);
      }
    } catch (_) {}
  }

  @override
  Future<List<String>> getPendingDeletedCloudIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_deletedCloudIdsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearPendingDeletedCloudIds(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(_deletedCloudIdsKey) ?? [];
      currentList.removeWhere((item) => ids.contains(item));
      await prefs.setStringList(_deletedCloudIdsKey, currentList);
    } catch (_) {}
  }
}
