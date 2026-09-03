import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/cover_storage_data_source.dart';
import '../../data/datasources/travel_book_firestore_data_source.dart';
import '../../data/repositories/travel_book_repository_impl.dart';
import '../../domain/entities/travel_book.dart';
import '../../domain/repositories/travel_book_repository.dart';
import '../../domain/usecases/create_travel_book_usecase.dart';
import '../../domain/usecases/delete_travel_book_usecase.dart';
import '../../domain/usecases/publish_travel_book_usecase.dart';
import '../../domain/usecases/unpublish_travel_book_usecase.dart';
import '../../domain/usecases/update_travel_book_usecase.dart';
import '../../domain/usecases/upload_cover_usecase.dart';

final travelBookRepositoryProvider = Provider<TravelBookRepository>((ref) {
  return TravelBookRepositoryImpl(
    firestoreDataSource: TravelBookFirestoreDataSource(
      firestore: FirebaseFirestore.instance,
    ),
    storageDataSource: CoverStorageDataSource(
      storage: FirebaseStorage.instance,
    ),
  );
});

/// The signed-in user's own travel books (drafts + published). Empty while
/// signed out.
final myTravelBooksProvider = StreamProvider<List<TravelBook>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return Stream.value(const []);
  return ref
      .watch(travelBookRepositoryProvider)
      .watchMyTravelBooks(authUser.uid);
});

final travelBookProvider = StreamProvider.family<TravelBook?, String>((
  ref,
  id,
) {
  return ref.watch(travelBookRepositoryProvider).watchTravelBook(id);
});

final createTravelBookUseCaseProvider = Provider<CreateTravelBookUseCase>((
  ref,
) {
  return CreateTravelBookUseCase(ref.watch(travelBookRepositoryProvider));
});

final updateTravelBookUseCaseProvider = Provider<UpdateTravelBookUseCase>((
  ref,
) {
  return UpdateTravelBookUseCase(ref.watch(travelBookRepositoryProvider));
});

final publishTravelBookUseCaseProvider = Provider<PublishTravelBookUseCase>((
  ref,
) {
  return PublishTravelBookUseCase(ref.watch(travelBookRepositoryProvider));
});

final unpublishTravelBookUseCaseProvider = Provider<UnpublishTravelBookUseCase>(
  (ref) {
    return UnpublishTravelBookUseCase(ref.watch(travelBookRepositoryProvider));
  },
);

final deleteTravelBookUseCaseProvider = Provider<DeleteTravelBookUseCase>((
  ref,
) {
  return DeleteTravelBookUseCase(ref.watch(travelBookRepositoryProvider));
});

final uploadCoverUseCaseProvider = Provider<UploadCoverUseCase>((ref) {
  return UploadCoverUseCase(ref.watch(travelBookRepositoryProvider));
});
