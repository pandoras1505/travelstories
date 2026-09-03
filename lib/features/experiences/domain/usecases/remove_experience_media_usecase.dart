import '../repositories/experience_repository.dart';

class RemoveExperienceMediaUseCase {
  const RemoveExperienceMediaUseCase(this._repository);

  final ExperienceRepository _repository;

  Future<void> call({required String travelBookId, required String id}) {
    return _repository.removeMedia(travelBookId: travelBookId, id: id);
  }
}
