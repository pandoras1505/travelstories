import '../repositories/profile_repository.dart';

class EnsureUserProfileUseCase {
  const EnsureUserProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call({
    required String uid,
    required String displayName,
    String? photoUrl,
  }) {
    return _repository.ensureProfileExists(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
