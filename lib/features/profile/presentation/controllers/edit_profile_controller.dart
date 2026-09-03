import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class EditProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns whether the save succeeded — the screen shows its own "saved"
  /// confirmation on `true` rather than inferring success from a
  /// loading-to-data state transition, which would also (wrongly) match
  /// this controller's own initial `build()` resolving.
  Future<bool> saveDisplayName(String displayName) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(updateDisplayNameUseCaseProvider)
          .call(uid: uid, displayName: displayName);
    });
    return !state.hasError;
  }

  /// Same "return success" contract as [saveDisplayName].
  Future<bool> uploadAvatar({
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(uploadAvatarUseCaseProvider)
          .call(uid: uid, fileBytes: fileBytes, fileExtension: fileExtension);
    });
    return !state.hasError;
  }
}

final editProfileControllerProvider =
    AsyncNotifierProvider<EditProfileController, void>(
      EditProfileController.new,
    );
