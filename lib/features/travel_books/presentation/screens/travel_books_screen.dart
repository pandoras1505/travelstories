import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// The current user's travel books (drafts + published), built in the
/// Travel Books CRUD phase.
class TravelBooksScreen extends StatelessWidget {
  const TravelBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTravelBooks)),
      body: EmptyStateView(
        icon: Icons.menu_book_outlined,
        title: l10n.navTravelBooks,
      ),
    );
  }
}
