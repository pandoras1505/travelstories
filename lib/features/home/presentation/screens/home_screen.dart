import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_image_cache.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../travel_books/domain/entities/travel_book.dart';
import '../../../travel_books/presentation/widgets/public_travel_book_card.dart';
import '../../../travel_books/presentation/widgets/public_travel_book_card_skeleton.dart';
import '../controllers/home_feed_controller.dart';

/// Curated public feed: a featured book plus the latest published books
/// (`isPublic == true`), paginated with pull-to-refresh.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(homeFeedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(homeFeedControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHome)),
      body: feedAsync.when(
        loading: () => const _HomeFeedSkeleton(),
        error: (error, stackTrace) => ErrorView(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(homeFeedControllerProvider),
        ),
        data: (state) {
          if (state.featured == null) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(homeFeedControllerProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: EmptyStateView(
                      icon: Icons.explore_outlined,
                      title: l10n.homeEmptyTitle,
                      message: l10n.homeEmptyMessage,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(homeFeedControllerProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _FeaturedBookCard(book: state.featured!),
                  ),
                ),
                if (state.books.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.homeSectionLatest,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: state.books.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) =>
                        PublicTravelBookCard(book: state.books[index]),
                  ),
                ),
                if (state.isLoadingMore)
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedBookCard extends StatelessWidget {
  const _FeaturedBookCard({required this.book});

  final TravelBook book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.homeFeaturedLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('${RoutePaths.travelBooks}/${book.id}'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgRadius,
                boxShadow: AppShadows.elevated(theme.brightness),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: book.coverImageUrl != null
                        ? AppImage(
                            path: book.coverImageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: AppImageCache.coverWidth,
                          )
                        : ColoredBox(
                            color: scheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.landscape_outlined,
                              size: 48,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                      child: Text(
                        book.title.isEmpty
                            ? l10n.travelBookNewTitle
                            : book.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeFeedSkeleton extends StatelessWidget {
  const _HomeFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        AspectRatio(aspectRatio: 16 / 10, child: ShimmerBox()),
        SizedBox(height: AppSpacing.xl),
        PublicTravelBookCardSkeleton(),
        SizedBox(height: AppSpacing.md),
        PublicTravelBookCardSkeleton(),
        SizedBox(height: AppSpacing.md),
        PublicTravelBookCardSkeleton(),
      ],
    );
  }
}
