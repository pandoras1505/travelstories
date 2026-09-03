import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/authentication/presentation/screens/register_screen.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  Future<FakeAuthRepository> pumpRegisterScreen(WidgetTester tester) async {
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

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    return auth;
  }

  Future<void> fillForm(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Amina');
    await tester.enterText(fields.at(1), 'amina@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
  }

  testWidgets('email already in use shows an error and stays on the form', (
    tester,
  ) async {
    final auth = await pumpRegisterScreen(tester);
    auth.nextError = const AuthException(
      'in use',
      code: 'email-already-in-use',
    );

    await fillForm(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('a valid form registers and lands in the app shell', (
    tester,
  ) async {
    await pumpRegisterScreen(tester);

    await fillForm(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
