import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/authentication/presentation/screens/login_screen.dart';
import 'package:travelstories/features/authentication/presentation/screens/splash_screen.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_profile_repository.dart';
import 'fakes/fake_travel_book_repository.dart';

void main() {
  testWidgets(
    'signed out: boots on the splash screen then redirects to login',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: const TravelStoriesApp(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets('signed in: boots straight into the shell with all five tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              initialUser: const AuthUser(
                uid: 'u1',
                email: 'traveler@example.com',
              ),
            ),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          travelBookRepositoryProvider.overrideWithValue(
            FakeTravelBookRepository(),
          ),
        ],
        child: const TravelStoriesApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}
