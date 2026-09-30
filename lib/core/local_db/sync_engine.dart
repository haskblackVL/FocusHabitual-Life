import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync status enum for UI indicators (100% Local offline-first architecture).
enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error;

  String get label {
    switch (this) {
      case SyncStatus.idle:
      case SyncStatus.synced:
        return 'Almacenamiento Local Seguro';
      case SyncStatus.syncing:
        return 'Guardando localmente...';
      case SyncStatus.offline:
        return '100% Local & Privado';
      case SyncStatus.error:
        return 'Guardado local';
    }
  }
}

/// Provider for the SyncEngine instance.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Provider for real-time SyncStatus.
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    final engine = ref.watch(syncEngineProvider);
    engine.onStatusChanged = (newStatus) {
      state = newStatus;
    };
    return engine.currentStatus;
  }
}

/// Local storage engine providing status guarantees without remote server dependencies.
class SyncEngine {
  SyncEngine();

  SyncStatus currentStatus = SyncStatus.synced;
  void Function(SyncStatus)? onStatusChanged;

  void dispose() {}

  /// No-op in 100% local mode: data is already written immediately to SQLite via AppDatabase.
  Future<void> syncNow() async {
    onStatusChanged?.call(SyncStatus.synced);
  }
}
