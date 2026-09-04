import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local on-device replacement for Firebase Storage — not activated in this
/// deployment (needs the paid Blaze plan, see HANDOFF.md §4.3/§8). Every
/// path previously used with Firebase Storage (`users/{uid}/profile/...`,
/// `travelBooks/{id}/cover/...`, `travelBooks/{id}/experiences/{id}/...`) is
/// reproduced unchanged under `<app documents directory>/media/`, so
/// `AvatarStorageDataSource`, `CoverStorageDataSource` and
/// `ExperienceMediaStorageDataSource` only had to swap what backs their
/// `upload`/`deleteAll` methods, not their callers or the Firestore fields
/// they write.
///
/// Trade-off accepted by the user: media is only ever readable on the
/// device that wrote it — see OFFLINE_SYNC.md. Reactivating real Storage
/// later means rewriting only those three data source classes back.

/// Writes [bytes] to `<mediaDirectory>/<relativePath>`, creating parent
/// directories as needed, and returns the resulting absolute file path.
/// Overwrites anything already at that exact path. Pass [baseDirectory] to
/// override the root — tests only; production always resolves the real app
/// documents directory via `path_provider`.
Future<String> writeMediaFile({
  required String relativePath,
  required List<int> bytes,
  String? baseDirectory,
}) async {
  final base = baseDirectory ?? await _defaultMediaDirectory();
  final file = File(p.join(base, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// Deletes `<mediaDirectory>/<relativeDirPath>` and everything under it, if
/// it exists — a no-op otherwise. See [writeMediaFile] for [baseDirectory].
Future<void> deleteMediaDirectory(
  String relativeDirPath, {
  String? baseDirectory,
}) async {
  final base = baseDirectory ?? await _defaultMediaDirectory();
  final dir = Directory(p.join(base, relativeDirPath));
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

Future<String> _defaultMediaDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return p.join(documents.path, 'media');
}
