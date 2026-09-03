import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/experiences/presentation/providers/experience_providers.dart';
import 'package:travelstories/features/experiences/presentation/screens/create_experience_screen.dart';
import 'package:travelstories/features/experiences/presentation/screens/edit_experience_screen.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_experience_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  testWidgets(
    'adds an experience to a travel book, edits it, then deletes it',
    (tester) async {
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
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
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

      // Create a travel book to land on its detail screen.
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Road trip au Togo',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Add an experience via the FAB.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(CreateExperienceScreen), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Cascade de Womé',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Back on the detail screen, the new experience shows in the timeline.
      expect(find.byType(CreateExperienceScreen), findsNothing);
      expect(find.text('Cascade de Womé'), findsOneWidget);

      // Tap it to edit.
      await tester.tap(find.text('Cascade de Womé'));
      await tester.pumpAndSettle();
      expect(find.byType(EditExperienceScreen), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Cascade de Womé (rénovée)',
      );
      // The media section pushes the save button below the fold on the
      // test surface — scroll it into view before tapping.
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Cascade de Womé (rénovée)'), findsOneWidget);

      // Delete it.
      await tester.tap(find.text('Cascade de Womé (rénovée)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      // Confirm dialog: the last TextButton is the destructive "delete" action.
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(find.byType(EditExperienceScreen), findsNothing);
      expect(find.text('Cascade de Womé (rénovée)'), findsNothing);
    },
  );
}
