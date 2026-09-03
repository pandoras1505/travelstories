import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_book.freezed.dart';

/// A `travelBooks/{id}` Firestore document.
@freezed
abstract class TravelBook with _$TravelBook {
  const factory TravelBook({
    required String id,
    required String ownerId,
    required String title,
    required String description,
    String? coverImageUrl,
    DateTime? startDate,
    DateTime? endDate,
    required bool isPublic,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? publishedAt,
    required int experienceCount,
  }) = _TravelBook;
}
