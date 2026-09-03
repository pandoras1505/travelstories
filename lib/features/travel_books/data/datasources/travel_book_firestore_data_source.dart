import 'package:cloud_firestore/cloud_firestore.dart';

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
