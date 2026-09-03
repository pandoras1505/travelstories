import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// Curated public feed built in the Home Feed phase (featured travel book,
/// popular destinations, latest published books).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHome)),
      body: EmptyStateView(icon: Icons.explore_outlined, title: l10n.navHome),
    );
  }
}
