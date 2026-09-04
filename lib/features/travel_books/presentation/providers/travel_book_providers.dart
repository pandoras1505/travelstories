import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../experiences/data/datasources/experience_local_data_source.dart';
import '../../data/datasources/cover_storage_data_source.dart';
import '../../data/datasources/travel_book_firestore_data_source.dart';
import '../../data/datasources/travel_book_local_data_source.dart';
import '../../data/repositories/travel_book_repository_impl.dart';
import '../../domain/entities/travel_book.dart';
import '../../domain/repositories/travel_book_repository.dart';
import '../../domain/usecases/create_travel_book_usecase.dart';
import '../../domain/usecases/delete_travel_book_usecase.dart';
import '../../domain/usecases/publish_travel_book_usecase.dart';
import '../../domain/usecases/unpublish_travel_book_usecase.dart';
import '../../domain/usecases/update_travel_book_usecase.dart';
import '../../domain/usecases/upload_cover_usecase.dart';

/// Reads `appDatabaseProvider` synchronously via `.requireValue` — safe
/// because `main()` awaits `openAppDatabase()` and overrides
/// `appDatabaseProvider` with the already-resolved value before `runApp`
/// (same pattern as awaiting `Firebase.initializeApp()` first). Tests never
/// hit this: they override `travelBookRepositoryProvider` directly with a
/// fake, so this body — and its dependency on `appDatabaseProvider` — never
/// runs.
final travelBookRepositoryProvider = Provider<TravelBookRepository>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return TravelBookRepositoryImpl(
    firestoreDataSource: TravelBookFirestoreDataSource(
      firestore: FirebaseFirestore.instance,
    ),
    storageDataSource: const CoverStorageDataSource(),
    localDataSource: TravelBookLocalDataSource(database: database),
    experienceLocalDataSource: ExperienceLocalDataSource(database: database),
    syncEngine: ref.watch(syncEngineProvider),
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
