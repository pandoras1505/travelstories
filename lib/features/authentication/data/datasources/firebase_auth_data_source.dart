import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the Firebase Auth and Google Sign-In SDKs. Lets every
/// SDK exception propagate untouched — mapping to [AuthException] happens
/// one layer up, in [AuthRepositoryImpl].
class FirebaseAuthDataSource {
  FirebaseAuthDataSource({required fb_auth.FirebaseAuth firebaseAuth, required GoogleSignIn googleSignIn})
    : _firebaseAuth = firebaseAuth,
      _googleSignIn = googleSignIn;

  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  bool _googleSignInInitialized = false;

  Stream<fb_auth.User?> authStateChanges() => _firebaseAuth.authStateChanges();

  fb_auth.User? get currentUser => _firebaseAuth.currentUser;

  Future<fb_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<fb_auth.UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    await credential.user?.reload();
    return credential;
  }

  Future<fb_auth.UserCredential> signInWithGoogle() async {
    if (!_googleSignInInitialized) {
      await _googleSignIn.initialize();
      _googleSignInInitialized = true;
    }
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    final credential = fb_auth.GoogleAuthProvider.credential(idToken: idToken);
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_googleSignInInitialized) {
      await _googleSignIn.signOut();
    }
  }
}
