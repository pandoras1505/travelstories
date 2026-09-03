import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// Placeholder for the password-reset form built in the Authentication phase.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authForgotPassword)),
      body: EmptyStateView(
        icon: Icons.lock_reset_outlined,
        title: l10n.authForgotPassword,
      ),
    );
  }
}
