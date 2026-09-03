import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
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
                sliver: SliverList.list(children: [_DetailBody(book: book)]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.book});

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
        const SizedBox(height: AppSpacing.md),
        EmptyStateView(
          icon: Icons.route_outlined,
          title: l10n.travelBookNoExperiencesYet,
        ),
      ],
    );
  }
}
