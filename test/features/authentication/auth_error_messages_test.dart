import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/core/localization/generated/app_localizations.dart';
import 'package:travelstories/features/authentication/presentation/auth_error_messages.dart';

void main() {
  testWidgets('maps every known AuthException code to its dedicated '
      'message, and anything else to the generic one', (tester) async {
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
    String messageFor(String? code) =>
        authErrorMessage(capturedContext, AuthException('boom', code: code));

    expect(messageFor('invalid-email'), l10n.authErrorInvalidEmail);
    expect(messageFor('invalid-credential'), l10n.authErrorInvalidCredential);
    expect(messageFor('wrong-password'), l10n.authErrorInvalidCredential);
    expect(messageFor('user-not-found'), l10n.authErrorInvalidCredential);
    expect(messageFor('user-disabled'), l10n.authErrorUserDisabled);
    expect(messageFor('email-already-in-use'), l10n.authErrorEmailInUse);
    expect(messageFor('weak-password'), l10n.authErrorWeakPassword);
    expect(messageFor('too-many-requests'), l10n.authErrorTooManyRequests);
    expect(messageFor('network-request-failed'), l10n.authErrorNetwork);
    expect(
      messageFor('google-sign-in-failed'),
      l10n.authErrorGoogleSignInFailed,
    );
    expect(messageFor('some-unmapped-code'), l10n.authErrorUnknown);
    expect(messageFor(null), l10n.authErrorUnknown);
  });
}
