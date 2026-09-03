import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/authentication/presentation/screens/forgot_password_screen.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  Future<FakeAuthRepository> pumpForgotPasswordScreen(
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const TravelStoriesApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);

    return auth;
  }

  testWidgets('a failed send shows an error and keeps the form visible', (
    tester,
  ) async {
    final auth = await pumpForgotPasswordScreen(tester);
    auth.nextError = const AuthException('nope', code: 'user-not-found');

    await tester.enterText(find.byType(TextFormField), 'traveler@example.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('a successful send replaces the form with a confirmation', (
    tester,
  ) async {
    await pumpForgotPasswordScreen(tester);

    await tester.enterText(find.byType(TextFormField), 'traveler@example.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Email sent. Check your inbox.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
