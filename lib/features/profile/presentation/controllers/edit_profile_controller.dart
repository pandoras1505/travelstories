import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class EditProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveDisplayName(String displayName) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(updateDisplayNameUseCaseProvider).call(uid: uid, displayName: displayName);
    });
  }

  Future<void> uploadAvatar({required List<int> fileBytes, required String fileExtension}) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(uploadAvatarUseCaseProvider)
          .call(uid: uid, fileBytes: fileBytes, fileExtension: fileExtension);
    });
  }
}

final editProfileControllerProvider = AsyncNotifierProvider<EditProfileController, void>(
  EditProfileController.new,
);
