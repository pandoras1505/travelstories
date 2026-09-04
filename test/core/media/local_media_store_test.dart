import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:travelstories/core/media/local_media_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('travelstories_media_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('writeMediaFile', () {
    test(
      'writes bytes at the given relative path, creating directories',
      () async {
        final bytes = utf8.encode('hello');

        final path = await writeMediaFile(
          relativePath: 'users/u1/profile/avatar.jpg',
          bytes: bytes,
          baseDirectory: tempDir.path,
        );

        expect(path, p.join(tempDir.path, 'users/u1/profile/avatar.jpg'));
        expect(await File(path).readAsBytes(), bytes);
      },
    );

    test('overwrites an existing file at the same path', () async {
      const relativePath = 'travelBooks/b1/cover/cover.jpg';

      final firstPath = await writeMediaFile(
        relativePath: relativePath,
        bytes: utf8.encode('first'),
        baseDirectory: tempDir.path,
      );
      final secondPath = await writeMediaFile(
        relativePath: relativePath,
        bytes: utf8.encode('second'),
        baseDirectory: tempDir.path,
      );

      expect(secondPath, firstPath);
      expect(await File(firstPath).readAsString(), 'second');
    });
  });

  group('deleteMediaDirectory', () {
    test('deletes the directory and everything under it', () async {
      final dir = 'travelBooks/b1/experiences/e1';
      await writeMediaFile(
        relativePath: '$dir/media.jpg',
        bytes: utf8.encode('media'),
        baseDirectory: tempDir.path,
      );
      await writeMediaFile(
        relativePath: '$dir/thumbnail.jpg',
        bytes: utf8.encode('thumb'),
        baseDirectory: tempDir.path,
      );

      await deleteMediaDirectory(dir, baseDirectory: tempDir.path);

      expect(await Directory(p.join(tempDir.path, dir)).exists(), isFalse);
    });

    test('is a no-op when the directory does not exist', () async {
      await expectLater(
        deleteMediaDirectory('nothing/here', baseDirectory: tempDir.path),
        completes,
      );
    });

    test('does not touch a sibling directory', () async {
      await writeMediaFile(
        relativePath: 'travelBooks/b1/cover/cover.jpg',
        bytes: utf8.encode('cover1'),
        baseDirectory: tempDir.path,
      );
      final keptPath = await writeMediaFile(
        relativePath: 'travelBooks/b2/cover/cover.jpg',
        bytes: utf8.encode('cover2'),
        baseDirectory: tempDir.path,
      );

      await deleteMediaDirectory('travelBooks/b1', baseDirectory: tempDir.path);

      expect(
        await Directory(p.join(tempDir.path, 'travelBooks/b1')).exists(),
        isFalse,
      );
      expect(await File(keptPath).readAsString(), 'cover2');
    });
  });
}
