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
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/travel_book.dart';

/// A public travel book card for the Home feed and Explore results — cover,
/// title, experience count and a lightweight author join
/// ([authorProfileProvider]) since the schema doesn't denormalize author
/// info onto the book document.
class PublicTravelBookCard extends ConsumerWidget {
  const PublicTravelBookCard({super.key, required this.book});

  final TravelBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final authorAsync = ref.watch(authorProfileProvider(book.ownerId));

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
                    Text(
                      book.title.isEmpty ? l10n.travelBookNewTitle : book.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: authorAsync.when(
                            loading: () => const SizedBox(height: 20),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                            data: (author) => author == null
                                ? const SizedBox.shrink()
                                : _AuthorRow(
                                    name: author.displayName,
                                    label: l10n.commonByAuthor(
                                      author.displayName,
                                    ),
                                    photoUrl: author.photoUrl,
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.route_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${book.experienceCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.name, required this.label, this.photoUrl});

  final String name;
  final String label;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundImage: photoUrl != null
              ? CachedNetworkImageProvider(
                  photoUrl!,
                  maxWidth: AppImageCache.smallAvatar,
                  maxHeight: AppImageCache.smallAvatar,
                )
              : null,
          child: photoUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: theme.textTheme.labelSmall,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
