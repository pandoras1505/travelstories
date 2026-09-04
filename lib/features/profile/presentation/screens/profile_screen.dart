import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_image_cache.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);
    // The users/{uid} doc no longer stores email (Phase 13 security
    // audit — it's broadly readable for the author join on public book
    // cards, so it must never carry anything sensitive). The signed-in
    // user's own email is already available from the Auth SDK.
    final email = ref.watch(authStateChangesProvider).value?.email;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: l10n.commonError),
        data: (profile) {
          if (profile == null) {
            return EmptyStateView(
              icon: Icons.person_outline,
              title: l10n.navProfile,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: profile.photoUrl != null
                      ? appImageProvider(
                          profile.photoUrl!,
                          maxWidth: AppImageCache.largeAvatar,
                          maxHeight: AppImageCache.largeAvatar,
                        )
                      : null,
                  // A local avatar path only resolves on the device that
                  // wrote it (see AppImage) — silence the framework's
                  // default error reporting for the expected "file doesn't
                  // exist here" case rather than let it reach Crashlytics.
                  onBackgroundImageError: profile.photoUrl != null
                      ? (error, stackTrace) {}
                      : null,
                  child: profile.photoUrl == null
                      ? Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                profile.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _AppearanceSection(),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.push(RoutePaths.editProfile),
                child: Text(l10n.profileEditButton),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => ref.read(signOutUseCaseProvider).call(),
                child: Text(l10n.authSignOut),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lets the user override the OS light/dark setting for this app
/// specifically, persisted via [themeModeProvider]/[saveThemeMode].
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileAppearance,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              icon: const Icon(Icons.brightness_auto_outlined),
              label: Text(l10n.profileAppearanceSystem),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: const Icon(Icons.light_mode_outlined),
              label: Text(l10n.profileAppearanceLight),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: const Icon(Icons.dark_mode_outlined),
              label: Text(l10n.profileAppearanceDark),
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            unawaited(
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selection.first),
            );
          },
        ),
      ],
    );
  }
}
