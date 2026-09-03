import '../entities/auth_user.dart';

/// Abstraction over the authentication provider. Implementations translate
/// provider-specific failures into [AuthException] (see core/errors) — no
/// Firebase type ever crosses this boundary.
abstract class AuthRepository {
  /// Emits the current user (or `null` when signed out) immediately on
  /// subscription, then again on every sign-in/sign-out.
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AuthUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthUser> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}
