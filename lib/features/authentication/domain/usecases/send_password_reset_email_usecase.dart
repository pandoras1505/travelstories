import '../repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) => _repository.sendPasswordResetEmail(email: email);
}
