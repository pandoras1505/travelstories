import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/authentication/presentation/screens/login_screen.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  Future<FakeAuthRepository> pumpSignedOutApp(WidgetTester tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
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
    return auth;
  }

  testWidgets('wrong credentials show an error and stay on the login screen', (
    tester,
  ) async {
    final auth = await pumpSignedOutApp(tester);
    auth.nextError = const AuthException(
      'bad credentials',
      code: 'invalid-credential',
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'traveler@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('correct credentials sign in and land in the app shell', (
    tester,
  ) async {
    await pumpSignedOutApp(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'traveler@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'correctpass');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
