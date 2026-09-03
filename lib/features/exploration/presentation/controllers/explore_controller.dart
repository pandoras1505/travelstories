import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../travel_books/domain/entities/travel_book.dart';
import '../../../travel_books/domain/repositories/travel_book_repository.dart';
import '../../../travel_books/presentation/providers/travel_book_providers.dart';

const _pageSize = 20;

class ExploreState {
  const ExploreState({
    required this.books,
    required this.hasMore,
    required this.sort,
    required this.searchText,
    this.isLoadingMore = false,
  });

  final List<TravelBook> books;
  final bool hasMore;
  final PublicBooksSort sort;
  final String searchText;
  final bool isLoadingMore;

  bool get isSearching => searchText.isNotEmpty;

  ExploreState copyWith({
    List<TravelBook>? books,
    bool? hasMore,
    PublicBooksSort? sort,
    String? searchText,
    bool? isLoadingMore,
  }) {
    return ExploreState(
      books: books ?? this.books,
      hasMore: hasMore ?? this.hasMore,
      sort: sort ?? this.sort,
      searchText: searchText ?? this.searchText,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Search + sort over public travel books. Sort is forced to title order by
/// the repository whenever a search is active (see
/// [TravelBookRepository.fetchPublicTravelBooks]), so [changeSort] and
/// [search] are independent knobs the UI can disable/enable accordingly.
class ExploreController extends AsyncNotifier<ExploreState> {
  @override
  Future<ExploreState> build() =>
      _fetch(sort: PublicBooksSort.recent, searchText: '');

  Future<ExploreState> _fetch({
    required PublicBooksSort sort,
    required String searchText,
  }) async {
    final page = await ref
        .read(travelBookRepositoryProvider)
        .fetchPublicTravelBooks(
          sort: sort,
          titlePrefix: searchText.isEmpty ? null : searchText,
          limit: _pageSize,
        );
    return ExploreState(
      books: page.books,
      hasMore: page.hasMore,
      sort: sort,
      searchText: searchText,
    );
  }

  Future<void> search(String text) async {
    final sort = state.value?.sort ?? PublicBooksSort.recent;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(sort: sort, searchText: text.trim()),
    );
  }

  Future<void> changeSort(PublicBooksSort sort) async {
    final searchText = state.value?.searchText ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(sort: sort, searchText: searchText),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref
          .read(travelBookRepositoryProvider)
          .fetchPublicTravelBooks(
            sort: current.sort,
            titlePrefix: current.searchText.isEmpty ? null : current.searchText,
            limit: _pageSize,
            startAfter: current.books.isNotEmpty ? current.books.last : null,
          );
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

final exploreControllerProvider =
    AsyncNotifierProvider<ExploreController, ExploreState>(
      ExploreController.new,
    );
