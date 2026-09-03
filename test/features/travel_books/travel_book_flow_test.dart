import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/experiences/presentation/providers/experience_providers.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';
import 'package:travelstories/features/travel_books/presentation/screens/travel_book_detail_screen.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_experience_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  testWidgets('creates a travel book and finds it in the list', (tester) async {
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
          experienceRepositoryProvider.overrideWithValue(
            FakeExperienceRepository(),
          ),
        ],
        child: const TravelStoriesApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Home tab -> Create tab.
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Road trip au Togo',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Creating navigates straight to the new book's detail screen.
    expect(find.byType(TravelBookDetailScreen), findsOneWidget);
    expect(find.text('Road trip au Togo'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // My Travel Books tab shows the new draft.
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Road trip au Togo'), findsOneWidget);
  });
}
