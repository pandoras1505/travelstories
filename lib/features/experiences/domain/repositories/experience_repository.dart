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

  /// Uploads the (already processed — compressed image, or video +
  /// generated thumbnail) media, then updates the experience's
  /// `mediaType`/`mediaUrl`/`thumbnailUrl`.
  Future<void> uploadMedia({
    required String travelBookId,
    required String id,
    required ExperienceMediaType mediaType,
    required List<int> bytes,
    required String extension,
    List<int>? thumbnailBytes,
  });

  /// Deletes the experience's media from Storage and resets
  /// `mediaType`/`mediaUrl`/`thumbnailUrl` back to text/null.
  Future<void> removeMedia({required String travelBookId, required String id});
}
