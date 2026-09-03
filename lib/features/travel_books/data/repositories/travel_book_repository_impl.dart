import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/travel_book.dart';
import '../../domain/repositories/travel_book_repository.dart';
import '../datasources/cover_storage_data_source.dart';
import '../datasources/travel_book_firestore_data_source.dart';

class TravelBookRepositoryImpl implements TravelBookRepository {
  TravelBookRepositoryImpl({
    required TravelBookFirestoreDataSource firestoreDataSource,
    required CoverStorageDataSource storageDataSource,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource;

  final TravelBookFirestoreDataSource _firestoreDataSource;
  final CoverStorageDataSource _storageDataSource;

  @override
  Stream<List<TravelBook>> watchMyTravelBooks(String ownerId) async* {
    try {
      await for (final snapshot in _firestoreDataSource.watchByOwner(ownerId)) {
        yield snapshot.docs.map(_toTravelBook).toList();
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Stream<TravelBook?> watchTravelBook(String id) async* {
    try {
      await for (final snapshot in _firestoreDataSource.watch(id)) {
        yield snapshot.exists ? _toTravelBook(snapshot) : null;
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<String> createTravelBook({
    required String ownerId,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required bool isPublic,
  }) async {
    try {
      final doc = await _firestoreDataSource.add({
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'coverImageUrl': null,
        'startDate': startDate == null
            ? null
            : fs.Timestamp.fromDate(startDate),
        'endDate': endDate == null ? null : fs.Timestamp.fromDate(endDate),
        'isPublic': isPublic,
        'createdAt': fs.FieldValue.serverTimestamp(),
        'updatedAt': fs.FieldValue.serverTimestamp(),
        'publishedAt': isPublic ? fs.FieldValue.serverTimestamp() : null,
        'experienceCount': 0,
      });
      return doc.id;
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> updateTravelBook({
    required String id,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _firestoreDataSource.update(id, {
        'title': title,
        'description': description,
        'startDate': startDate == null
            ? null
            : fs.Timestamp.fromDate(startDate),
        'endDate': endDate == null ? null : fs.Timestamp.fromDate(endDate),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> publishTravelBook(String id) async {
    try {
      final current = await _firestoreDataSource.get(id);
      final alreadyPublishedOnce = current.data()?['publishedAt'] != null;
      await _firestoreDataSource.update(id, {
        'isPublic': true,
        'updatedAt': fs.FieldValue.serverTimestamp(),
        if (!alreadyPublishedOnce)
          'publishedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> unpublishTravelBook(String id) async {
    try {
      await _firestoreDataSource.update(id, {
        'isPublic': false,
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> deleteTravelBook(String id) async {
    try {
      await _firestoreDataSource.delete(id);
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<String> uploadCover({
    required String travelBookId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final String downloadUrl;
    try {
      downloadUrl = await _storageDataSource.upload(
        travelBookId: travelBookId,
        fileBytes: fileBytes,
        fileExtension: fileExtension,
      );
    } on fs.FirebaseException catch (e) {
      throw StorageException(
        'Storage error: ${e.code}',
        code: e.code,
        cause: e,
      );
    }

    try {
      await _firestoreDataSource.update(travelBookId, {
        'coverImageUrl': downloadUrl,
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }

    return downloadUrl;
  }

  TravelBook _toTravelBook(fs.DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    final now = DateTime.now();
    return TravelBook(
      id: snapshot.id,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String?,
      startDate: (data['startDate'] as fs.Timestamp?)?.toDate(),
      endDate: (data['endDate'] as fs.Timestamp?)?.toDate(),
      isPublic: data['isPublic'] as bool? ?? false,
      createdAt: (data['createdAt'] as fs.Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as fs.Timestamp?)?.toDate() ?? now,
      publishedAt: (data['publishedAt'] as fs.Timestamp?)?.toDate(),
      experienceCount: (data['experienceCount'] as num?)?.toInt() ?? 0,
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
