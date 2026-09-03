import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/experience.dart';

/// Local SQLite mirror of the `travelBooks/{id}/experiences` subcollection
/// — foundation for offline-first reads (Phase 11). Lets sqflite exceptions
/// propagate untouched, same as the Firestore data source does with
/// [FirebaseException]; mapping to the app's own `DatabaseException`
/// happens one layer up, once a repository actually reads through this.
class ExperienceLocalDataSource {
  ExperienceLocalDataSource({required Database database}) : _db = database;

  final Database _db;

  static const _table = AppDatabaseSchema.experiences;

  Future<void> upsert(Experience experience) {
    return _db.insert(
      _table,
      _toRow(experience),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<Experience> experiences) async {
    final batch = _db.batch();
    for (final experience in experiences) {
      batch.insert(
        _table,
        _toRow(experience),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Experience?> getById(String id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  /// Mirrors `ExperienceRepository.watchExperiences`'s chronological order.
  Future<List<Experience>> getByTravelBook(String travelBookId) async {
    final rows = await _db.query(
      _table,
      where: 'travel_book_id = ?',
      whereArgs: [travelBookId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_toEntity).toList();
  }

  Future<void> delete(String id) {
    return _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByTravelBook(String travelBookId) {
    return _db.delete(
      _table,
      where: 'travel_book_id = ?',
      whereArgs: [travelBookId],
    );
  }

  Future<void> clear() => _db.delete(_table);

  Map<String, Object?> _toRow(Experience experience) {
    return {
      'id': experience.id,
      'travel_book_id': experience.travelBookId,
      'owner_id': experience.ownerId,
      'title': experience.title,
      'description': experience.description,
      'latitude': experience.latitude,
      'longitude': experience.longitude,
      'location_name': experience.locationName,
      'media_type': experience.mediaType.name,
      'media_url': experience.mediaUrl,
      'thumbnail_url': experience.thumbnailUrl,
      'created_at': experience.createdAt.millisecondsSinceEpoch,
      'updated_at': experience.updatedAt.millisecondsSinceEpoch,
    };
  }

  Experience _toEntity(Map<String, Object?> row) {
    return Experience(
      id: row['id']! as String,
      travelBookId: row['travel_book_id']! as String,
      ownerId: row['owner_id']! as String,
      title: row['title']! as String,
      description: row['description']! as String,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      locationName: row['location_name'] as String?,
      mediaType: ExperienceMediaType.values.byName(
        row['media_type']! as String,
      ),
      mediaUrl: row['media_url'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
    );
  }
}
