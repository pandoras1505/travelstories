import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../travel_books/domain/repositories/travel_book_repository.dart';
import '../../../travel_books/presentation/widgets/public_travel_book_card.dart';
import '../../../travel_books/presentation/widgets/public_travel_book_card_skeleton.dart';
import '../controllers/explore_controller.dart';

/// Search + filter + sort over public travel books (section 20 of the
/// brief) — deliberately no likes/favorites/comments/following, out of
/// scope for the MVP.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(exploreControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(exploreControllerProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exploreAsync = ref.watch(exploreControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navExplore)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.exploreSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                      ),
              ),
              onSubmitted: (_) {},
            ),
          ),
          _SortBar(
            enabled: !(exploreAsync.value?.isSearching ?? false),
            selected: exploreAsync.value?.sort ?? PublicBooksSort.recent,
            searching: exploreAsync.value?.isSearching ?? false,
          ),
          Expanded(
            child: exploreAsync.when(
              loading: () => const _ExploreSkeleton(),
              error: (error, stackTrace) => ErrorView(
                message: l10n.commonError,
                onRetry: () => ref.invalidate(exploreControllerProvider),
              ),
              data: (state) {
                if (state.books.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.travel_explore_outlined,
                    title: l10n.exploreEmptyTitle,
                    message: l10n.exploreEmptyMessage,
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: state.books.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index >= state.books.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return PublicTravelBookCard(book: state.books[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortBar extends ConsumerWidget {
  const _SortBar({
    required this.enabled,
    required this.selected,
    required this.searching,
  });

  final bool enabled;
  final PublicBooksSort selected;
  final bool searching;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _SortChip(
                label: l10n.exploreSortRecent,
                sort: PublicBooksSort.recent,
                selected: selected,
                enabled: enabled,
              ),
              _SortChip(
                label: l10n.exploreSortPopular,
                sort: PublicBooksSort.popular,
                selected: selected,
                enabled: enabled,
              ),
              _SortChip(
                label: l10n.exploreSortAlphabetical,
                sort: PublicBooksSort.alphabetical,
                selected: selected,
                enabled: enabled,
              ),
            ],
          ),
          if (searching)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.exploreSortingByTitleWhileSearching,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortChip extends ConsumerWidget {
  const _SortChip({
    required this.label,
    required this.sort,
    required this.selected,
    required this.enabled,
  });

  final String label;
  final PublicBooksSort sort;
  final PublicBooksSort selected;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == sort,
      onSelected: !enabled
          ? null
          : (_) =>
                ref.read(exploreControllerProvider.notifier).changeSort(sort),
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 4,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const PublicTravelBookCardSkeleton(),
    );
  }
}
