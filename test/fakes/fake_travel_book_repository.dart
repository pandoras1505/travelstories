import 'dart:async';

import 'package:travelstories/features/travel_books/domain/entities/travel_book.dart';
import 'package:travelstories/features/travel_books/domain/repositories/travel_book_repository.dart';

/// In-memory [TravelBookRepository] for widget/unit tests — no Firestore/
/// Storage SDK involved.
class FakeTravelBookRepository implements TravelBookRepository {
  final Map<String, TravelBook> _books = {};
  final _byOwnerController = StreamController<void>.broadcast();
  final _byIdControllers = <String, StreamController<TravelBook?>>{};
  int _nextId = 0;

  StreamController<TravelBook?> _controllerFor(String id) {
    return _byIdControllers.putIfAbsent(
      id,
      () => StreamController<TravelBook?>.broadcast(),
    );
  }

  @override
  Stream<List<TravelBook>> watchMyTravelBooks(String ownerId) async* {
    List<TravelBook> current() =>
        _books.values.where((b) => b.ownerId == ownerId).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    yield current();
    yield* _byOwnerController.stream.map((_) => current());
  }

  @override
  Stream<TravelBook?> watchTravelBook(String id) async* {
    yield _books[id];
    yield* _controllerFor(id).stream;
  }

  @override
  Future<PublicTravelBooksPage> fetchPublicTravelBooks({
    PublicBooksSort sort = PublicBooksSort.recent,
    String? titlePrefix,
    int limit = 10,
    TravelBook? startAfter,
  }) async {
    var results = _books.values.where((b) => b.isPublic).toList();

    final trimmedPrefix = titlePrefix?.trim();
    final searching = trimmedPrefix != null && trimmedPrefix.isNotEmpty;
    if (searching) {
      results = results
          .where((b) => b.title.startsWith(trimmedPrefix))
          .toList();
      results.sort((a, b) {
        final byTitle = a.title.compareTo(b.title);
        return byTitle != 0 ? byTitle : b.createdAt.compareTo(a.createdAt);
      });
    } else {
      switch (sort) {
        case PublicBooksSort.recent:
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        case PublicBooksSort.popular:
          results.sort((a, b) {
            final byCount = b.experienceCount.compareTo(a.experienceCount);
            return byCount != 0 ? byCount : b.createdAt.compareTo(a.createdAt);
          });
        case PublicBooksSort.alphabetical:
          results.sort((a, b) {
            final byTitle = a.title.compareTo(b.title);
            return byTitle != 0 ? byTitle : b.createdAt.compareTo(a.createdAt);
          });
      }
    }

    if (startAfter != null) {
      final cursorIndex = results.indexWhere((b) => b.id == startAfter.id);
      results = cursorIndex == -1 ? const [] : results.sublist(cursorIndex + 1);
    }

    final hasMore = results.length > limit;
    return (books: results.take(limit).toList(), hasMore: hasMore);
  }

  @override
  Future<String> createTravelBook({
    required String ownerId,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required bool isPublic,
  }) async {
    final id = 'book-${_nextId++}';
    // Offset by insertion order rather than relying on wall-clock gaps
    // between calls: tests must never `await Future.delayed(...)` to force
    // distinct timestamps — that deadlocks under flutter_test's fake clock,
    // which only advances via `tester.pump`.
    final now = DateTime.now().add(Duration(microseconds: _nextId));
    _books[id] = TravelBook(
      id: id,
      ownerId: ownerId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isPublic: isPublic,
      createdAt: now,
      updatedAt: now,
      publishedAt: isPublic ? now : null,
      experienceCount: 0,
    );
    _byOwnerController.add(null);
    _controllerFor(id).add(_books[id]);
    return id;
  }

  @override
  Future<void> updateTravelBook({
    required String id,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final existing = _books[id];
    if (existing == null) return;
    final updated = existing.copyWith(
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      updatedAt: DateTime.now(),
    );
    _books[id] = updated;
    _byOwnerController.add(null);
    _controllerFor(id).add(updated);
  }

  @override
  Future<void> publishTravelBook(String id) async {
    final existing = _books[id];
    if (existing == null) return;
    final updated = existing.copyWith(
      isPublic: true,
      publishedAt: existing.publishedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _books[id] = updated;
    _byOwnerController.add(null);
    _controllerFor(id).add(updated);
  }

  @override
  Future<void> unpublishTravelBook(String id) async {
    final existing = _books[id];
    if (existing == null) return;
    final updated = existing.copyWith(
      isPublic: false,
      updatedAt: DateTime.now(),
    );
    _books[id] = updated;
    _byOwnerController.add(null);
    _controllerFor(id).add(updated);
  }

  @override
  Future<void> deleteTravelBook(String id) async {
    _books.remove(id);
    _byOwnerController.add(null);
    _controllerFor(id).add(null);
  }

  @override
  Future<String> uploadCover({
    required String travelBookId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    const url = 'https://example.com/fake-cover.jpg';
    final existing = _books[travelBookId];
    if (existing != null) {
      final updated = existing.copyWith(
        coverImageUrl: url,
        updatedAt: DateTime.now(),
      );
      _books[travelBookId] = updated;
      _byOwnerController.add(null);
      _controllerFor(travelBookId).add(updated);
    }
    return url;
  }
}
