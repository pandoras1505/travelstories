import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../providers/auth_providers.dart';

/// Drives [LoginScreen]. `state` is [AsyncLoading] while a sign-in attempt
/// is in flight and [AsyncError] holding an [AuthException] on failure —
/// screens map the exception's `code` to a localized message.
class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(signInWithEmailUseCaseProvider)
          .call(email: email, password: password);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(signInWithGoogleUseCaseProvider).call();
      state = const AsyncData(null);
    } on AuthException catch (e) {
      if (e.code == 'google-sign-in-cancelled') {
        state = const AsyncData(null);
      } else {
        state = AsyncError(e, StackTrace.current);
      }
    }
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
