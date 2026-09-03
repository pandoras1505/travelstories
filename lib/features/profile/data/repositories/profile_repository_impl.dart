import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/avatar_storage_data_source.dart';
import '../datasources/profile_firestore_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileFirestoreDataSource firestoreDataSource,
    required AvatarStorageDataSource storageDataSource,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource;

  final ProfileFirestoreDataSource _firestoreDataSource;
  final AvatarStorageDataSource _storageDataSource;

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    try {
      await for (final snapshot in _firestoreDataSource.watch(uid)) {
        yield _toProfile(snapshot);
      }
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final snapshot = await _firestoreDataSource.get(uid);
      return _toProfile(snapshot);
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> ensureProfileExists({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    try {
      final existing = await _firestoreDataSource.get(uid);
      if (existing.exists) return;

      await _firestoreDataSource.set(uid, {
        'id': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': fs.FieldValue.serverTimestamp(),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    try {
      await _firestoreDataSource.update(uid, {
        'displayName': displayName,
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    // cloud_firestore's and firebase_storage's `FirebaseException` are both
    // the same re-exported firebase_core type, so they can't be told apart
    // by catch type — each SDK call gets its own try/catch instead.
    final String downloadUrl;
    try {
      downloadUrl = await _storageDataSource.upload(
        uid: uid,
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
      await _firestoreDataSource.update(uid, {
        'photoUrl': downloadUrl,
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    } on fs.FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }

    return downloadUrl;
  }

  UserProfile? _toProfile(fs.DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    final now = DateTime.now();
    return UserProfile(
      id: data['id'] as String? ?? snapshot.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
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
