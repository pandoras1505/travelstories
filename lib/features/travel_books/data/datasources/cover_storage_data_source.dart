import '../../../../core/media/local_media_store.dart';

/// Stores a travel book's cover locally on-device — Firebase Storage isn't
/// activated (see HANDOFF.md §4.3/§8). Lets I/O exceptions propagate
/// untouched — mapping to `StorageException` happens one layer up, in
/// `TravelBookRepositoryImpl`.
class CoverStorageDataSource {
  const CoverStorageDataSource();

  Future<String> upload({
    required String travelBookId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final dir = 'travelBooks/$travelBookId/cover';
    // The previous cover may have used a different extension — clear the
    // whole directory first so it doesn't linger alongside the new file.
    await deleteMediaDirectory(dir);
    return writeMediaFile(
      relativePath: '$dir/cover.$fileExtension',
      bytes: fileBytes,
    );
  }
}
