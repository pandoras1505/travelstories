import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/travel_book_providers.dart';

class EditTravelBookController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveChanges({
    required String id,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(updateTravelBookUseCaseProvider)
          .call(
            id: id,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
          );
    });
  }

  Future<void> togglePublish({
    required String id,
    required bool currentlyPublic,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return currentlyPublic
          ? ref.read(unpublishTravelBookUseCaseProvider).call(id)
          : ref.read(publishTravelBookUseCaseProvider).call(id);
    });
  }

  Future<void> uploadCover({
    required String id,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(uploadCoverUseCaseProvider)
          .call(
            travelBookId: id,
            fileBytes: fileBytes,
            fileExtension: fileExtension,
          );
    });
  }

  /// Returns `true` on success.
  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(deleteTravelBookUseCaseProvider).call(id),
    );
    state = result;
    return result.hasError == false;
  }
}

final editTravelBookControllerProvider =
    AsyncNotifierProvider<EditTravelBookController, void>(
      EditTravelBookController.new,
    );
