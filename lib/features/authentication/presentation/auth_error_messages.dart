import 'package:flutter/widgets.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/localization/generated/app_localizations.dart';

/// Maps an [AuthException.code] to a localized, user-safe message. Never
/// surface [AuthException.message] or the raw provider code directly — both
/// are logging-only.
String authErrorMessage(BuildContext context, AuthException exception) {
  final l10n = AppLocalizations.of(context)!;
  return switch (exception.code) {
    'invalid-email' => l10n.authErrorInvalidEmail,
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => l10n.authErrorInvalidCredential,
    'user-disabled' => l10n.authErrorUserDisabled,
    'email-already-in-use' => l10n.authErrorEmailInUse,
    'weak-password' => l10n.authErrorWeakPassword,
    'too-many-requests' => l10n.authErrorTooManyRequests,
    'network-request-failed' => l10n.authErrorNetwork,
    'google-sign-in-failed' => l10n.authErrorGoogleSignInFailed,
    _ => l10n.authErrorUnknown,
  };
}
