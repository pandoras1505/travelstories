import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelstories/core/database/app_database.dart';
import 'package:travelstories/core/sync/pending_mutations_local_data_source.dart';

import '../database/sqflite_test_setup.dart';

void main() {
  setUpAll(initSqfliteFfiForTests);

  late Database db;
  late PendingMutationsLocalDataSource queue;

  setUp(() async {
    db = await openAppDatabase(path: inMemoryDatabasePath);
    queue = PendingMutationsLocalDataSource(database: db);
  });

  tearDown(() => db.close());

  test('first returns null on an empty queue', () async {
    expect(await queue.first(), isNull);
  });

  test('first returns the oldest mutation, FIFO', () async {
    await queue.enqueue(type: 'a', payload: {'n': 1});
    await queue.enqueue(type: 'b', payload: {'n': 2});

    final first = await queue.first();
    expect(first?.type, 'a');
    expect(first?.payload, {'n': 1});
  });

  test('payload round-trips nested/typed values through JSON', () async {
    await queue.enqueue(
      type: 'createExperience',
      payload: {
        'title': 'Sunset',
        'latitude': 31.5,
        'longitude': null,
        'isPublic': true,
      },
    );

    final mutation = await queue.first();
    expect(mutation?.payload, {
      'title': 'Sunset',
      'latitude': 31.5,
      'longitude': null,
      'isPublic': true,
    });
  });

  test('remove drops a mutation and getAll reflects remaining order', () async {
    await queue.enqueue(type: 'a', payload: {});
    await queue.enqueue(type: 'b', payload: {});
    await queue.enqueue(type: 'c', payload: {});

    final all = await queue.getAll();
    await queue.remove(all[1].id);

    final remaining = await queue.getAll();
    expect(remaining.map((m) => m.type), ['a', 'c']);
  });

  test('count reflects the queue size', () async {
    expect(await queue.count(), 0);
    await queue.enqueue(type: 'a', payload: {});
    await queue.enqueue(type: 'b', payload: {});
    expect(await queue.count(), 2);
  });
}
