import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/experience_providers.dart';

class CreateExperienceController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns the new experience's id on success, or `null` if the user
  /// wasn't signed in or the create call failed (check [state]).
  Future<String?> create({
    required String travelBookId,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return null;

    state = const AsyncLoading();
    String? newId;
    state = await AsyncValue.guard(() async {
      newId = await ref
          .read(createExperienceUseCaseProvider)
          .call(
            travelBookId: travelBookId,
            ownerId: uid,
            title: title,
            description: description,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
          );
    });
    return newId;
  }
}

final createExperienceControllerProvider =
    AsyncNotifierProvider<CreateExperienceController, void>(
      CreateExperienceController.new,
    );
