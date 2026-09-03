import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/core/errors/app_exception.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/experiences/presentation/providers/experience_providers.dart';
import 'package:travelstories/features/experiences/presentation/screens/create_experience_screen.dart';
import 'package:travelstories/features/location/presentation/providers/location_providers.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_experience_repository.dart';
import '../../fakes/fake_location_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  Future<FakeLocationRepository> pumpCreateExperienceScreen(
    WidgetTester tester,
  ) async {
    final location = FakeLocationRepository();
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
          locationRepositoryProvider.overrideWithValue(location),
        ],
        child: const TravelStoriesApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Road trip');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(CreateExperienceScreen), findsOneWidget);

    return location;
  }

  testWidgets(
    '"use my location" fills the location field from the reverse-geocoded '
    'name',
    (tester) async {
      final location = await pumpCreateExperienceScreen(tester);
      location.placeNameToReturn = 'Kpalimé, Togo';

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      expect(find.text('Kpalimé, Togo'), findsOneWidget);
    },
  );

  testWidgets(
    '"use my location" shows the mapped error and leaves the field empty '
    'when permission is denied',
    (tester) async {
      final location = await pumpCreateExperienceScreen(tester);
      location.nextError = const LocationException(
        'denied',
        code: 'permission-denied',
      );

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Kpalimé, Togo'), findsNothing);
      expect(find.text('Lomé, Togo'), findsNothing);
    },
  );
}
