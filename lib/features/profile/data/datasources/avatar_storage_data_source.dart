import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Storage uploads for profile avatars. Lets Storage
/// exceptions propagate untouched — mapping to [StorageException] happens
/// one layer up, in [ProfileRepositoryImpl].
class AvatarStorageDataSource {
  AvatarStorageDataSource({required FirebaseStorage storage}) : _storage = storage;

  final FirebaseStorage _storage;

  Future<String> upload({required String uid, required List<int> fileBytes, required String fileExtension}) async {
    final ref = _storage.ref('users/$uid/profile/avatar.$fileExtension');
    await ref.putData(Uint8List.fromList(fileBytes));
    return ref.getDownloadURL();
  }
}
