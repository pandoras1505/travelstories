import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String email, required String password}) {
    return _repository.signInWithEmailAndPassword(email: email, password: password);
  }
}
