import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/travel_book_repository.dart';

/// Thin wrapper around the `travelBooks` collection. Lets Firestore
/// exceptions propagate untouched — mapping to [FirestoreException] happens
/// one layer up, in [TravelBookRepositoryImpl].
class TravelBookFirestoreDataSource {
  TravelBookFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _travelBooks =>
      _firestore.collection('travelBooks');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchByOwner(String ownerId) {
    return _travelBooks
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Builds the public-books query for [sort]/[titlePrefix] and applies
  /// [startAfterValues] (already Firestore-ready cursor values matching the
  /// query's orderBy fields, computed by the repository) when paginating.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchPublic({
    required PublicBooksSort sort,
    String? titlePrefix,
    required int limit,
    List<Object?>? startAfterValues,
  }) {
    Query<Map<String, dynamic>> query = _travelBooks.where(
      'isPublic',
      isEqualTo: true,
    );

    if (titlePrefix != null && titlePrefix.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: titlePrefix)
          .where('title', isLessThan: '$titlePrefix')
          .orderBy('title')
          .orderBy('createdAt', descending: true);
    } else {
      switch (sort) {
        case PublicBooksSort.recent:
          query = query.orderBy('createdAt', descending: true);
        case PublicBooksSort.popular:
          query = query
              .orderBy('experienceCount', descending: true)
              .orderBy('createdAt', descending: true);
        case PublicBooksSort.alphabetical:
          query = query.orderBy('title').orderBy('createdAt', descending: true);
      }
    }

    if (startAfterValues != null) {
      query = query.startAfter(startAfterValues);
    }

    return query.limit(limit).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String id) =>
      _travelBooks.doc(id).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> get(String id) =>
      _travelBooks.doc(id).get();

  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) => _travelBooks.add(data);

  Future<void> update(String id, Map<String, dynamic> data) =>
      _travelBooks.doc(id).update(data);

  Future<void> delete(String id) => _travelBooks.doc(id).delete();
}
