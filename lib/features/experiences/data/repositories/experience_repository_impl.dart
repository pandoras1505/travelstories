import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/experience.dart';
import '../../domain/repositories/experience_repository.dart';
import '../datasources/experience_firestore_data_source.dart';
import '../datasources/experience_media_storage_data_source.dart';

class ExperienceRepositoryImpl implements ExperienceRepository {
  ExperienceRepositoryImpl({
    required ExperienceFirestoreDataSource dataSource,
    required ExperienceMediaStorageDataSource mediaStorageDataSource,
  }) : _dataSource = dataSource,
       _mediaStorageDataSource = mediaStorageDataSource;

  final ExperienceFirestoreDataSource _dataSource;
  final ExperienceMediaStorageDataSource _mediaStorageDataSource;

  @override
  Stream<List<Experience>> watchExperiences(String travelBookId) async* {
    try {
      await for (final snapshot in _dataSource.watchAll(travelBookId)) {
        yield snapshot.docs.map(_toExperience).toList();
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Stream<Experience?> watchExperience({
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
    try {
      return await _dataSource.addAndIncrementCount(travelBookId, {
        'travelBookId': travelBookId,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'mediaType': ExperienceMediaType.text.name,
        'mediaUrl': null,
        'thumbnailUrl': null,
        'createdAt': fs.FieldValue.serverTimestamp(),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
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
    try {
      await _dataSource.update(travelBookId, id, {
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
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
    try {
      await _dataSource.deleteAndDecrementCount(travelBookId, id);
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
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
