import '../entities/experience.dart';

abstract class ExperienceRepository {
  /// The experiences of one travel book, in chronological order (creation
  /// order — the timeline reads top to bottom as "what happened first").
  Stream<List<Experience>> watchExperiences(String travelBookId);

  Stream<Experience?> watchExperience({
    required String travelBookId,
    required String id,
  });

  /// Creates the experience and atomically increments the parent travel
  /// book's `experienceCount`.
  Future<String> createExperience({
    required String travelBookId,
    required String ownerId,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  });

  Future<void> updateExperience({
    required String travelBookId,
    required String id,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  });

  /// Deletes the experience and atomically decrements the parent travel
  /// book's `experienceCount`.
  Future<void> deleteExperience({
    required String travelBookId,
    required String id,
  });
}
