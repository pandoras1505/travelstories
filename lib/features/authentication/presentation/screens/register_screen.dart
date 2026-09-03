import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// Placeholder for the registration form built in the Authentication phase.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authRegister)),
      body: EmptyStateView(
        icon: Icons.person_add_alt_1_outlined,
        title: l10n.authRegister,
      ),
    );
  }
}
