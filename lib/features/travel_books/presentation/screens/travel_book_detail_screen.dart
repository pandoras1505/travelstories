import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../experiences/domain/entities/experience.dart';
import '../../../experiences/presentation/providers/experience_providers.dart';
import '../../domain/entities/travel_book.dart';
import '../providers/travel_book_providers.dart';

class TravelBookDetailScreen extends ConsumerWidget {
  const TravelBookDetailScreen({super.key, required this.travelBookId});

  final String travelBookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookAsync = ref.watch(travelBookProvider(travelBookId));
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;

    return bookAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: l10n.commonError),
      ),
      data: (book) {
        if (book == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyStateView(
              icon: Icons.menu_book_outlined,
              title: l10n.commonEmpty,
            ),
          );
        }
        final isOwner = book.ownerId == currentUid;
        return Scaffold(
          floatingActionButton: isOwner
              ? FloatingActionButton.extended(
                  onPressed: () => context.push(
                    '${RoutePaths.travelBooks}/$travelBookId/experiences/new',
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.experienceAdd),
                )
              : null,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(
                        '${RoutePaths.travelBooks}/$travelBookId/edit',
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: book.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.coverImageUrl!,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.landscape_outlined,
                            size: 56,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.list(children: [_DetailHeader(book: book)]),
              ),
              _ExperienceTimeline(travelBookId: travelBookId),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.book});

  final TravelBook book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = MaterialLocalizations.of(context).formatMediumDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          book.title.isEmpty ? l10n.travelBookNewTitle : book.title,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (book.startDate != null || book.endDate != null)
          Text(
            [
              if (book.startDate != null) dateFormat(book.startDate!),
              if (book.endDate != null) dateFormat(book.endDate!),
            ].join(' – '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (book.description.isNotEmpty)
          Text(book.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        Divider(color: theme.colorScheme.outlineVariant),
      ],
    );
  }
}

class _ExperienceTimeline extends ConsumerWidget {
  const _ExperienceTimeline({required this.travelBookId});

  final String travelBookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final experiencesAsync = ref.watch(
      experiencesForBookProvider(travelBookId),
    );

    return experiencesAsync.when(
      loading: () => const SliverToBoxAdapter(child: LoadingView()),
      error: (error, stackTrace) =>
          SliverToBoxAdapter(child: ErrorView(message: l10n.commonError)),
      data: (experiences) {
        if (experiences.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: EmptyStateView(
                icon: Icons.route_outlined,
                title: l10n.travelBookNoExperiencesYet,
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.separated(
            itemCount: experiences.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _ExperienceCard(
              travelBookId: travelBookId,
              experience: experiences[index],
            ),
          ),
        );
      },
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.travelBookId, required this.experience});

  final String travelBookId;
  final Experience experience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasMedia = experience.mediaType != ExperienceMediaType.text;
    final previewUrl = experience.mediaType == ExperienceMediaType.image
        ? experience.mediaUrl
        : experience.thumbnailUrl;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.mdRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '${RoutePaths.travelBooks}/$travelBookId/experiences/${experience.id}/edit',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMedia)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    previewUrl != null
                        ? CachedNetworkImage(
                            imageUrl: previewUrl,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(color: scheme.surfaceContainerHigh),
                    if (experience.mediaType == ExperienceMediaType.video)
                      Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 40,
                          color: scheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(experience.title, style: theme.textTheme.titleMedium),
                  if (experience.locationName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          experience.locationName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (experience.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      experience.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
