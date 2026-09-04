import '../../../../core/media/local_media_store.dart';

/// Stores one experience's media locally on-device
/// (`travelBooks/{bookId}/experiences/{experienceId}/media.*` and
/// `.../thumbnail.jpg`) — Firebase Storage isn't activated (see
/// HANDOFF.md §4.3/§8). Lets I/O exceptions propagate untouched — mapping
/// to `StorageException` happens one layer up, in `ExperienceRepositoryImpl`.
class ExperienceMediaStorageDataSource {
  const ExperienceMediaStorageDataSource();

  String _relativeDir(String travelBookId, String experienceId) =>
      'travelBooks/$travelBookId/experiences/$experienceId';

  Future<String> uploadMedia({
    required String travelBookId,
    required String experienceId,
    required List<int> bytes,
    required String extension,
  }) {
    final dir = _relativeDir(travelBookId, experienceId);
    return writeMediaFile(relativePath: '$dir/media.$extension', bytes: bytes);
  }

  Future<String> uploadThumbnail({
    required String travelBookId,
    required String experienceId,
    required List<int> bytes,
  }) {
    final dir = _relativeDir(travelBookId, experienceId);
    return writeMediaFile(relativePath: '$dir/thumbnail.jpg', bytes: bytes);
  }

  /// Deletes this experience's media folder (both `media.*` and
  /// `thumbnail.jpg`, if present) — a no-op if there's nothing there.
  Future<void> deleteAll({
    required String travelBookId,
    required String experienceId,
  }) {
    return deleteMediaDirectory(_relativeDir(travelBookId, experienceId));
  }
}
