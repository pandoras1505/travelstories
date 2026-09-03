import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/travel_book.dart';

/// Local SQLite mirror of the `travelBooks` collection — foundation for
/// offline-first reads (Phase 11). Lets sqflite exceptions propagate
/// untouched, same as the Firestore data source does with
/// [FirebaseException]; mapping to the app's own `DatabaseException`
/// happens one layer up, once a repository actually reads through this.
class TravelBookLocalDataSource {
  TravelBookLocalDataSource({required Database database}) : _db = database;

  final Database _db;

  static const _table = AppDatabaseSchema.travelBooks;

  Future<void> upsert(TravelBook book) {
    return _db.insert(
      _table,
      _toRow(book),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<TravelBook> books) async {
    final batch = _db.batch();
    for (final book in books) {
      batch.insert(
        _table,
        _toRow(book),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<TravelBook?> getById(String id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  /// The given user's own travel books (drafts + published), newest update
  /// first — mirrors `TravelBookRepository.watchMyTravelBooks`'s ordering.
  Future<List<TravelBook>> getByOwner(String ownerId) async {
    final rows = await _db.query(
      _table,
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_toEntity).toList();
  }

  Future<void> delete(String id) {
    return _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() => _db.delete(_table);

  Map<String, Object?> _toRow(TravelBook book) {
    return {
      'id': book.id,
      'owner_id': book.ownerId,
      'title': book.title,
      'description': book.description,
      'cover_image_url': book.coverImageUrl,
      'start_date': book.startDate?.millisecondsSinceEpoch,
      'end_date': book.endDate?.millisecondsSinceEpoch,
      'is_public': book.isPublic ? 1 : 0,
      'created_at': book.createdAt.millisecondsSinceEpoch,
      'updated_at': book.updatedAt.millisecondsSinceEpoch,
      'published_at': book.publishedAt?.millisecondsSinceEpoch,
      'experience_count': book.experienceCount,
    };
  }

  TravelBook _toEntity(Map<String, Object?> row) {
    return TravelBook(
      id: row['id']! as String,
      ownerId: row['owner_id']! as String,
      title: row['title']! as String,
      description: row['description']! as String,
      coverImageUrl: row['cover_image_url'] as String?,
      startDate: _fromMillis(row['start_date']),
      endDate: _fromMillis(row['end_date']),
      isPublic: (row['is_public']! as int) == 1,
      createdAt: _fromMillis(row['created_at'])!,
      updatedAt: _fromMillis(row['updated_at'])!,
      publishedAt: _fromMillis(row['published_at']),
      experienceCount: row['experience_count']! as int,
    );
  }

  DateTime? _fromMillis(Object? value) {
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value as int);
  }
}
