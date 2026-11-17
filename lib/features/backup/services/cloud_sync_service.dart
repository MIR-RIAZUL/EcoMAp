import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/file_helper.dart';
import '../../../data/repositories/memory_repository.dart';
import '../../memories/models/memory_item.dart';
import 'supabase_storage_service.dart';

class SyncResult {
  final bool success;
  final int memoriesPushed;
  final int memoriesPulled;
  final int photosUploaded;
  final int photosDownloaded;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    this.memoriesPushed = 0,
    this.memoriesPulled = 0,
    this.photosUploaded = 0,
    this.photosDownloaded = 0,
    this.errorMessage,
  });

  String get summary {
    if (!success) return errorMessage ?? 'Sync failed';
    final parts = <String>[];
    if (memoriesPushed > 0) parts.add('$memoriesPushed uploaded');
    if (memoriesPulled > 0) parts.add('$memoriesPulled downloaded');
    if (photosUploaded > 0) parts.add('$photosUploaded photos uploaded');
    if (photosDownloaded > 0) parts.add('$photosDownloaded photos downloaded');
    if (parts.isEmpty) return 'All memories are up to date';
    return parts.join(', ');
  }
}

/// Service handling synchronization between local Drift/SQLite and Supabase `public.memories`.
/// Offline-first: local database is the single source of truth.
class CloudSyncService {
  static const String lastSyncPrefKey = 'supabase_last_successful_sync';
  static const String tableName = 'memories';

  final MemoryRepository _localRepo;
  final SupabaseClient? _client;
  final SupabaseStorageService _storageService;

  CloudSyncService({
    required MemoryRepository localRepo,
    SupabaseClient? client,
    SupabaseStorageService? storageService,
  })  : _localRepo = localRepo,
        _client = client ?? (SupabaseConfig.isConfigured ? _safeGetClient() : null),
        _storageService = storageService ?? SupabaseStorageService(client);

  static SupabaseClient? _safeGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable {
    final client = _client;
    return client != null && client.auth.currentUser != null;
  }

