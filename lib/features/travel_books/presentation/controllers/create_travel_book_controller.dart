import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/travel_book_providers.dart';

class CreateTravelBookController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns the new travel book's id on success, or `null` if the user
  /// wasn't signed in (shouldn't happen — this screen lives behind the
  /// router's auth guard) or the create call failed (check [state] for the
  /// error).
  Future<String?> create({
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required bool isPublic,
  }) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return null;

    state = const AsyncLoading();
    String? newId;
    state = await AsyncValue.guard(() async {
      newId = await ref
          .read(createTravelBookUseCaseProvider)
          .call(
            ownerId: uid,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            isPublic: isPublic,
          );
    });
    return newId;
  }
}

final createTravelBookControllerProvider =
    AsyncNotifierProvider<CreateTravelBookController, void>(
      CreateTravelBookController.new,
    );
