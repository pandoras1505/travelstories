import '../entities/experience.dart';
import '../repositories/experience_repository.dart';

class UploadExperienceMediaUseCase {
  const UploadExperienceMediaUseCase(this._repository);

  final ExperienceRepository _repository;

  Future<void> call({
    required String travelBookId,
    required String id,
    required ExperienceMediaType mediaType,
    required List<int> bytes,
    required String extension,
    List<int>? thumbnailBytes,
  }) {
    return _repository.uploadMedia(
      travelBookId: travelBookId,
      id: id,
      mediaType: mediaType,
      bytes: bytes,
      extension: extension,
      thumbnailBytes: thumbnailBytes,
    );
  }
}
