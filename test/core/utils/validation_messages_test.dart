import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/localization/generated/app_localizations.dart';
import 'package:travelstories/core/utils/validation_messages.dart';
import 'package:travelstories/core/utils/validators.dart';

void main() {
  testWidgets('maps every ValidationError to its dedicated message, and '
      'null to no message', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final l10n = AppLocalizations.of(capturedContext)!;
    String? messageFor(ValidationError? error) =>
        validationErrorMessage(capturedContext, error);

    expect(messageFor(null), isNull);
    expect(
      messageFor(ValidationError.emailRequired),
      l10n.validationEmailRequired,
    );
    expect(
      messageFor(ValidationError.emailInvalid),
      l10n.validationEmailInvalid,
    );
    expect(
      messageFor(ValidationError.passwordRequired),
      l10n.validationPasswordRequired,
    );
    expect(
      messageFor(ValidationError.passwordTooShort),
      l10n.validationPasswordTooShort,
    );
    expect(
      messageFor(ValidationError.displayNameRequired),
      l10n.validationDisplayNameRequired,
    );
    expect(
      messageFor(ValidationError.passwordsDoNotMatch),
      l10n.validationPasswordsDoNotMatch,
    );
    expect(
      messageFor(ValidationError.titleRequired),
      l10n.validationTitleRequired,
    );
    expect(
      messageFor(ValidationError.titleTooLong),
      l10n.validationTitleTooLong,
    );
    expect(
      messageFor(ValidationError.endDateBeforeStartDate),
      l10n.validationEndDateBeforeStartDate,
    );
  });
}
