import '../repositories/experience_repository.dart';

class UpdateExperienceUseCase {
  const UpdateExperienceUseCase(this._repository);

  final ExperienceRepository _repository;

  Future<void> call({
    required String travelBookId,
    required String id,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) {
    return _repository.updateExperience(
      travelBookId: travelBookId,
      id: id,
      title: title,
      description: description,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
