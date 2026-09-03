import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailUseCase {
  const RegisterWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String email, required String password, required String displayName}) {
    return _repository.registerWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
