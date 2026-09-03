import '../repositories/profile_repository.dart';

class UpdateDisplayNameUseCase {
  const UpdateDisplayNameUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call({required String uid, required String displayName}) {
    return _repository.updateDisplayName(uid: uid, displayName: displayName);
  }
}
