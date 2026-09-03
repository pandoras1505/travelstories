import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelstories/core/database/app_database.dart';
import 'package:travelstories/features/travel_books/data/datasources/travel_book_local_data_source.dart';
import 'package:travelstories/features/travel_books/domain/entities/travel_book.dart';

import '../../core/database/sqflite_test_setup.dart';

TravelBook _book({
  required String id,
  required String ownerId,
  String title = 'Untitled',
  bool isPublic = false,
  DateTime? updatedAt,
  int experienceCount = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return TravelBook(
    id: id,
    ownerId: ownerId,
    title: title,
    description: 'A trip',
    isPublic: isPublic,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    experienceCount: experienceCount,
  );
}

void main() {
  setUpAll(initSqfliteFfiForTests);

  late Database db;
  late TravelBookLocalDataSource dataSource;

  setUp(() async {
    db = await openAppDatabase(path: inMemoryDatabasePath);
    dataSource = TravelBookLocalDataSource(database: db);
  });

  tearDown(() => db.close());

  test('upsert then getById round-trips every field', () async {
    final book = TravelBook(
      id: 'b1',
      ownerId: 'u1',
      title: 'Road trip',
      description: 'Along the coast',
      coverImageUrl: 'https://example.com/cover.jpg',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 15),
      isPublic: true,
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 2, 11),
      publishedAt: DateTime(2026, 1, 2, 11),
      experienceCount: 3,
    );

    await dataSource.upsert(book);
    final fetched = await dataSource.getById('b1');

    expect(fetched, book);
  });

  test('getById returns null for a missing row', () async {
    expect(await dataSource.getById('missing'), isNull);
  });

  test('upsert replaces an existing row with the same id', () async {
    await dataSource.upsert(_book(id: 'b1', ownerId: 'u1', title: 'First'));
    await dataSource.upsert(_book(id: 'b1', ownerId: 'u1', title: 'Second'));

    final fetched = await dataSource.getById('b1');
    expect(fetched?.title, 'Second');
  });

  test('getByOwner filters by owner and sorts by updatedAt desc', () async {
    await dataSource.upsertAll([
      _book(
        id: 'b1',
        ownerId: 'u1',
        title: 'Older',
        updatedAt: DateTime(2026, 1, 1),
      ),
      _book(
        id: 'b2',
        ownerId: 'u1',
        title: 'Newer',
        updatedAt: DateTime(2026, 1, 5),
      ),
      _book(id: 'b3', ownerId: 'u2', title: "Someone else's"),
    ]);

    final books = await dataSource.getByOwner('u1');

    expect(books.map((b) => b.title), ['Newer', 'Older']);
  });

  test('delete removes the row', () async {
    await dataSource.upsert(_book(id: 'b1', ownerId: 'u1'));
    await dataSource.delete('b1');

    expect(await dataSource.getById('b1'), isNull);
  });

  test('clear empties the table', () async {
    await dataSource.upsertAll([
      _book(id: 'b1', ownerId: 'u1'),
      _book(id: 'b2', ownerId: 'u2'),
    ]);
    await dataSource.clear();

    expect(await dataSource.getByOwner('u1'), isEmpty);
    expect(await dataSource.getByOwner('u2'), isEmpty);
  });
}
