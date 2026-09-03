import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/app/app.dart';
import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/presentation/providers/auth_providers.dart';
import 'package:travelstories/features/profile/presentation/providers/profile_providers.dart';
import 'package:travelstories/features/travel_books/presentation/providers/travel_book_providers.dart';
import 'package:travelstories/features/travel_books/presentation/widgets/public_travel_book_card.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';
import '../../fakes/fake_travel_book_repository.dart';

void main() {
  testWidgets('explore searches public books by title prefix', (tester) async {
    // A tall surface so every card in these short lists is actually built
    // by the lazy ListView/CustomScrollView, instead of only whatever
    // happens to fit the default 600-tall test viewport.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final travelBooks = FakeTravelBookRepository();
    final profiles = FakeProfileRepository();
    await profiles.ensureProfileExists(uid: 'owner-1', displayName: 'Amina');

    await travelBooks.createTravelBook(
      ownerId: 'owner-1',
      title: 'Alpine Adventure',
      description: '',
      isPublic: true,
    );
    await travelBooks.createTravelBook(
      ownerId: 'owner-1',
      title: 'Amazon Basin',
      description: '',
      isPublic: true,
    );
    await travelBooks.createTravelBook(
      ownerId: 'owner-1',
      title: 'Bali Sunsets',
      description: '',
      isPublic: true,
    );

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

    await tester.tap(find.byIcon(Icons.travel_explore_outlined));
    await tester.pumpAndSettle();

    // No filter yet: all three public books are listed.
    expect(find.byType(PublicTravelBookCard), findsNWidgets(3));
    expect(find.text('Alpine Adventure'), findsOneWidget);
    expect(find.text('Amazon Basin'), findsOneWidget);
    expect(find.text('Bali Sunsets'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Al');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Alpine Adventure'), findsOneWidget);
    expect(find.text('Amazon Basin'), findsNothing);
    expect(find.text('Bali Sunsets'), findsNothing);

    // Widening the prefix brings the other "A" title back.
    await tester.enterText(find.byType(TextField), 'A');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Alpine Adventure'), findsOneWidget);
    expect(find.text('Amazon Basin'), findsOneWidget);
    expect(find.text('Bali Sunsets'), findsNothing);

    // Clearing the search and switching sort doesn't crash and still
    // renders every public book.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).at(2)); // Alphabetical / A-Z
    await tester.pumpAndSettle();

    expect(find.text('Alpine Adventure'), findsOneWidget);
    expect(find.text('Amazon Basin'), findsOneWidget);
    expect(find.text('Bali Sunsets'), findsOneWidget);
  });
}
