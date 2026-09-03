import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Swaps sqflite's `databaseFactory` for the pure-Dart FFI one so tests can
/// open a real (in-memory) SQLite database without a device/emulator.
/// Idempotent — safe to call from every test file's `setUpAll`.
void initSqfliteFfiForTests() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
