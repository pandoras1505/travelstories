import '../repositories/travel_book_repository.dart';

class PublishTravelBookUseCase {
  const PublishTravelBookUseCase(this._repository);

  final TravelBookRepository _repository;

  Future<void> call(String id) => _repository.publishTravelBook(id);
}
