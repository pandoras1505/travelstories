import 'package:flutter/widgets.dart';

import '../localization/generated/app_localizations.dart';
import 'validators.dart';

/// Maps a [ValidationError] to its localized message. Kept separate from
/// [Validators] so the validators themselves stay free of any Flutter
/// dependency and are trivial to unit-test.
String? validationErrorMessage(BuildContext context, ValidationError? error) {
  if (error == null) return null;
  final l10n = AppLocalizations.of(context)!;
  return switch (error) {
    ValidationError.emailRequired => l10n.validationEmailRequired,
    ValidationError.emailInvalid => l10n.validationEmailInvalid,
    ValidationError.passwordRequired => l10n.validationPasswordRequired,
    ValidationError.passwordTooShort => l10n.validationPasswordTooShort,
    ValidationError.displayNameRequired => l10n.validationDisplayNameRequired,
    ValidationError.passwordsDoNotMatch => l10n.validationPasswordsDoNotMatch,
  };
}
