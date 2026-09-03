import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class RegisterController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(registerWithEmailUseCaseProvider)
          .call(email: email, password: password, displayName: displayName);
    });
  }
}

final registerControllerProvider =
    AsyncNotifierProvider<RegisterController, void>(RegisterController.new);
