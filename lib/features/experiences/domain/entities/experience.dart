import 'package:freezed_annotation/freezed_annotation.dart';

part 'experience.freezed.dart';

/// Distinguishes what kind of media (if any) an experience carries.
/// `text` experiences have no media yet — the capture pipeline for
/// image/video ships in a later phase.
enum ExperienceMediaType { text, image, video }

/// A `travelBooks/{travelBookId}/experiences/{id}` Firestore document.
@freezed
abstract class Experience with _$Experience {
  const factory Experience({
    required String id,
    required String travelBookId,
    required String ownerId,
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    String? locationName,
    required ExperienceMediaType mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Experience;
}
