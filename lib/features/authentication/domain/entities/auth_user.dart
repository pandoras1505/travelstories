import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// The identity of the currently authenticated user, as known by the auth
/// provider. Distinct from the richer `UserProfile` Firestore document
/// (built in the Profile feature) — this is only what Firebase Auth itself
/// hands back.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) = _AuthUser;
}
