import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/core/localization/generated/app_localizations.dart';
import 'package:travelstories/features/profile/presentation/profile_error_messages.dart';

void main() {
  testWidgets('maps every known StorageException code to its dedicated '
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
    String messageFor(String? code) => storageErrorMessage(
      capturedContext,
      StorageException('boom', code: code),
    );

    expect(messageFor('unauthorized'), l10n.storageErrorUnauthorized);
    expect(messageFor('unauthenticated'), l10n.storageErrorUnauthorized);
    expect(messageFor('object-not-found'), l10n.storageErrorUnavailable);
    expect(messageFor('bucket-not-found'), l10n.storageErrorUnavailable);
    expect(messageFor('project-not-found'), l10n.storageErrorUnavailable);
    expect(messageFor('some-unmapped-code'), l10n.storageErrorUnknown);
    expect(messageFor(null), l10n.storageErrorUnknown);
  });
}
