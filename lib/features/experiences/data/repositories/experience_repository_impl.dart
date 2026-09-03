import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/local_first_stream.dart';
import '../../../../core/sync/pending_mutation.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../travel_books/data/datasources/travel_book_local_data_source.dart';
import '../../domain/entities/experience.dart';
import '../../domain/repositories/experience_repository.dart';
import '../datasources/experience_firestore_data_source.dart';
import '../datasources/experience_local_data_source.dart';
import '../datasources/experience_media_storage_data_source.dart';

class ExperienceRepositoryImpl implements ExperienceRepository {
  ExperienceRepositoryImpl({
    required ExperienceFirestoreDataSource dataSource,
    required ExperienceMediaStorageDataSource mediaStorageDataSource,
    required ExperienceLocalDataSource localDataSource,
    required TravelBookLocalDataSource travelBookLocalDataSource,
    required SyncEngine syncEngine,
  }) : _dataSource = dataSource,
       _mediaStorageDataSource = mediaStorageDataSource,
       _localDataSource = localDataSource,
       _travelBookLocalDataSource = travelBookLocalDataSource,
       _syncEngine = syncEngine {
    _syncEngine
      ..registerApplier('createExperience', _applyCreate)
      ..registerApplier('updateExperience', _applyUpdate)
      ..registerApplier('deleteExperience', _applyDelete);
  }

  final ExperienceFirestoreDataSource _dataSource;
  final ExperienceMediaStorageDataSource _mediaStorageDataSource;
  final ExperienceLocalDataSource _localDataSource;
  final TravelBookLocalDataSource _travelBookLocalDataSource;
  final SyncEngine _syncEngine;

  /// Local-first: see `TravelBookRepositoryImpl.watchMyTravelBooks` for the
  /// same pattern — cache emitted immediately, then live Firestore updates
  /// mirrored into the cache, falling back to the cache silently if
  /// Firestore can't be reached.
  @override
  Stream<List<Experience>> watchExperiences(String travelBookId) {
    return localFirstStream<Experience>(
      readCache: () => _localDataSource.getByTravelBook(travelBookId),
      watchRemote: () => _watchExperiencesRemote(travelBookId),
      onRemoteData: (experiences) =>
          _reconcileBookCache(travelBookId, experiences),
    );
  }

