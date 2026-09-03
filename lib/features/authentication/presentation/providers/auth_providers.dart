import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository_instance.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/register_with_email_usecase.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => authRepository,
);

/// The current auth state, updated live. Watched by the router redirect
/// (via the shared repository stream — see app_router.dart) and by widgets
/// that need to react to sign-in/sign-out (e.g. Profile).
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final registerWithEmailUseCaseProvider = Provider<RegisterWithEmailUseCase>((
  ref,
) {
  return RegisterWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((
  ref,
) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase>((ref) {
      return SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider));
    });

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});
