import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import 'pending_mutation.dart';

/// Local SQLite-backed FIFO queue of [PendingMutation]s. Read/write access
/// for [SyncEngine] only — repositories enqueue mutations through it, not
/// this data source directly.
class PendingMutationsLocalDataSource {
  PendingMutationsLocalDataSource({required Database database})
    : _db = database;

  final Database _db;

  static const _table = AppDatabaseSchema.pendingMutations;

  Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    return _db.insert(_table, {
      'type': type,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// The oldest still-queued mutation, or `null` once the queue is empty.
  Future<PendingMutation?> first() async {
    final rows = await _db.query(_table, orderBy: 'id ASC', limit: 1);
    return rows.isEmpty ? null : _toEntity(rows.first);
  }

  Future<List<PendingMutation>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'id ASC');
    return rows.map(_toEntity).toList();
  }

  Future<void> remove(int id) {
    return _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final result = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM $_table'),
    );
    return result ?? 0;
  }

  PendingMutation _toEntity(Map<String, Object?> row) {
    return PendingMutation(
      id: row['id']! as int,
      type: row['type']! as String,
      payload: jsonDecode(row['payload']! as String) as Map<String, dynamic>,
    );
  }
}