  Stream<List<Experience>> _watchExperiencesRemote(String travelBookId) async* {
    try {
      await for (final snapshot in _dataSource.watchAll(travelBookId)) {
        yield snapshot.docs.map(_toExperience).toList();
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  /// Upserts the fresh set and drops any cached experience for
  /// [travelBookId] that Firestore no longer returned.
  Future<void> _reconcileBookCache(
    String travelBookId,
    List<Experience> freshExperiences,
  ) async {
    await _localDataSource.upsertAll(freshExperiences);
    final freshIds = freshExperiences.map((e) => e.id).toSet();
    final cached = await _localDataSource.getByTravelBook(travelBookId);
    for (final experience in cached) {
      if (!freshIds.contains(experience.id)) {
        await _localDataSource.delete(experience.id);
      }
    }
  }

  @override
  Stream<Experience?> watchExperience({
    required String travelBookId,
    required String id,
  }) {
    return localFirstSingleStream<Experience>(
      readCache: () => _localDataSource.getById(id),
      watchRemote: () =>
          _watchExperienceRemote(travelBookId: travelBookId, id: id),
      onRemoteData: (experience) => experience == null
          ? _localDataSource.delete(id)
          : _localDataSource.upsert(experience),
    );
  }

  Stream<Experience?> _watchExperienceRemote({
    required String travelBookId,
    required String id,
  }) async* {
    try {
      await for (final snapshot in _dataSource.watchOne(
        travelBookId: travelBookId,
        id: id,
      )) {
        yield snapshot.exists ? _toExperience(snapshot) : null;
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  /// Writes below apply to the local cache immediately and queue the real
  /// Firestore write on [_syncEngine] instead of awaiting it — see
  /// `TravelBookRepositoryImpl`'s equivalent methods for the same pattern
  /// (including why [createdAt] is a client timestamp).
  @override
  Future<String> createExperience({
    required String travelBookId,
    required String ownerId,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final id = _dataSource.newId(travelBookId);
    final now = DateTime.now();
    final experience = Experience(
      id: id,
      travelBookId: travelBookId,
      ownerId: ownerId,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      mediaType: ExperienceMediaType.text,
      createdAt: now,
      updatedAt: now,
    );

    await _localDataSource.upsert(experience);
    await _bumpLocalExperienceCount(travelBookId, delta: 1, updatedAt: now);
    await _syncEngine.enqueue('createExperience', {
      'id': id,
      'travelBookId': travelBookId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'createdAt': now.toIso8601String(),
    });

    return id;
  }

  Future<void> _applyCreate(PendingMutation mutation) async {
    final data = mutation.payload;
    try {
      await _dataSource.createAndIncrementCount(
        data['travelBookId'] as String,
        data['id'] as String,
        {
          'travelBookId': data['travelBookId'],
          'ownerId': data['ownerId'],
          'title': data['title'],
          'description': data['description'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'locationName': data['locationName'],
          'mediaType': ExperienceMediaType.text.name,
          'mediaUrl': null,
          'thumbnailUrl': null,
          'createdAt': fs.Timestamp.fromDate(
            DateTime.parse(data['createdAt'] as String),
          ),
          'updatedAt': fs.FieldValue.serverTimestamp(),
        },
      );
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> updateExperience({
    required String travelBookId,
    required String id,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final existing = await _localDataSource.getById(id);
    if (existing != null) {
      await _localDataSource.upsert(
        existing.copyWith(
          title: title,
          description: description,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
          updatedAt: DateTime.now(),
        ),
      );
    }
    await _syncEngine.enqueue('updateExperience', {
      'travelBookId': travelBookId,
      'id': id,
      'title': title,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<void> _applyUpdate(PendingMutation mutation) async {
    final data = mutation.payload;
    try {
      await _dataSource
          .update(data['travelBookId'] as String, data['id'] as String, {
            'title': data['title'],
            'description': data['description'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'locationName': data['locationName'],
            'updatedAt': fs.FieldValue.serverTimestamp(),
          });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> deleteExperience({
    required String travelBookId,
    required String id,
  }) async {
    await _localDataSource.delete(id);
    await _bumpLocalExperienceCount(
      travelBookId,
      delta: -1,
      updatedAt: DateTime.now(),
    );
    await _syncEngine.enqueue('deleteExperience', {
      'travelBookId': travelBookId,
      'id': id,
    });
  }

  Future<void> _applyDelete(PendingMutation mutation) async {
    final data = mutation.payload;
    try {
      await _dataSource.deleteAndDecrementCount(
        data['travelBookId'] as String,
        data['id'] as String,
      );
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Future<void> _bumpLocalExperienceCount(
    String travelBookId, {
    required int delta,
    required DateTime updatedAt,
  }) async {
    final book = await _travelBookLocalDataSource.getById(travelBookId);
    if (book == null) return;
    await _travelBookLocalDataSource.upsert(
      book.copyWith(
        experienceCount: book.experienceCount + delta,
        updatedAt: updatedAt,
      ),
    );
  }

  @override
  Future<void> uploadMedia({
    required String travelBookId,
    required String id,
    required ExperienceMediaType mediaType,
    required List<int> bytes,
    required String extension,
    List<int>? thumbnailBytes,
  }) async {
    final String mediaUrl;
    String? thumbnailUrl;
    try {
      mediaUrl = await _mediaStorageDataSource.uploadMedia(
        travelBookId: travelBookId,
        experienceId: id,
        bytes: bytes,
        extension: extension,
      );
      if (thumbnailBytes != null) {
        thumbnailUrl = await _mediaStorageDataSource.uploadThumbnail(
          travelBookId: travelBookId,
          experienceId: id,
          bytes: thumbnailBytes,
        );
      }
    } on fs.FirebaseException catch (e) {
      throw StorageException(
        'Storage error: ${e.code}',
        code: e.code,
        cause: e,
      );
    }

    try {
      await _dataSource.update(travelBookId, id, {
        'mediaType': mediaType.name,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> removeMedia({
    required String travelBookId,
    required String id,
  }) async {
    try {
      await _mediaStorageDataSource.deleteAll(
        travelBookId: travelBookId,
        experienceId: id,
      );
    } on fs.FirebaseException catch (e) {
      throw StorageException(
        'Storage error: ${e.code}',
        code: e.code,
        cause: e,
      );
    }

    try {
      await _dataSource.update(travelBookId, id, {
        'mediaType': ExperienceMediaType.text.name,
        'mediaUrl': null,
        'thumbnailUrl': null,
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Experience _toExperience(fs.DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    final now = DateTime.now();
    return Experience(
      id: snapshot.id,
      travelBookId: data['travelBookId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationName: data['locationName'] as String?,
      mediaType: ExperienceMediaType.values.firstWhere(
        (type) => type.name == data['mediaType'],
        orElse: () => ExperienceMediaType.text,
      ),
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      createdAt: (data['createdAt'] as fs.Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as fs.Timestamp?)?.toDate() ?? now,
    );
  }

  FirestoreException _mapFirestoreException(fs.FirebaseException e) {
    return FirestoreException(
      'Firestore error: ${e.code}',
      code: e.code,
      cause: e,
    );
  }
}
