import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// The `users/{uid}` Firestore document. Auto-created the first time a user
/// signs in (see `EnsureUserProfileUseCase`) — every authenticated user has
/// exactly one of these.
///
/// Deliberately has no `email` field: this document is readable by any
/// signed-in user (the public feed/explore cards join in the author's
/// displayName/photoUrl — see `PublicTravelBookCard`), so it must never
/// carry anything sensitive. The current user's own email is available
/// from `AuthUser` (the Auth SDK already has it) without needing to
/// duplicate it here. Security-audit finding, Phase 13.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String displayName,
    String? photoUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;
}
