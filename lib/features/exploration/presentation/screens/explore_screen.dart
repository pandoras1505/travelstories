import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// Search/filter/sort over public travel books, built in the Exploration
/// phase.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navExplore)),
      body: EmptyStateView(
        icon: Icons.travel_explore_outlined,
        title: l10n.navExplore,
      ),
    );
  }
}
