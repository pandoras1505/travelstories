import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// The app's local SQLite database, opened once and kept alive for the
/// process lifetime. Local data sources depend on this rather than opening
/// their own connection. Not yet consumed by any repository — that wiring
/// (local-first reads, Firestore fallback) is Phase 11's job.
final appDatabaseProvider = FutureProvider<Database>((ref) {
  return openAppDatabase();
});
