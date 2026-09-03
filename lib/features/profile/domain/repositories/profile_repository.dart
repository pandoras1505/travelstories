import '../entities/user_profile.dart';

abstract class ProfileRepository {
  /// Live updates for one user's profile (`null` if the document doesn't
  /// exist yet or was deleted).
  Stream<UserProfile?> watchProfile(String uid);

  Future<UserProfile?> getProfile(String uid);

  /// Creates the profile document if (and only if) it doesn't already
  /// exist. Safe to call on every sign-in.
  Future<void> ensureProfileExists({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
  });

  Future<void> updateDisplayName({required String uid, required String displayName});

  /// Uploads [fileBytes] to `users/{uid}/profile/` and updates the
  /// profile's `photoUrl` to the resulting download URL, returning it.
  Future<String> uploadAvatar({required String uid, required List<int> fileBytes, required String fileExtension});
}
