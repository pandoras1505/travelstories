import '../repositories/travel_book_repository.dart';

class UnpublishTravelBookUseCase {
  const UnpublishTravelBookUseCase(this._repository);

  final TravelBookRepository _repository;

  Future<void> call(String id) => _repository.unpublishTravelBook(id);
}
