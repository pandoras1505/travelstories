import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  testWidgets(
    'home feed shows public books (featured + latest) and hides drafts',
    (tester) async {
      // A tall surface so the list item below the featured card is
      // actually built by the lazy sliver list, instead of only whatever
      // happens to fit the default 600-tall test viewport.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final travelBooks = FakeTravelBookRepository();
      final profiles = FakeProfileRepository();

      await profiles.ensureProfileExists(uid: 'owner-1', displayName: 'Amina');
      await profiles.ensureProfileExists(uid: 'owner-2', displayName: 'Kenji');

      // Created in this order (oldest first); FakeTravelBookRepository
      // offsets each createdAt by insertion order, so "recent" sort doesn't
      // depend on real wall-clock gaps between calls — never
      // `await Future.delayed(...)` here, it deadlocks under flutter_test's
      // fake clock, which only advances via `tester.pump`.
      final saharaId = await travelBooks.createTravelBook(
        ownerId: 'owner-1',
        title: 'Sahara Trek',
        description: '',
        isPublic: true,
      );
      await travelBooks.createTravelBook(
        ownerId: 'owner-1',
        title: 'Secret Diary',
        description: '',
        isPublic: false,
      );
      final tokyoId = await travelBooks.createTravelBook(
        ownerId: 'owner-2',
        title: 'Tokyo Nights',
        description: '',
        isPublic: true,
      );
      // Sanity check the fixture is wired the way the assertions expect.
      expect(saharaId, isNotEmpty);
      expect(tokyoId, isNotEmpty);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                initialUser: const AuthUser(
                  uid: 'owner-1',
                  email: 'amina@example.com',
                ),
              ),
            ),
            profileRepositoryProvider.overrideWithValue(profiles),
            travelBookRepositoryProvider.overrideWithValue(travelBooks),
          ],
          child: const TravelStoriesApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // "Tokyo Nights" is the most recently created public book: featured.
      expect(find.text('Tokyo Nights'), findsOneWidget);

      // "Sahara Trek" is public too: shown in the latest-books list.
      expect(find.text('Sahara Trek'), findsOneWidget);
      // The draft must never appear on the public feed.
      expect(find.text('Secret Diary'), findsNothing);
      // Author join renders for the list card (Sahara Trek's owner).
      expect(find.textContaining('Amina'), findsOneWidget);
    },
  );
}
