import 'dart:async';

import 'package:travelstories/features/profile/domain/entities/user_profile.dart';
import 'package:travelstories/features/profile/domain/repositories/profile_repository.dart';

/// In-memory [ProfileRepository] for widget/unit tests — no Firestore/
/// Storage SDK involved.
class FakeProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> _profiles = {};
  final _controllers = <String, StreamController<UserProfile?>>{};

  StreamController<UserProfile?> _controllerFor(String uid) {
    return _controllers.putIfAbsent(uid, () => StreamController<UserProfile?>.broadcast());
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _profiles[uid];
    yield* _controllerFor(uid).stream;
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => _profiles[uid];

  @override
  Future<void> ensureProfileExists({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    if (_profiles.containsKey(uid)) return;
    final now = DateTime.now();
    final profile = UserProfile(
      id: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      createdAt: now,
      updatedAt: now,
    );
    _profiles[uid] = profile;
    _controllerFor(uid).add(profile);
  }

  @override
  Future<void> updateDisplayName({required String uid, required String displayName}) async {
    final existing = _profiles[uid];
    if (existing == null) return;
    final updated = existing.copyWith(displayName: displayName, updatedAt: DateTime.now());
    _profiles[uid] = updated;
    _controllerFor(uid).add(updated);
  }

  @override
  Future<String> uploadAvatar({required String uid, required List<int> fileBytes, required String fileExtension}) async {
    const url = 'https://example.com/fake-avatar.jpg';
    final existing = _profiles[uid];
    if (existing != null) {
      final updated = existing.copyWith(photoUrl: url, updatedAt: DateTime.now());
      _profiles[uid] = updated;
      _controllerFor(uid).add(updated);
    }
    return url;
  }
}
