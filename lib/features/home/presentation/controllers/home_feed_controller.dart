import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../travel_books/domain/entities/travel_book.dart';
import '../../../travel_books/presentation/providers/travel_book_providers.dart';

const _pageSize = 10;

/// [featured] is the most recent public book, shown separately from
/// [books] (the "latest published" list right below it) so it isn't
/// duplicated.
class HomeFeedState {
  const HomeFeedState({
    required this.featured,
    required this.books,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final TravelBook? featured;
  final List<TravelBook> books;
  final bool hasMore;
  final bool isLoadingMore;

  HomeFeedState copyWith({
    List<TravelBook>? books,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return HomeFeedState(
      featured: featured,
      books: books ?? this.books,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Curated public feed: a featured book plus the latest published books,
/// paginated, with pull-to-refresh.
class HomeFeedController extends AsyncNotifier<HomeFeedState> {
  @override
  Future<HomeFeedState> build() => _fetchFirstPage();

  Future<HomeFeedState> _fetchFirstPage() async {
    final page = await ref
        .read(travelBookRepositoryProvider)
        .fetchPublicTravelBooks(limit: _pageSize + 1);
    if (page.books.isEmpty) {
      return const HomeFeedState(featured: null, books: [], hasMore: false);
    }
    return HomeFeedState(
      featured: page.books.first,
      books: page.books.skip(1).toList(),
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final cursor = current.books.isNotEmpty
        ? current.books.last
        : current.featured;
    try {
      final page = await ref
          .read(travelBookRepositoryProvider)
          .fetchPublicTravelBooks(limit: _pageSize, startAfter: cursor);
      state = AsyncData(
        current.copyWith(
          books: [...current.books, ...page.books],
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final homeFeedControllerProvider =
    AsyncNotifierProvider<HomeFeedController, HomeFeedState>(
      HomeFeedController.new,
    );
