import '../entities/travel_book.dart';

abstract class TravelBookRepository {
  /// The current user's own travel books (drafts + published), newest
  /// update first.
  Stream<List<TravelBook>> watchMyTravelBooks(String ownerId);

  Stream<TravelBook?> watchTravelBook(String id);

  Future<String> createTravelBook({
    required String ownerId,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required bool isPublic,
  });

  Future<void> updateTravelBook({
    required String id,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Sets `isPublic: true`, stamping `publishedAt` the first time this is
  /// called for a given book (subsequent calls leave it untouched).
  Future<void> publishTravelBook(String id);

  /// Sets `isPublic: false`, taking a published book back to draft.
  Future<void> unpublishTravelBook(String id);

  Future<void> deleteTravelBook(String id);

  Future<String> uploadCover({
    required String travelBookId,
    required List<int> fileBytes,
    required String fileExtension,
  });
}
