import '../repositories/travel_book_repository.dart';

class CreateTravelBookUseCase {
  const CreateTravelBookUseCase(this._repository);

  final TravelBookRepository _repository;

  Future<String> call({
    required String ownerId,
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required bool isPublic,
  }) {
    return _repository.createTravelBook(
      ownerId: ownerId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isPublic: isPublic,
    );
  }
}
