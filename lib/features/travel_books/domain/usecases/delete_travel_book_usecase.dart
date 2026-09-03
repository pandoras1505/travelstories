import '../repositories/travel_book_repository.dart';

class DeleteTravelBookUseCase {
  const DeleteTravelBookUseCase(this._repository);

  final TravelBookRepository _repository;

  Future<void> call(String id) => _repository.deleteTravelBook(id);
}
