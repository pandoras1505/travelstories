import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around the `travelBooks/{id}/experiences` subcollection.
/// Lets Firestore exceptions propagate untouched — mapping to
/// [FirestoreException] happens one layer up, in [ExperienceRepositoryImpl].
class ExperienceFirestoreDataSource {
  ExperienceFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _travelBookDoc(String travelBookId) =>
      _firestore.collection('travelBooks').doc(travelBookId);

  CollectionReference<Map<String, dynamic>> _experiences(String travelBookId) =>
      _travelBookDoc(travelBookId).collection('experiences');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAll(String travelBookId) {
    return _experiences(
      travelBookId,
    ).orderBy('createdAt', descending: false).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOne({
    required String travelBookId,
    required String id,
  }) {
    return _experiences(travelBookId).doc(id).snapshots();
  }

  /// Creates the experience doc and increments the parent's
  /// `experienceCount` in one atomic batch.
  Future<String> addAndIncrementCount(
    String travelBookId,
    Map<String, dynamic> data,
  ) async {
    final ref = _experiences(travelBookId).doc();
    final batch = _firestore.batch()
      ..set(ref, data)
      ..update(_travelBookDoc(travelBookId), {
        'experienceCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    return ref.id;
  }

  Future<void> update(
    String travelBookId,
    String id,
    Map<String, dynamic> data,
  ) {
    return _experiences(travelBookId).doc(id).update(data);
  }

  /// Deletes the experience doc and decrements the parent's
  /// `experienceCount` in one atomic batch.
  Future<void> deleteAndDecrementCount(String travelBookId, String id) async {
    final batch = _firestore.batch()
      ..delete(_experiences(travelBookId).doc(id))
      ..update(_travelBookDoc(travelBookId), {
        'experienceCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }
}
