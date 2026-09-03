import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_providers.dart';
import '../localization/generated/app_localizations.dart';
import '../theme/app_spacing.dart';

/// Persistent "You are offline" strip while there's no connectivity, then a
/// brief "Back online. Syncing..." confirmation for a few seconds after
/// reconnecting. Collapses to nothing the rest of the time.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  static const _backOnlineDuration = Duration(seconds: 3);

  bool _showBackOnline = false;
  Timer? _backOnlineTimer;

  @override
  void dispose() {
    _backOnlineTimer?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged(
    AsyncValue<bool>? previous,
    AsyncValue<bool> next,
  ) {
    final wasOnline = previous?.value;
    final isOnline = next.value;
    if (wasOnline == false && isOnline == true) {
      _backOnlineTimer?.cancel();
      setState(() => _showBackOnline = true);
      _backOnlineTimer = Timer(_backOnlineDuration, () {
        if (mounted) setState(() => _showBackOnline = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider).value;
    ref.listen(isOnlineProvider, _onConnectivityChanged);

    final isOffline = isOnline == false;
    final visible = isOffline || _showBackOnline;

    final backgroundColor = isOffline
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final foregroundColor = isOffline
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Material(
              color: backgroundColor,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOffline
                            ? Icons.cloud_off_outlined
                            : Icons.cloud_done_outlined,
                        size: 16,
                        color: foregroundColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isOffline ? l10n.commonOffline : l10n.commonBackOnline,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
