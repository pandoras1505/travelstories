import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/app/router/app_router.dart';
import 'package:travelstories/app/router/route_paths.dart';
import 'package:travelstories/features/authentication/presentation/screens/login_screen.dart';
import 'package:travelstories/features/authentication/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('boots on the splash screen then redirects to login', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TravelStoriesApp()));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'the authenticated shell exposes all five bottom navigation tabs',
    (tester) async {
      appRouter.go(RoutePaths.home);
      await tester.pumpWidget(const ProviderScope(child: TravelStoriesApp()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    },
  );
}
