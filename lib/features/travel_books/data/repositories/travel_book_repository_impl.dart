import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/local_first_stream.dart';
import '../../../../core/sync/pending_mutation.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../experiences/data/datasources/experience_local_data_source.dart';
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
    required ExperienceLocalDataSource experienceLocalDataSource,
    required SyncEngine syncEngine,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource,
       _localDataSource = localDataSource,
       _experienceLocalDataSource = experienceLocalDataSource,
       _syncEngine = syncEngine {
    _syncEngine
      ..registerApplier('createTravelBook', _applyCreate)
      ..registerApplier('updateTravelBook', _applyUpdate)
      ..registerApplier('publishTravelBook', _applyPublish)
      ..registerApplier('unpublishTravelBook', _applyUnpublish)
      ..registerApplier('deleteTravelBook', _applyDelete);
  }

  final TravelBookFirestoreDataSource _firestoreDataSource;
  final CoverStorageDataSource _storageDataSource;
  final TravelBookLocalDataSource _localDataSource;
  final ExperienceLocalDataSource _experienceLocalDataSource;
  final SyncEngine _syncEngine;

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

  /// Writes below apply to the local cache immediately (so the UI reflects
  /// them right away, online or not) and queue the real Firestore write on
  /// [_syncEngine] rather than awaiting it — see `SyncEngine`. [createdAt]
  /// is a client timestamp rather than `serverTimestamp()` specifically so
  /// it's identical in the local cache and in the eventual Firestore write
  /// (sort order — e.g. the public feed's "recent" tab — depends on it
  /// never shifting once assigned); the tradeoff is that it trusts the
  /// device clock instead of Firestore's.
  @override
  Future<String> createTravelBook({
    required String ownerId,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required bool isPublic,
  }) async {
    final id = _firestoreDataSource.newId();
    final now = DateTime.now();
    final book = TravelBook(
      id: id,
      ownerId: ownerId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isPublic: isPublic,
      createdAt: now,
      updatedAt: now,
      publishedAt: isPublic ? now : null,
      experienceCount: 0,
    );

    await _localDataSource.upsert(book);
    await _syncEngine.enqueue('createTravelBook', {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isPublic': isPublic,
      'createdAt': now.toIso8601String(),
    });

    return id;
  }

  Future<void> _applyCreate(PendingMutation mutation) async {
    final data = mutation.payload;
    final isPublic = data['isPublic'] as bool;
    final createdAt = fs.Timestamp.fromDate(
      DateTime.parse(data['createdAt'] as String),
    );
    try {
      await _firestoreDataSource.set(data['id'] as String, {
        'ownerId': data['ownerId'],
        'title': data['title'],
        'description': data['description'],
        'coverImageUrl': null,
        'startDate': _parseNullable(data['startDate']),
        'endDate': _parseNullable(data['endDate']),
        'isPublic': isPublic,
        'createdAt': createdAt,
        'updatedAt': fs.FieldValue.serverTimestamp(),
        'publishedAt': isPublic ? createdAt : null,
        'experienceCount': 0,
      });
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
    final existing = await _localDataSource.getById(id);
    if (existing != null) {
      await _localDataSource.upsert(
        existing.copyWith(
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          updatedAt: DateTime.now(),
        ),
      );
    }
    await _syncEngine.enqueue('updateTravelBook', {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    });
  }

  Future<void> _applyUpdate(PendingMutation mutation) async {
    final data = mutation.payload;
    try {
      await _firestoreDataSource.update(data['id'] as String, {
        'title': data['title'],
        'description': data['description'],
        'startDate': _parseNullable(data['startDate']),
        'endDate': _parseNullable(data['endDate']),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> publishTravelBook(String id) async {
    final existing = await _localDataSource.getById(id);
    final now = DateTime.now();
    if (existing != null) {
      await _localDataSource.upsert(
        existing.copyWith(
          isPublic: true,
          publishedAt: existing.publishedAt ?? now,
          updatedAt: now,
        ),
      );
    }
    await _syncEngine.enqueue('publishTravelBook', {'id': id});
  }

  Future<void> _applyPublish(PendingMutation mutation) async {
    final id = mutation.payload['id'] as String;
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
    final existing = await _localDataSource.getById(id);
    if (existing != null) {
      await _localDataSource.upsert(
        existing.copyWith(isPublic: false, updatedAt: DateTime.now()),
      );
    }
    await _syncEngine.enqueue('unpublishTravelBook', {'id': id});
  }

  Future<void> _applyUnpublish(PendingMutation mutation) async {
    final id = mutation.payload['id'] as String;
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
    await _localDataSource.delete(id);
    await _experienceLocalDataSource.deleteByTravelBook(id);
    await _syncEngine.enqueue('deleteTravelBook', {'id': id});
  }

  Future<void> _applyDelete(PendingMutation mutation) async {
    final id = mutation.payload['id'] as String;
    try {
      await _firestoreDataSource.delete(id);
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  fs.Timestamp? _parseNullable(Object? isoString) {
    return isoString == null
        ? null
        : fs.Timestamp.fromDate(DateTime.parse(isoString as String));
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
