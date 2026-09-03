import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/repositories/auth_repository.dart';
import 'datasources/firebase_auth_data_source.dart';
import 'repositories/auth_repository_impl.dart';

/// Single shared [AuthRepository] instance. Exposed to the widget tree via
/// `authRepositoryProvider` (see auth_providers.dart) and used directly by
/// `app_router.dart`, which lives outside the widget tree and therefore
/// cannot read a Riverpod provider — both consumers must share the same
/// instance rather than each wrapping its own [FirebaseAuth.instance].
final AuthRepository authRepository = AuthRepositoryImpl(
  dataSource: FirebaseAuthDataSource(
    firebaseAuth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn.instance,
  ),
);
