import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// The current user's profile (avatar, display name, settings entry point),
/// built in the Profile phase.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: EmptyStateView(icon: Icons.person_outline, title: l10n.navProfile),
    );
  }
}
