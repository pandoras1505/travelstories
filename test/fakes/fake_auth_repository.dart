import 'dart:async';

import 'package:travelstories/features/authentication/domain/entities/auth_user.dart';
import 'package:travelstories/features/authentication/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository] for widget/unit tests — no Firebase SDK
/// involved. Call [setUser] to simulate a sign-in/sign-out from a test.
///
/// Set [nextError] to make the *next* mutating call (sign-in, register,
/// Google sign-in, or password reset) throw it instead of succeeding —
/// cleared automatically after that one use, so each simulated failure
/// needs its own assignment.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _user = initialUser;

  AuthUser? _user;
  final _controller = StreamController<AuthUser?>.broadcast();

  Object? nextError;

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

  void _maybeThrow() {
    final error = nextError;
    if (error == null) return;
    nextError = null;
    throw error;
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _maybeThrow();
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
    _maybeThrow();
    final user = AuthUser(
      uid: 'fake-uid',
      email: email,
      displayName: displayName,
    );
    setUser(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    _maybeThrow();
    const user = AuthUser(uid: 'fake-google-uid', email: 'fake@gmail.com');
    setUser(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    _maybeThrow();
  }

  @override
  Future<void> signOut() async {
    setUser(null);
  }
}
