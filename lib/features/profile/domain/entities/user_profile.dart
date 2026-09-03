import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// The `users/{uid}` Firestore document. Auto-created the first time a user
/// signs in (see `EnsureUserProfileUseCase`) — every authenticated user has
/// exactly one of these.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String displayName,
    required String email,
    String? photoUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;
}
