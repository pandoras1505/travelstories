import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around the `users` collection. Lets Firestore exceptions
/// propagate untouched — mapping to [FirestoreException] happens one layer
/// up, in [ProfileRepositoryImpl].
class ProfileFirestoreDataSource {
  ProfileFirestoreDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String uid) => _users.doc(uid).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> get(String uid) => _users.doc(uid).get();

  Future<void> set(String uid, Map<String, dynamic> data) => _users.doc(uid).set(data);

  Future<void> update(String uid, Map<String, dynamic> data) => _users.doc(uid).update(data);
}
