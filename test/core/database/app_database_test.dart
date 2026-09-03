import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelstories/core/database/app_database.dart';

import 'sqflite_test_setup.dart';

void main() {
  setUpAll(initSqfliteFfiForTests);

  test('creates the travel_books and experiences tables with indexes', () async {
    final db = await openAppDatabase(path: inMemoryDatabasePath);
    addTearDown(db.close);

    final tables = await db.query(
      'sqlite_master',
      columns: ['name'],
      where:
          "type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    final tableNames = tables.map((row) => row['name']).toSet();
    expect(
      tableNames,
      containsAll([
        AppDatabaseSchema.travelBooks,
        AppDatabaseSchema.experiences,
      ]),
    );

    final indexes = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'index'",
    );
    final indexNames = indexes.map((row) => row['name']).toSet();
    expect(
      indexNames,
      containsAll([
        'idx_travel_books_owner_id',
        'idx_experiences_travel_book_id',
      ]),
    );
  });

  test('is safe to reopen the same in-memory database twice', () async {
    // Not a real-world scenario (in-memory paths aren't reused), but
    // guards against onCreate accidentally running twice on the same file.
    final db1 = await openAppDatabase(path: inMemoryDatabasePath);
    await db1.close();
    final db2 = await openAppDatabase(path: inMemoryDatabasePath);
    addTearDown(db2.close);

    expect(await db2.getVersion(), AppDatabaseSchema.version);
  });
}
