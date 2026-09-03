import 'dart:async';

import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository] for widget/unit tests — no Firebase SDK
/// involved. Call [setUser] to simulate a sign-in/sign-out from a test.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _user = initialUser;

  AuthUser? _user;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  void setUser(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({required String email, required String password}) async {
    final user = AuthUser(uid: 'fake-uid', email: email);
    setUser(user);
    return user;
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = AuthUser(uid: 'fake-uid', email: email, displayName: displayName);
    setUser(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    const user = AuthUser(uid: 'fake-google-uid', email: 'fake@gmail.com');
    setUser(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {
    setUser(null);
  }
}
