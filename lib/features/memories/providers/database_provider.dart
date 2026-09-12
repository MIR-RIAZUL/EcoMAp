import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/memory_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MemoryRepositoryImpl(db);
});
