import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/experience_providers.dart';

class EditExperienceController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveChanges({
    required String travelBookId,
    required String id,
    required String title,
    required String description,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(updateExperienceUseCaseProvider)
          .call(
            travelBookId: travelBookId,
            id: id,
            title: title,
            description: description,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
          );
    });
  }

  /// Returns `true` on success.
  Future<bool> delete({
    required String travelBookId,
    required String id,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(deleteExperienceUseCaseProvider)
          .call(travelBookId: travelBookId, id: id),
    );
    state = result;
    return result.hasError == false;
  }
}

final editExperienceControllerProvider =
    AsyncNotifierProvider<EditExperienceController, void>(
      EditExperienceController.new,
    );
