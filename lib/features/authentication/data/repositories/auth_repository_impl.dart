import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource}) : _dataSource = dataSource;

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _dataSource.authStateChanges().map(_toAuthUser);
  }

  @override
  AuthUser? get currentUser => _toAuthUser(_dataSource.currentUser);

  @override
  Future<AuthUser> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      final credential = await _dataSource.signInWithEmailAndPassword(email: email, password: password);
      return _requireAuthUser(credential.user);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _dataSource.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return _requireAuthUser(credential.user);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final credential = await _dataSource.signInWithGoogle();
      return _requireAuthUser(credential.user);
    } on GoogleSignInException catch (e) {
      throw _mapGoogleSignInException(e);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _dataSource.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  AuthUser _requireAuthUser(fb_auth.User? user) {
    final authUser = _toAuthUser(user);
    if (authUser == null) {
      throw const AuthException('Authentication succeeded without a user.', code: 'missing-user');
    }
    return authUser;
  }

  AuthUser? _toAuthUser(fb_auth.User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email, displayName: user.displayName, photoUrl: user.photoURL);
  }

  AuthException _mapFirebaseAuthException(fb_auth.FirebaseAuthException e) {
    return AuthException('Firebase Auth error: ${e.code}', code: e.code, cause: e);
  }

  AuthException _mapGoogleSignInException(GoogleSignInException e) {
    final code = switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'google-sign-in-cancelled',
      _ => 'google-sign-in-failed',
    };
    return AuthException('Google sign-in error: ${e.code}', code: code, cause: e);
  }
}
