import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_providers.dart';
import '../database/database_providers.dart';
import 'pending_mutations_local_data_source.dart';
import 'sync_engine.dart';

/// One shared [SyncEngine] for the whole app — `TravelBookRepositoryImpl`
/// and `ExperienceRepositoryImpl` each register their own mutation types on
/// it (in their constructors) the first time either repository provider is
/// read, and it starts listening for reconnection immediately.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  final engine = SyncEngine(
    queue: PendingMutationsLocalDataSource(database: database),
    connectivity: ref.watch(connectivityServiceProvider),
  );
  engine.start();
  ref.onDispose(engine.dispose);
  return engine;
});
