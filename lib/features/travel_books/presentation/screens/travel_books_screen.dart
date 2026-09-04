import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_image_cache.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/travel_book.dart';
import '../providers/travel_book_providers.dart';

class TravelBooksScreen extends ConsumerWidget {
  const TravelBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(myTravelBooksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTravelBooks)),
      body: booksAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: l10n.commonError),
        data: (books) {
          if (books.isEmpty) {
            return EmptyStateView(
              icon: Icons.menu_book_outlined,
              title: l10n.travelBookEmptyTitle,
              message: l10n.travelBookEmptyMessage,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: books.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) =>
                _TravelBookCard(book: books[index]),
          );
        },
      ),
    );
  }
}

class _TravelBookCard extends StatelessWidget {
  const _TravelBookCard({required this.book});

  final TravelBook book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${RoutePaths.travelBooks}/${book.id}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            boxShadow: AppShadows.card(theme.brightness),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: book.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.coverImageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: AppImageCache.coverWidth,
                      )
                    : ColoredBox(
                        color: scheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.landscape_outlined,
                          size: 40,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book.title.isEmpty
                                ? l10n.travelBookNewTitle
                                : book.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatusBadge(isPublic: book.isPublic),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      book.description.isEmpty
                          ? l10n.commonEmpty
                          : book.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final color = isPublic ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        isPublic ? l10n.travelBookPublicBadge : l10n.travelBookDraftBadge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
