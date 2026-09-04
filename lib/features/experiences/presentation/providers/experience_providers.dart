import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../media/media_processor.dart';
import '../../../media/media_service.dart';
import '../../../travel_books/data/datasources/travel_book_local_data_source.dart';
import '../../data/datasources/experience_firestore_data_source.dart';
import '../../data/datasources/experience_local_data_source.dart';
import '../../data/datasources/experience_media_storage_data_source.dart';
import '../../data/repositories/experience_repository_impl.dart';
import '../../domain/entities/experience.dart';
import '../../domain/repositories/experience_repository.dart';
import '../../domain/usecases/create_experience_usecase.dart';
import '../../domain/usecases/delete_experience_usecase.dart';
import '../../domain/usecases/remove_experience_media_usecase.dart';
import '../../domain/usecases/update_experience_usecase.dart';
import '../../domain/usecases/upload_experience_media_usecase.dart';

/// See `travelBookRepositoryProvider` for why `.requireValue` is safe here
/// and why tests never actually run this body.
final experienceRepositoryProvider = Provider<ExperienceRepository>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return ExperienceRepositoryImpl(
    dataSource: ExperienceFirestoreDataSource(
      firestore: FirebaseFirestore.instance,
    ),
    mediaStorageDataSource: const ExperienceMediaStorageDataSource(),
    localDataSource: ExperienceLocalDataSource(database: database),
    travelBookLocalDataSource: TravelBookLocalDataSource(database: database),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());

final mediaProcessorProvider = Provider<MediaProcessor>(
  (ref) => MediaProcessor(),
);

final experiencesForBookProvider =
    StreamProvider.family<List<Experience>, String>((ref, travelBookId) {
      return ref
          .watch(experienceRepositoryProvider)
          .watchExperiences(travelBookId);
    });

typedef ExperienceKey = ({String travelBookId, String id});

final experienceProvider = StreamProvider.family<Experience?, ExperienceKey>((
  ref,
  key,
) {
  return ref
      .watch(experienceRepositoryProvider)
      .watchExperience(travelBookId: key.travelBookId, id: key.id);
});

final createExperienceUseCaseProvider = Provider<CreateExperienceUseCase>((
  ref,
) {
  return CreateExperienceUseCase(ref.watch(experienceRepositoryProvider));
});

final updateExperienceUseCaseProvider = Provider<UpdateExperienceUseCase>((
  ref,
) {
  return UpdateExperienceUseCase(ref.watch(experienceRepositoryProvider));
});

final deleteExperienceUseCaseProvider = Provider<DeleteExperienceUseCase>((
  ref,
) {
  return DeleteExperienceUseCase(ref.watch(experienceRepositoryProvider));
});

final uploadExperienceMediaUseCaseProvider =
    Provider<UploadExperienceMediaUseCase>((ref) {
      return UploadExperienceMediaUseCase(
        ref.watch(experienceRepositoryProvider),
      );
    });

final removeExperienceMediaUseCaseProvider =
    Provider<RemoveExperienceMediaUseCase>((ref) {
      return RemoveExperienceMediaUseCase(
        ref.watch(experienceRepositoryProvider),
      );
    });
