import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/local_first_stream.dart';
import '../../domain/entities/travel_book.dart';
import '../../domain/repositories/travel_book_repository.dart';
import '../datasources/cover_storage_data_source.dart';
import '../datasources/travel_book_firestore_data_source.dart';
import '../datasources/travel_book_local_data_source.dart';

class TravelBookRepositoryImpl implements TravelBookRepository {
  TravelBookRepositoryImpl({
    required TravelBookFirestoreDataSource firestoreDataSource,
    required CoverStorageDataSource storageDataSource,
    required TravelBookLocalDataSource localDataSource,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource,
       _localDataSource = localDataSource;

  final TravelBookFirestoreDataSource _firestoreDataSource;
  final CoverStorageDataSource _storageDataSource;
  final TravelBookLocalDataSource _localDataSource;

  /// Local-first: emits the cached copy immediately (works offline, and
  /// paints instantly instead of waiting on Firestore's first snapshot),
  /// then live Firestore updates, mirroring each one into the cache. Falls
  /// back to the cache silently if Firestore can't be reached, as long as
  /// there was something cached to fall back to.
  @override
  Stream<List<TravelBook>> watchMyTravelBooks(String ownerId) {
    return localFirstStream<TravelBook>(
      readCache: () => _localDataSource.getByOwner(ownerId),
      watchRemote: () => _watchMyTravelBooksRemote(ownerId),
      onRemoteData: (books) => _reconcileOwnerCache(ownerId, books),
    );
  }

  Stream<List<TravelBook>> _watchMyTravelBooksRemote(String ownerId) async* {
    try {
      await for (final snapshot in _firestoreDataSource.watchByOwner(ownerId)) {
        yield snapshot.docs.map(_toTravelBook).toList();
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  /// Upserts the fresh set and drops any cached book for [ownerId] that
  /// Firestore no longer returned (deleted elsewhere while this client
  /// was offline).
  Future<void> _reconcileOwnerCache(
    String ownerId,
    List<TravelBook> freshBooks,
  ) async {
    await _localDataSource.upsertAll(freshBooks);
    final freshIds = freshBooks.map((b) => b.id).toSet();
    final cached = await _localDataSource.getByOwner(ownerId);
    for (final book in cached) {
      if (!freshIds.contains(book.id)) {
        await _localDataSource.delete(book.id);
      }
    }
  }

  @override
  Stream<TravelBook?> watchTravelBook(String id) {
    return localFirstSingleStream<TravelBook>(
      readCache: () => _localDataSource.getById(id),
      watchRemote: () => _watchTravelBookRemote(id),
      onRemoteData: (book) => book == null
          ? _localDataSource.delete(id)
          : _localDataSource.upsert(book),
    );
  }

  Stream<TravelBook?> _watchTravelBookRemote(String id) async* {
    try {
      await for (final snapshot in _firestoreDataSource.watch(id)) {
        yield snapshot.exists ? _toTravelBook(snapshot) : null;
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<PublicTravelBooksPage> fetchPublicTravelBooks({
    PublicBooksSort sort = PublicBooksSort.recent,
    String? titlePrefix,
    int limit = 10,
    TravelBook? startAfter,
  }) async {
    try {
      final trimmedPrefix = titlePrefix?.trim();
      final searching = trimmedPrefix != null && trimmedPrefix.isNotEmpty;

      List<Object?>? startAfterValues;
      if (startAfter != null) {
        final createdAt = fs.Timestamp.fromDate(startAfter.createdAt);
        if (searching) {
          startAfterValues = [startAfter.title, createdAt];
        } else {
          startAfterValues = switch (sort) {
            PublicBooksSort.recent => [createdAt],
            PublicBooksSort.popular => [startAfter.experienceCount, createdAt],
            PublicBooksSort.alphabetical => [startAfter.title, createdAt],
          };
        }
      }

      final snapshot = await _firestoreDataSource.fetchPublic(
        sort: sort,
        titlePrefix: searching ? trimmedPrefix : null,
        limit: limit + 1,
        startAfterValues: startAfterValues,
      );
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final books = docs.take(limit).map(_toTravelBook).toList();
      return (books: books, hasMore: hasMore);
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
