import '../repositories/profile_repository.dart';

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final ProfileRepository _repository;

  Future<String> call({required String uid, required List<int> fileBytes, required String fileExtension}) {
    return _repository.uploadAvatar(uid: uid, fileBytes: fileBytes, fileExtension: fileExtension);
  }
}
