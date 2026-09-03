import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns whether the email was sent — the screen shows its own
  /// confirmation on `true` rather than inferring success from a
  /// loading-to-data state transition, which would also (wrongly) match
  /// this controller's own initial `build()` resolving.
  Future<bool> sendResetLink({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(sendPasswordResetEmailUseCaseProvider).call(email: email);
    });
    return !state.hasError;
  }
}

final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, void>(
      ForgotPasswordController.new,
    );
