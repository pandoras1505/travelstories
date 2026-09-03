import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';

/// Placeholder for the email/password + Google sign-in flow built in the
/// Authentication phase. Only inter-screen navigation is wired here.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.authLogin, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.appTagline, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => context.push(RoutePaths.forgotPassword),
                child: Text(l10n.authForgotPassword),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.register),
                child: Text(l10n.authRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
