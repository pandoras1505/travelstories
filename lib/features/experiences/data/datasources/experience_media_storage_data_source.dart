import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Storage uploads for one experience's media
/// (`travelBooks/{bookId}/experiences/{experienceId}/media.*` and
/// `.../thumbnail.jpg`). Lets Storage exceptions propagate untouched —
/// mapping to [StorageException] happens one layer up, in
/// [ExperienceRepositoryImpl].
class ExperienceMediaStorageDataSource {
  ExperienceMediaStorageDataSource({required FirebaseStorage storage})
    : _storage = storage;

  final FirebaseStorage _storage;

  Future<String> uploadMedia({
    required String travelBookId,
    required String experienceId,
    required List<int> bytes,
    required String extension,
  }) async {
    final ref = _storage.ref(
      'travelBooks/$travelBookId/experiences/$experienceId/media.$extension',
    );
    await ref.putData(Uint8List.fromList(bytes));
    return ref.getDownloadURL();
  }

  Future<String> uploadThumbnail({
    required String travelBookId,
    required String experienceId,
    required List<int> bytes,
  }) async {
    final ref = _storage.ref(
      'travelBooks/$travelBookId/experiences/$experienceId/thumbnail.jpg',
    );
    await ref.putData(Uint8List.fromList(bytes));
    return ref.getDownloadURL();
  }

  /// Best-effort delete of every object under this experience's media
  /// folder. Missing objects (e.g. no thumbnail was ever generated) are not
  /// an error.
  Future<void> deleteAll({
    required String travelBookId,
    required String experienceId,
  }) async {
    final folder = _storage.ref(
      'travelBooks/$travelBookId/experiences/$experienceId',
    );
    final listing = await folder.listAll();
    for (final item in listing.items) {
      try {
        await item.delete();
      } on FirebaseException {
        // Already gone or not permitted — nothing more we can do here.
      }
    }
  }
}
