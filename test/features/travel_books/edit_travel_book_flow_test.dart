import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/experiences/presentation/providers/experience_providers.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';
import 'package:travelstories/features/travel_books/presentation/screens/edit_travel_book_screen.dart';
import 'package:travelstories/features/travel_books/presentation/screens/travel_book_detail_screen.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_experience_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  testWidgets('edit, publish/unpublish, then delete a travel book', (
    tester,
  ) async {
    // EditTravelBookScreen's cover-image placeholder pushes the save/
    // publish buttons below the default 600-tall test viewport, where a
    // tap silently misses instead of activating them.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // Create a draft via the Create tab.
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Road trip');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(TravelBookDetailScreen), findsOneWidget);

    // Open the edit screen and change the title.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(EditTravelBookScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Road trip v2');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    // Starts as a draft.
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Back to draft'), findsNothing);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(find.text('Back to draft'), findsOneWidget);

    await tester.tap(find.text('Back to draft'));
    await tester.pumpAndSettle();
    expect(find.text('Publish'), findsOneWidget);

    // Delete requires confirmation.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this travel book?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(EditTravelBookScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Deleting pops back to the detail route, which then shows its
    // "not found" empty state once the book vanishes from the stream —
    // it doesn't auto-navigate further back on its own.
    expect(find.byType(EditTravelBookScreen), findsNothing);
    expect(find.byType(TravelBookDetailScreen), findsOneWidget);
    expect(find.text('Road trip v2'), findsNothing);
  });
}