  /// Fetches the last successful sync timestamp from SharedPreferences
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(lastSyncPrefKey);
      if (str != null && str.isNotEmpty) {
        return DateTime.tryParse(str)?.toLocal();
      }
    } catch (_) {}
    return null;
  }

  /// Sets the last successful sync timestamp
  static Future<void> setLastSyncTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastSyncPrefKey, time.toUtc().toIso8601String());
    } catch (_) {}
  }

  /// Executes bidirectional synchronization safely without destroying local data.
  Future<SyncResult> sync() async {
    final client = _client;
    if (client == null) {
      return const SyncResult(
        success: false,
        errorMessage: 'Supabase is not configured. Please check your credentials.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const SyncResult(
        success: false,
        errorMessage: 'You must be signed in to perform a cloud backup.',
      );
    }

    int pushedCount = 0;
    int pulledCount = 0;
    int photoUploadCount = 0;
    int photoDownloadCount = 0;

    try {
      // 1. Process pending local deletions in Supabase
      final pendingDeletes = await _localRepo.getPendingDeletedCloudIds();
      if (pendingDeletes.isNotEmpty) {
        try {
          await client
              .from(tableName)
              .delete()
              .filter('id', 'in', pendingDeletes);
          await _localRepo.clearPendingDeletedCloudIds(pendingDeletes);
        } catch (e) {
          debugPrint('Warning: Failed to sync some deletions to Supabase: $e');
        }
      }

      // 2. Fetch all cloud memories for the authenticated user
      final List<dynamic> cloudRecordsRaw =
          await client.from(tableName).select().eq('user_id', user.id);

      final Map<String, Map<String, dynamic>> cloudMap = {};
      for (final raw in cloudRecordsRaw) {
        if (raw is Map<String, dynamic> && raw['id'] != null) {
          cloudMap[raw['id'] as String] = raw;
        }
      }

      // 3. Fetch all local memories
      final localMemories = await _localRepo.getAllMemories();
      final Map<String, MemoryItem> localMap = {};

      for (var local in localMemories) {
        // Ensure every local memory has a stable UUID
        if (local.cloudId == null || local.cloudId!.isEmpty) {
          final newCloudId = const Uuid().v4();
          local = local.copyWith(cloudId: newCloudId);
          await _localRepo.updateMemory(local);
        }
        localMap[local.cloudId!] = local;
      }

      // 4. Sync Local -> Cloud (Insert new, Update modified)
      for (final local in localMap.values) {
        final cloudId = local.cloudId!;
        final cloudItem = cloudMap[cloudId];

        if (cloudItem == null) {
          // New memory on local device -> push to cloud
          String? cloudPhotoPath;
          if (local.hasPhoto && File(local.photoPath!).existsSync()) {
            final uploadedPath = await _storageService.uploadPhoto(
              userId: user.id,
              memoryId: cloudId,
              localFile: File(local.photoPath!),
            );
            if (uploadedPath != null) {
              cloudPhotoPath = uploadedPath;
              photoUploadCount++;
            }
          }

          final supabaseJson = local.toSupabaseJson(
            userId: user.id,
            cloudPhotoPath: cloudPhotoPath,
          );

          await client.from(tableName).insert(supabaseJson);
          pushedCount++;
        } else {
          // Exists on both sides -> timestamp comparison
          final cloudUpdatedAt = DateTime.tryParse(
                cloudItem['updated_at'] as String? ??
                    cloudItem['created_at'] as String? ??
                    '',
              )?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

          final localUpdatedAt =
              (local.updatedAt ?? local.createdAt).toUtc();

          // If local is strictly newer by more than 1 second, update cloud
          if (localUpdatedAt.difference(cloudUpdatedAt).inSeconds > 1) {
            String? cloudPhotoPath = cloudItem['photo_path'] as String?;

            // If local has a photo and cloud path is null or local file exists, check photo
            if (local.hasPhoto && File(local.photoPath!).existsSync()) {
              if (cloudPhotoPath == null || cloudPhotoPath.isEmpty) {
                final uploadedPath = await _storageService.uploadPhoto(
                  userId: user.id,
                  memoryId: cloudId,
                  localFile: File(local.photoPath!),
                );
                if (uploadedPath != null) {
                  cloudPhotoPath = uploadedPath;
                  photoUploadCount++;
                }
              }
            }

            final updateJson = local.toSupabaseJson(
              userId: user.id,
              cloudPhotoPath: cloudPhotoPath,
            );
            // Don't modify id or user_id in updates
            updateJson.remove('id');
            updateJson.remove('user_id');

            await client.from(tableName).update(updateJson).eq('id', cloudId);
            pushedCount++;
          }
          // If cloud is strictly newer by more than 1 second, update local
          else if (cloudUpdatedAt.difference(localUpdatedAt).inSeconds > 1) {
            String? localPhotoPath = local.photoPath;

            final cloudPhoto = cloudItem['photo_path'] as String?;
            if (cloudPhoto != null && cloudPhoto.isNotEmpty) {
              if (localPhotoPath == null || !File(localPhotoPath).existsSync()) {
                final bytes = await _storageService.downloadPhoto(cloudPhoto);
                if (bytes != null) {
                  final savedPath = await FileHelper.saveImageBytes(
                    bytes,
                    p.basename(cloudPhoto),
                  );
                  if (savedPath != null) {
                    localPhotoPath = savedPath;
                    photoDownloadCount++;
                  }
                }
              }
            }

            final updatedMemory = MemoryItem.fromSupabaseJson(
              cloudItem,
              localId: local.id,
              localPhotoPath: localPhotoPath,
            );
            await _localRepo.updateMemory(updatedMemory);
            pulledCount++;
          }
        }
      }

      // 5. Sync Cloud -> Local (Pull cloud memories that don't exist locally)
      for (final entry in cloudMap.entries) {
        final cloudId = entry.key;
        final cloudItem = entry.value;

        if (!localMap.containsKey(cloudId)) {
          String? localPhotoPath;
          final cloudPhoto = cloudItem['photo_path'] as String?;
          if (cloudPhoto != null && cloudPhoto.isNotEmpty) {
            final bytes = await _storageService.downloadPhoto(cloudPhoto);
            if (bytes != null) {
              final savedPath = await FileHelper.saveImageBytes(
                bytes,
                p.basename(cloudPhoto),
              );
              if (savedPath != null) {
                localPhotoPath = savedPath;
                photoDownloadCount++;
              }
            }
          }

          final newMemory = MemoryItem.fromSupabaseJson(
            cloudItem,
            localPhotoPath: localPhotoPath,
          );
          await _localRepo.insertMemory(newMemory);
          pulledCount++;
        }
      }

      // 6. Record successful sync timestamp
      final now = DateTime.now();
      await setLastSyncTime(now);

      return SyncResult(
        success: true,
        memoriesPushed: pushedCount,
        memoriesPulled: pulledCount,
        photosUploaded: photoUploadCount,
        photosDownloaded: photoDownloadCount,
      );
    } on PostgrestException catch (e) {
      debugPrint('Supabase PostgrestException during sync: ${e.message}');
      return SyncResult(
        success: false,
        errorMessage: 'Database sync error: ${e.message}',
      );
    } catch (e) {
      debugPrint('Sync failed with error: $e');
      return SyncResult(
        success: false,
        errorMessage: 'Sync failed: $e. Your local memories are safe.',
      );
    }
  }
}
