import '../../../../core/media/local_media_store.dart';

/// Stores the current user's avatar locally on-device — Firebase Storage
/// isn't activated (see HANDOFF.md §4.3/§8). Lets I/O exceptions propagate
/// untouched — mapping to `StorageException` happens one layer up, in
/// `ProfileRepositoryImpl`.
class AvatarStorageDataSource {
  const AvatarStorageDataSource();

  Future<String> upload({
    required String uid,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final dir = 'users/$uid/profile';
    // The previous avatar may have used a different extension — clear the
    // whole directory first so it doesn't linger alongside the new file.
    await deleteMediaDirectory(dir);
    return writeMediaFile(
      relativePath: '$dir/avatar.$fileExtension',
      bytes: fileBytes,
    );
  }
}
