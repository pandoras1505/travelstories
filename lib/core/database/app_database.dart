import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Table names for the local SQLite mirror of the Firestore schema
/// (`travelBooks`, `travelBooks/{id}/experiences`) — foundation for
/// offline-first reads (Phase 11) and the sync engine (Phase 12). Read/write
/// access goes through the per-feature `*LocalDataSource` classes; nothing
/// else should reference these tables directly.
abstract final class AppDatabaseSchema {
  static const int version = 1;

  static const String travelBooks = 'travel_books';
  static const String experiences = 'experiences';
}

/// Opens the app's local database, creating the schema on first run.
///
/// Uses whatever `sqflite` `databaseFactory` is currently set — the real
/// one on Android/iOS, or `sqflite_common_ffi`'s in tests. Pass [path] to
/// open somewhere other than the default app-documents location (tests pass
/// `inMemoryDatabasePath`).
Future<Database> openAppDatabase({String? path}) async {
  final resolvedPath = path ?? await _defaultPath();
  return openDatabase(
    resolvedPath,
    version: AppDatabaseSchema.version,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE ${AppDatabaseSchema.travelBooks} (
          id TEXT PRIMARY KEY,
          owner_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          cover_image_url TEXT,
          start_date INTEGER,
          end_date INTEGER,
          is_public INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          published_at INTEGER,
          experience_count INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_travel_books_owner_id '
        'ON ${AppDatabaseSchema.travelBooks} (owner_id)',
      );

      await db.execute('''
        CREATE TABLE ${AppDatabaseSchema.experiences} (
          id TEXT PRIMARY KEY,
          travel_book_id TEXT NOT NULL,
          owner_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          location_name TEXT,
          media_type TEXT NOT NULL,
          media_url TEXT,
          thumbnail_url TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_experiences_travel_book_id '
        'ON ${AppDatabaseSchema.experiences} (travel_book_id)',
      );
    },
  );
}

Future<String> _defaultPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return p.join(directory.path, 'travelstories.db');
}
