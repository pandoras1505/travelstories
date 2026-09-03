import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validation_messages.dart';
import '../../../../core/utils/validators.dart';
import '../auth_error_messages.dart';
import '../controllers/login_controller.dart';

/// Email/password + Google sign-in. On success there is nothing left to do
/// here: `app_router.dart`'s redirect reacts to the auth state stream and
/// takes the user to [RoutePaths.home] on its own.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(loginControllerProvider.notifier)
        .signInWithEmail(email: _emailController.text.trim(), password: _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(loginControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(loginControllerProvider, (previous, next) {
      final error = next.error;
      if (error is AuthException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(context, error))));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.authLogin, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.appTagline, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: l10n.authEmailLabel),
                    validator: (value) => validationErrorMessage(context, Validators.email(value)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: l10n.authPasswordLabel),
                    validator: (value) => validationErrorMessage(context, Validators.password(value)),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(RoutePaths.forgotPassword),
                      child: Text(l10n.authForgotPassword),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.authLoginButton),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Text(l10n.commonOr, style: theme.textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => ref.read(loginControllerProvider.notifier).signInWithGoogle(),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: Text(l10n.authSignInWithGoogle),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.authNoAccount, style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.push(RoutePaths.register),
                        child: Text(l10n.authRegister),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
