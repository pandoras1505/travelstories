import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/avatar_storage_data_source.dart';
import '../../data/datasources/profile_firestore_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/ensure_user_profile_usecase.dart';
import '../../domain/usecases/update_display_name_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    firestoreDataSource: ProfileFirestoreDataSource(
      firestore: FirebaseFirestore.instance,
    ),
    storageDataSource: const AvatarStorageDataSource(),
  );
});

/// The signed-in user's profile document, live. `null` while signed out or
/// before the profile document has been created.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(authUser.uid);
});

/// One-off lookup of another user's profile — used to render the author of
/// a public travel book on Home/Explore cards.
final authorProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(profileRepositoryProvider).getProfile(uid);
});

final ensureUserProfileUseCaseProvider = Provider<EnsureUserProfileUseCase>((
  ref,
) {
  return EnsureUserProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateDisplayNameUseCaseProvider = Provider<UpdateDisplayNameUseCase>((
  ref,
) {
  return UpdateDisplayNameUseCase(ref.watch(profileRepositoryProvider));
});

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(profileRepositoryProvider));
});
