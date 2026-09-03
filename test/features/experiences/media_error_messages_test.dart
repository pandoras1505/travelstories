import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/core/localization/generated/app_localizations.dart';
import 'package:travelstories/features/experiences/presentation/media_error_messages.dart';

void main() {
  testWidgets('maps every known MediaException code to its dedicated '
      'message, null to "processing failed", and anything else to the '
      'generic one', (tester) async {
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
        mediaErrorMessage(capturedContext, MediaException('boom', code: code));

    expect(messageFor('image-too-large'), l10n.mediaErrorImageTooLarge);
    expect(messageFor('video-too-large'), l10n.mediaErrorVideoTooLarge);
    expect(messageFor(null), l10n.mediaErrorProcessingFailed);
    expect(messageFor('some-unmapped-code'), l10n.mediaErrorUnknown);
  });
}
