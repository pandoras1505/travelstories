import '../entities/travel_book.dart';

/// Ordering for [TravelBookRepository.fetchPublicTravelBooks]. Ignored
/// (falls back to title order) whenever a `titlePrefix` search is active —
/// Firestore requires the range-filtered field to be the primary orderBy.
enum PublicBooksSort { recent, popular, alphabetical }

/// One page of [TravelBookRepository.fetchPublicTravelBooks]. [hasMore]
/// tells the caller whether passing the last entry of [books] as the next
/// call's `startAfter` would yield further results.
typedef PublicTravelBooksPage = ({List<TravelBook> books, bool hasMore});

abstract class TravelBookRepository {
  /// The current user's own travel books (drafts + published), newest
  /// update first.
  Stream<List<TravelBook>> watchMyTravelBooks(String ownerId);

  Stream<TravelBook?> watchTravelBook(String id);

  /// A page of public travel books (`isPublic == true`), for the Home feed
  /// and Explore search.
  ///
  /// - [titlePrefix], when non-empty, does a case-sensitive prefix match on
  ///   `title` and forces title ordering regardless of [sort].
  /// - Pass the last [TravelBook] of the previous page as [startAfter] to
  ///   fetch the next one; omit for the first page.
  Future<PublicTravelBooksPage> fetchPublicTravelBooks({
    PublicBooksSort sort = PublicBooksSort.recent,
    String? titlePrefix,
    int limit = 10,
    TravelBook? startAfter,
  });

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
