/// Base of the app's exception hierarchy. Every exception carries a
/// [message] safe to show to the user (never a raw platform/SDK message —
/// e.g. a Firebase `permission-denied` code must never reach the UI) and an
/// optional [cause] kept for logging.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause, this.code});

  /// Provider-specific error code (e.g. `invalid-credential`), kept for
  /// logging/telemetry — never interpolated into [message].
  final String? code;
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.cause, this.code});

  final String? code;
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause, this.code});

  final String? code;
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

class LocationException extends AppException {
  const LocationException(super.message, {super.cause});
}

class MediaException extends AppException {
  const MediaException(super.message, {super.cause});
}

class SyncException extends AppException {
  const SyncException(super.message, {super.cause});
}
