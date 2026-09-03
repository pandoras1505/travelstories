import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Storage uploads for travel book covers. Lets Storage
/// exceptions propagate untouched — mapping to [StorageException] happens
/// one layer up, in [TravelBookRepositoryImpl].
class CoverStorageDataSource {
  CoverStorageDataSource({required FirebaseStorage storage})
    : _storage = storage;

  final FirebaseStorage _storage;

  Future<String> upload({
    required String travelBookId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final ref = _storage.ref(
      'travelBooks/$travelBookId/cover/cover.$fileExtension',
    );
    await ref.putData(Uint8List.fromList(fileBytes));
    return ref.getDownloadURL();
  }
}
