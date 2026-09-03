import '../repositories/travel_book_repository.dart';

class UploadCoverUseCase {
  const UploadCoverUseCase(this._repository);

  final TravelBookRepository _repository;

  Future<String> call({
    required String travelBookId,
    required List<int> fileBytes,
    required String fileExtension,
  }) {
    return _repository.uploadCover(
      travelBookId: travelBookId,
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
  }
}
