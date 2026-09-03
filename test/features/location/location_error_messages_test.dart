import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/core/localization/generated/app_localizations.dart';
import 'package:travelstories/features/location/presentation/location_error_messages.dart';

void main() {
  testWidgets('maps every known LocationException code to its dedicated '
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
    String messageFor(String? code) => locationErrorMessage(
      capturedContext,
      LocationException('boom', code: code),
    );

    expect(messageFor('service-disabled'), l10n.locationErrorServiceDisabled);
    expect(messageFor('permission-denied'), l10n.locationErrorPermissionDenied);
    expect(
      messageFor('permission-denied-forever'),
      l10n.locationErrorPermissionDeniedForever,
    );
    expect(messageFor('some-unmapped-code'), l10n.locationErrorUnknown);
    expect(messageFor(null), l10n.locationErrorUnknown);
  });
}
