import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

/// Service managing private photo storage in Supabase Storage.
/// Bucket: `memory-photos` (private, protected by Row Level Security)
/// Object structure: `${user-id}/${memory-id}/${filename}`
class SupabaseStorageService {
  static const String bucketName = 'memory-photos';

  final SupabaseClient? _client;

  SupabaseStorageService([SupabaseClient? client])
      : _client = client ?? (SupabaseConfig.isConfigured ? _safeGetClient() : null);

  static SupabaseClient? _safeGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _client != null;

  /// Builds the structured private storage object path:
  /// `${userId}/${memoryId}/${filename}`
  static String buildObjectPath({
    required String userId,
    required String memoryId,
    required String fileName,
  }) {
    final sanitizedFileName = p.basename(fileName);
    return '$userId/$memoryId/$sanitizedFileName';
  }

  /// Uploads a local photo to the authenticated user's private folder in `memory-photos`.
  /// Returns the relative storage object path (e.g. `user-id/memory-id/filename.jpg`)
  /// to be saved in Supabase `public.memories.photo_path`.
  Future<String?> uploadPhoto({
    required String userId,
    required String memoryId,
    required File localFile,
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint('Storage client not available for upload');
      return null;
    }

    if (!await localFile.exists()) {
      debugPrint('Local photo file does not exist at: ${localFile.path}');
      return null;
    }

    try {
      final fileName = p.basename(localFile.path);
      final objectPath = buildObjectPath(
        userId: userId,
        memoryId: memoryId,
        fileName: fileName,
      );

      final fileBytes = await localFile.readAsBytes();

      // Upsert: true ensures repeated syncs don't fail if the file already exists
      await client.storage.from(bucketName).uploadBinary(
            objectPath,
            fileBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return objectPath;
    } on StorageException catch (e) {
      debugPrint('Supabase storage upload error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Failed to upload photo: $e');
      return null;
    }
  }

  /// Downloads photo bytes directly via authenticated request.
  /// Used for safely downloading private photos for local storage during sync.
  Future<Uint8List?> downloadPhoto(String storagePath) async {
    final client = _client;
    if (client == null || storagePath.trim().isEmpty) return null;

    try {
      final bytes = await client.storage.from(bucketName).download(storagePath);
      return bytes;
    } on StorageException catch (e) {
      debugPrint('Supabase storage download error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Failed to download photo: $e');
      return null;
    }
  }

  /// Creates a temporary signed URL to view a private photo (default: valid for 1 hour).
  /// Note: The signed URL is temporary and must NEVER be stored as a permanent photo path.
  Future<String?> getSignedUrl(String storagePath, {int expiresIn = 3600}) async {
    final client = _client;
    if (client == null || storagePath.trim().isEmpty) return null;

    try {
      final signedUrl = await client.storage
          .from(bucketName)
          .createSignedUrl(storagePath, expiresIn);
      return signedUrl;
    } catch (e) {
      debugPrint('Failed to create signed URL for $storagePath: $e');
      return null;
    }
  }

  /// Deletes a photo from private storage
  Future<void> deletePhoto(String storagePath) async {
    final client = _client;
    if (client == null || storagePath.trim().isEmpty) return;

    try {
      await client.storage.from(bucketName).remove([storagePath]);
    } catch (e) {
      debugPrint('Failed to delete cloud photo: $e');
    }
  }
}
