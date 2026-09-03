import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/experience.dart';
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

  Future<void> addPhoto({
    required String travelBookId,
    required String id,
    required ImageSource source,
  }) async {
    final mediaService = ref.read(mediaServiceProvider);
    final file = source == ImageSource.camera
        ? await mediaService.captureImage()
        : await mediaService.pickImage();
    if (file == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final processed = await ref
          .read(mediaProcessorProvider)
          .processImage(file);
      await ref
          .read(uploadExperienceMediaUseCaseProvider)
          .call(
            travelBookId: travelBookId,
            id: id,
            mediaType: ExperienceMediaType.image,
            bytes: processed.bytes,
            extension: processed.extension,
          );
    });
  }

  Future<void> addVideo({
    required String travelBookId,
    required String id,
    required ImageSource source,
  }) async {
    final mediaService = ref.read(mediaServiceProvider);
    final file = source == ImageSource.camera
        ? await mediaService.captureVideo()
        : await mediaService.pickVideo();
    if (file == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final processed = await ref
          .read(mediaProcessorProvider)
          .processVideo(file);
      await ref
          .read(uploadExperienceMediaUseCaseProvider)
          .call(
            travelBookId: travelBookId,
            id: id,
            mediaType: ExperienceMediaType.video,
            bytes: processed.bytes,
            extension: processed.extension,
            thumbnailBytes: processed.thumbnailBytes,
          );
    });
  }

  Future<void> removeMedia({
    required String travelBookId,
    required String id,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(removeExperienceMediaUseCaseProvider)
          .call(travelBookId: travelBookId, id: id);
    });
  }
}

final editExperienceControllerProvider =
    AsyncNotifierProvider<EditExperienceController, void>(
      EditExperienceController.new,
    );
