import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendResetLink({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(sendPasswordResetEmailUseCaseProvider).call(email: email);
    });
  }
}

final forgotPasswordControllerProvider = AsyncNotifierProvider<ForgotPasswordController, void>(
  ForgotPasswordController.new,
);
