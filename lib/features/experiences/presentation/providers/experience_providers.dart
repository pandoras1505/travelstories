import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/experience_firestore_data_source.dart';
import '../../data/repositories/experience_repository_impl.dart';
import '../../domain/entities/experience.dart';
import '../../domain/repositories/experience_repository.dart';
import '../../domain/usecases/create_experience_usecase.dart';
import '../../domain/usecases/delete_experience_usecase.dart';
import '../../domain/usecases/update_experience_usecase.dart';

final experienceRepositoryProvider = Provider<ExperienceRepository>((ref) {
  return ExperienceRepositoryImpl(
    dataSource: ExperienceFirestoreDataSource(
      firestore: FirebaseFirestore.instance,
    ),
  );
});

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
