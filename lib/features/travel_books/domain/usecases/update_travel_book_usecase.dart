import '../repositories/travel_book_repository.dart';

class UpdateTravelBookUseCase {
  const UpdateTravelBookUseCase(this._repository);

  final TravelBookRepository _repository;

  Future<void> call({
    required String id,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.updateTravelBook(
      id: id,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
