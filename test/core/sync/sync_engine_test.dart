import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelstories/core/database/app_database.dart';
import 'package:travelstories/core/sync/pending_mutations_local_data_source.dart';
import 'package:travelstories/core/sync/sync_engine.dart';

import '../../fakes/fake_connectivity_service.dart';
import '../database/sqflite_test_setup.dart';

void main() {
  setUpAll(initSqfliteFfiForTests);

  late Database db;
  late PendingMutationsLocalDataSource queue;
  late FakeConnectivityService connectivity;
  late SyncEngine engine;

  setUp(() async {
    db = await openAppDatabase(path: inMemoryDatabasePath);
    queue = PendingMutationsLocalDataSource(database: db);
    connectivity = FakeConnectivityService(initiallyOnline: true);
    engine = SyncEngine(
      queue: queue,
      connectivity: connectivity,
      applyTimeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() async {
    // Let any in-flight flush settle before closing the db out from under
    // it — flush() coalesces, so this reliably waits for the latest one.
    await engine.flush();
    engine.dispose();
    await db.close();
  });

  test('applies a mutation and removes it from the queue on success', () async {
    final applied = <Map<String, dynamic>>[];
    engine.registerApplier('greet', (m) async => applied.add(m.payload));

    await engine.enqueue('greet', {'name': 'Amina'});
    await engine.flush();

    expect(applied, [
      {'name': 'Amina'},
    ]);
    expect(await queue.count(), 0);
  });

  test('does not apply while offline, then flushes on reconnect', () async {
    connectivity = FakeConnectivityService(initiallyOnline: false);
    engine = SyncEngine(queue: queue, connectivity: connectivity);
    final applied = <String>[];
    engine.registerApplier('greet', (m) async => applied.add(m.type));
    engine.start();

    await engine.enqueue('greet', {});
    await engine.flush();
    expect(applied, isEmpty);
    expect(await queue.count(), 1);

    connectivity.setOnline(true);
    // The reconnect listener triggers its own flush asynchronously; there's
    // no handle to await directly, so give it a moment, then settle.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await engine.flush();

    expect(applied, ['greet']);
    expect(await queue.count(), 0);
  });

  test(
    'stops at the first failure, preserving order for later mutations',
    () async {
      var firstAttempts = 0;
      final secondApplied = <void>[];
      engine.registerApplier('first', (m) async {
        firstAttempts++;
        throw Exception('not yet');
      });
      engine.registerApplier('second', (m) async => secondApplied.add(null));

      await engine.enqueue('first', {});
      await engine.enqueue('second', {});
      await engine.flush();

      expect(firstAttempts, greaterThanOrEqualTo(1));
      expect(secondApplied, isEmpty);
      expect(await queue.count(), 2);

      // Once "first" actually succeeds, "second" is reached right after —
      // in the same order they were queued.
      engine.registerApplier('first', (m) async {});
      await engine.flush();

      expect(secondApplied, [null]);
      expect(await queue.count(), 0);
    },
  );

  test(
    'drops a mutation with no registered applier instead of jamming the queue',
    () async {
      final secondApplied = <void>[];
      engine.registerApplier('known', (m) async => secondApplied.add(null));

      await queue.enqueue(type: 'unknown', payload: {});
      await queue.enqueue(type: 'known', payload: {});
      await engine.flush();

      expect(secondApplied, [null]);
      expect(await queue.count(), 0);
    },
  );

  test('a hung applier is treated as a failure after the timeout', () async {
    var attempts = 0;
    engine.registerApplier('hangs', (m) async {
      attempts++;
      return Completer<void>().future; // never completes
    });

    await engine.enqueue('hangs', {});
    await engine.flush();

    expect(attempts, 1);
    expect(await queue.count(), 1);
  });

  test('concurrent flush calls do not apply the same mutation twice', () async {
    var attempts = 0;
    engine.registerApplier('once', (m) async {
      attempts++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await queue.enqueue(type: 'once', payload: {});

    await Future.wait([engine.flush(), engine.flush(), engine.flush()]);

    expect(attempts, 1);
  });
}
