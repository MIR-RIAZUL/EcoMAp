import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../memories/providers/database_provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/supabase_storage_service.dart';

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService();
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final localRepo = ref.watch(memoryRepositoryProvider);
  final storageService = ref.watch(supabaseStorageServiceProvider);
  return CloudSyncService(
    localRepo: localRepo,
    storageService: storageService,
  );
});

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final SyncResult? lastResult;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastResult,
    this.lastSyncTime,
    this.errorMessage,
  });

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    SyncResult? lastResult,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final CloudSyncService _syncService;

  SyncNotifier(this._syncService) : super(const SyncState()) {
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final time = await CloudSyncService.getLastSyncTime();
    if (mounted) {
      state = state.copyWith(lastSyncTime: time);
    }
  }

  Future<SyncResult> syncNow() async {
    if (state.isSyncing) {
      return const SyncResult(
        success: false,
        errorMessage: 'A synchronization is already in progress.',
      );
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      errorMessage: null,
    );

    final result = await _syncService.sync();

    if (result.success) {
      final now = DateTime.now();
      state = state.copyWith(
        status: SyncStatus.success,
        lastResult: result,
        lastSyncTime: now,
      );
    } else {
      state = state.copyWith(
        status: SyncStatus.error,
        lastResult: result,
        errorMessage: result.errorMessage,
      );
    }

    return result;
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(cloudSyncServiceProvider);
  return SyncNotifier(syncService);
});
