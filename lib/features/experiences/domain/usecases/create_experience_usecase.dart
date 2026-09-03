import '../repositories/experience_repository.dart';

class CreateExperienceUseCase {
  const CreateExperienceUseCase(this._repository);

  final ExperienceRepository _repository;

  Future<String> call({
    required String travelBookId,
    required String ownerId,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) {
    return _repository.createExperience(
      travelBookId: travelBookId,
      ownerId: ownerId,
      title: title,
      description: description,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
