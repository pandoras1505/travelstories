import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Placeholder matching [PublicTravelBookCard]'s layout, shown while the
/// first page of a public feed is loading.
class PublicTravelBookCardSkeleton extends StatelessWidget {
  const PublicTravelBookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: ShimmerBox()),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerBox(width: 160, height: 16),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
