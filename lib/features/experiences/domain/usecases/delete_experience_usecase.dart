import '../repositories/experience_repository.dart';

class DeleteExperienceUseCase {
  const DeleteExperienceUseCase(this._repository);

  final ExperienceRepository _repository;

  Future<void> call({required String travelBookId, required String id}) {
    return _repository.deleteExperience(travelBookId: travelBookId, id: id);
  }
}
