import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// Entry point of the travel book creation workflow (basic info → cover →
/// experiences → preview → publish), built in the Travel Books CRUD phase.
class CreateEntryScreen extends StatelessWidget {
  const CreateEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCreate)),
      body: EmptyStateView(
        icon: Icons.add_circle_outline,
        title: l10n.navCreate,
      ),
    );
  }
}
