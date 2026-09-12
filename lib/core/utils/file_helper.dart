import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileHelper {
  static const _uuid = Uuid();

  /// Saves a picked image file permanently to the app's documents directory.
  static Future<String> saveImagePermanently(String sourcePath) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDocDir.path, 'memory_images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final newFileName = 'mem_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}$extension';
    final targetPath = p.join(imagesDir.path, newFileName);

    final sourceFile = File(sourcePath);
    final savedFile = await sourceFile.copy(targetPath);
    return savedFile.path;
  }

  /// Deletes an image file if it exists.
  static Future<void> deleteImageFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup, ignore errors
    }
  }

  /// Checks whether an image file exists at the given path.
  static bool imageExists(String? filePath) {
    if (filePath == null || filePath.isEmpty) return false;
    return File(filePath).existsSync();
  }
}
