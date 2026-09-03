import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/offline/local_first_stream.dart';

void main() {
  group('localFirstStream', () {
    test('emits the cache immediately, then remote updates', () async {
      final remoteController = StreamController<List<int>>();
      final written = <List<int>>[];

      final stream = localFirstStream<int>(
        readCache: () async => [1, 2],
        watchRemote: () => remoteController.stream,
        onRemoteData: (items) async => written.add(items),
      );

      final events = <List<int>>[];
      final subscription = stream.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        [1, 2],
      ]);

      remoteController.add([1, 2, 3]);
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        [1, 2],
        [1, 2, 3],
      ]);
      expect(written, [
        [1, 2, 3],
      ]);

      await remoteController.close();
      await subscription.cancel();
    });

    test('does not emit an empty cache before remote data arrives', () async {
      final remoteController = StreamController<List<int>>();

      final stream = localFirstStream<int>(
        readCache: () async => [],
        watchRemote: () => remoteController.stream,
        onRemoteData: (items) async {},
      );

      final events = <List<int>>[];
      final subscription = stream.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);

      remoteController.add([9]);
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        [9],
      ]);

      await remoteController.close();
      await subscription.cancel();
    });

    test(
      'rethrows a remote error when there was no cache to fall back to',
      () async {
        final stream = localFirstStream<int>(
          readCache: () async => [],
          watchRemote: () => Stream.error(Exception('offline')),
          onRemoteData: (items) async {},
        );

        expect(stream, emitsError(isException));
      },
    );

    test(
      'swallows a remote error once a non-empty cache was already emitted',
      () async {
        final stream = localFirstStream<int>(
          readCache: () async => [1],
          watchRemote: () => Stream.error(Exception('offline')),
          onRemoteData: (items) async {},
        );

        expect(
          stream,
          emitsInOrder([
            [1],
            emitsDone,
          ]),
        );
      },
    );
  });

  group('localFirstSingleStream', () {
    test('emits the cache immediately, then remote updates', () async {
      final remoteController = StreamController<String?>();

      final stream = localFirstSingleStream<String>(
        readCache: () async => 'cached',
        watchRemote: () => remoteController.stream,
        onRemoteData: (item) async {},
      );

      final events = <String?>[];
      final subscription = stream.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['cached']);

      remoteController.add('fresh');
      await Future<void>.delayed(Duration.zero);
      expect(events, ['cached', 'fresh']);

      await remoteController.close();
      await subscription.cancel();
    });

    test('a null remote emission (deleted) still reaches the caller', () async {
      final remoteController = StreamController<String?>();
      String? lastWritten = 'unset';

      final stream = localFirstSingleStream<String>(
        readCache: () async => 'cached',
        watchRemote: () => remoteController.stream,
        onRemoteData: (item) async => lastWritten = item,
      );

      final events = <String?>[];
      final subscription = stream.listen(events.add);
      await Future<void>.delayed(Duration.zero);

      remoteController.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(events, ['cached', null]);
      expect(lastWritten, isNull);

      await remoteController.close();
      await subscription.cancel();
    });

    test('rethrows a remote error when the cache was null', () async {
      final stream = localFirstSingleStream<String>(
        readCache: () async => null,
        watchRemote: () => Stream.error(Exception('offline')),
        onRemoteData: (item) async {},
      );

      expect(stream, emitsError(isException));
    });
  });
}
