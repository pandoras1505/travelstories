import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelstories/core/database/app_database.dart';
import 'package:travelstories/features/experiences/data/datasources/experience_local_data_source.dart';
import 'package:travelstories/features/experiences/domain/entities/experience.dart';

import '../../core/database/sqflite_test_setup.dart';

Experience _experience({
  required String id,
  required String travelBookId,
  String title = 'Untitled',
  DateTime? createdAt,
  ExperienceMediaType mediaType = ExperienceMediaType.text,
}) {
  final now = DateTime(2026, 1, 1);
  return Experience(
    id: id,
    travelBookId: travelBookId,
    ownerId: 'u1',
    title: title,
    description: 'A moment',
    mediaType: mediaType,
    createdAt: createdAt ?? now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(initSqfliteFfiForTests);

  late Database db;
  late ExperienceLocalDataSource dataSource;

  setUp(() async {
    db = await openAppDatabase(path: inMemoryDatabasePath);
    dataSource = ExperienceLocalDataSource(database: db);
  });

  tearDown(() => db.close());

  test(
    'upsert then getById round-trips every field, including geo data',
    () async {
      final experience = Experience(
        id: 'e1',
        travelBookId: 'b1',
        ownerId: 'u1',
        title: 'Sunset at the dunes',
        description: 'Golden hour',
        latitude: 31.5,
        longitude: -7.0,
        locationName: 'Erg Chebbi',
        mediaType: ExperienceMediaType.image,
        mediaUrl: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 1, 11),
      );

      await dataSource.upsert(experience);
      final fetched = await dataSource.getById('e1');

      expect(fetched, experience);
    },
  );

  test('getById returns null for a missing row', () async {
    expect(await dataSource.getById('missing'), isNull);
  });

  test(
    'getByTravelBook filters by book and sorts by createdAt ascending',
    () async {
      await dataSource.upsertAll([
        _experience(
          id: 'e1',
          travelBookId: 'b1',
          title: 'First stop',
          createdAt: DateTime(2026, 1, 1),
        ),
        _experience(
          id: 'e2',
          travelBookId: 'b1',
          title: 'Second stop',
          createdAt: DateTime(2026, 1, 3),
        ),
        _experience(id: 'e3', travelBookId: 'b2', title: 'Other book'),
      ]);

      final experiences = await dataSource.getByTravelBook('b1');

      expect(experiences.map((e) => e.title), ['First stop', 'Second stop']);
    },
  );

  test('deleteByTravelBook removes only that book\'s experiences', () async {
    await dataSource.upsertAll([
      _experience(id: 'e1', travelBookId: 'b1'),
      _experience(id: 'e2', travelBookId: 'b2'),
    ]);

    await dataSource.deleteByTravelBook('b1');

    expect(await dataSource.getByTravelBook('b1'), isEmpty);
    expect(await dataSource.getByTravelBook('b2'), hasLength(1));
  });

  test('clear empties the table', () async {
    await dataSource.upsertAll([
      _experience(id: 'e1', travelBookId: 'b1'),
      _experience(id: 'e2', travelBookId: 'b2'),
    ]);
    await dataSource.clear();

    expect(await dataSource.getByTravelBook('b1'), isEmpty);
    expect(await dataSource.getByTravelBook('b2'), isEmpty);
  });
}
