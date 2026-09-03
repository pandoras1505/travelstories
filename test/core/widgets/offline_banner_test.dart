import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/connectivity/connectivity_providers.dart';
import 'package:travelstories/core/localization/generated/app_localizations.dart';
import 'package:travelstories/core/widgets/offline_banner.dart';

import '../../fakes/fake_connectivity_service.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester,
    FakeConnectivityService connectivity,
  ) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivity),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: OfflineBanner()),
        ),
      ),
    );
  }

  testWidgets('hidden while online', (tester) async {
    await pumpBanner(tester, FakeConnectivityService());
    await tester.pump();

    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
  });

  testWidgets('shows offline persistently, then a timed back-online banner', (
    tester,
  ) async {
    final connectivity = FakeConnectivityService(initiallyOnline: true);
    await pumpBanner(tester, connectivity);
    await tester.pump();

    connectivity.setOnline(false);
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    // Stays visible while offline — no auto-dismiss.
    await tester.pump(const Duration(seconds: 5));
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    connectivity.setOnline(true);
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);

    // Auto-dismisses a few seconds after reconnecting.
    await tester.pump(const Duration(seconds: 4));
    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
  });
}
