import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  testWidgets('shows the profile and lets the user rename it', (tester) async {
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

    // Land on the home tab; switch to the Profile tab.
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('traveler@example.com'), findsOneWidget);

    // ProfileScreen has exactly one FilledButton ("edit profile"; sign-out
    // is an OutlinedButton) — target by type/role rather than localized text.
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Amina');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Amina'), findsOneWidget);
  });
}
