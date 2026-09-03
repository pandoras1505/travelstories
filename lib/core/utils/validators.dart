/// Form-field validators shared across the app. Each returns `null` when
/// the value is valid, or an error-message *l10n key* consumed by the
/// caller (screens map the key to a localized string — validators
/// themselves stay free of any Flutter/BuildContext dependency).
library;

enum ValidationError {
  emailRequired,
  emailInvalid,
  passwordRequired,
  passwordTooShort,
  displayNameRequired,
  passwordsDoNotMatch,
  titleRequired,
  titleTooLong,
  endDateBeforeStartDate,
}

class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const int minPasswordLength = 8;

  static ValidationError? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return ValidationError.emailRequired;
    if (!_emailPattern.hasMatch(trimmed)) return ValidationError.emailInvalid;
    return null;
  }

  static ValidationError? password(String? value) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) return ValidationError.passwordRequired;
    if (trimmed.length < minPasswordLength) {
      return ValidationError.passwordTooShort;
    }
    return null;
  }

  static ValidationError? displayName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return ValidationError.displayNameRequired;
    return null;
  }

  static ValidationError? confirmPassword(
    String? password,
    String? confirmation,
  ) {
    if (password != confirmation) return ValidationError.passwordsDoNotMatch;
    return null;
  }

  static const int maxTitleLength = 120;

  static ValidationError? title(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return ValidationError.titleRequired;
    if (trimmed.length > maxTitleLength) return ValidationError.titleTooLong;
    return null;
  }

  static ValidationError? dateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null && end.isBefore(start)) {
      return ValidationError.endDateBeforeStartDate;
    }
    return null;
  }
}
