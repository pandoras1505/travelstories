import 'dart:async';

/// A local-first stream for a *collection* query: emits whatever
/// [readCache] currently holds right away (if non-empty), so the UI has
/// something to show instantly — even offline, or before the remote's
/// first snapshot arrives — then switches to live [watchRemote] updates,
/// mirroring every remote emission into the cache via [onRemoteData]
/// before yielding it.
///
/// If [watchRemote] errors (typically: no connectivity, or a transient
/// `permission-denied` while switching accounts) after a cache snapshot —
/// initial or previously received from the remote — was already emitted,
/// the error is swallowed rather than propagated: the caller keeps the
/// last known value, and [watchRemote] is resubscribed after [retryDelay]
/// rather than ending the stream. A `StreamProvider` watching this is not
/// `autoDispose`, so ending here would freeze that entity's updates for
/// the rest of the app session — even once the transient condition (e.g.
/// re-authenticating as the right user) clears. The error is only
/// propagated, ending the stream, when there was nothing to fall back to.
///
/// Built on [Stream.multi] rather than `async*`/`await for` so that
/// cancelling the returned stream's subscription actually stops a
/// pending retry: an `async*` generator only notices cancellation at a
/// `yield`, which a retry loop that's currently failing never reaches —
/// it would otherwise keep calling [watchRemote] forever in the
/// background even after nothing is listening.
Stream<List<T>> localFirstStream<T>({
  required Future<List<T>> Function() readCache,
  required Stream<List<T>> Function() watchRemote,
  required Future<void> Function(List<T> items) onRemoteData,
  Duration retryDelay = const Duration(seconds: 3),
}) {
  return _localFirstMulti<List<T>>(
    isEmpty: (items) => items.isEmpty,
    readCache: readCache,
    watchRemote: watchRemote,
    onRemoteData: onRemoteData,
    retryDelay: retryDelay,
  );
}

/// Same as [localFirstStream], for a single-entity watch (`null` meaning
/// "doesn't exist" / "was deleted").
Stream<T?> localFirstSingleStream<T>({
  required Future<T?> Function() readCache,
  required Stream<T?> Function() watchRemote,
  required Future<void> Function(T? item) onRemoteData,
  Duration retryDelay = const Duration(seconds: 3),
}) {
  return _localFirstMulti<T?>(
    isEmpty: (item) => item == null,
    readCache: readCache,
    watchRemote: watchRemote,
    onRemoteData: onRemoteData,
    retryDelay: retryDelay,
  );
}

/// Shared implementation behind [localFirstStream]/[localFirstSingleStream]
/// — [isEmpty] tells it "no fallback value" (`[]` for the collection case,
/// `null` for the single-entity case) without needing two near-identical
/// copies of the retry/cancellation machinery.
Stream<V> _localFirstMulti<V>({
  required bool Function(V value) isEmpty,
  required Future<V> Function() readCache,
  required Stream<V> Function() watchRemote,
  required Future<void> Function(V value) onRemoteData,
  required Duration retryDelay,
}) {
  return Stream.multi((controller) {
    var cancelled = false;
    var hasFallback = false;
    StreamSubscription<V>? remoteSub;
    Timer? retryTimer;

    controller.onCancel = () {
      cancelled = true;
      retryTimer?.cancel();
      return remoteSub?.cancel();
    };

    void subscribeRemote() {
      // A stream that errors (e.g. `Stream.error`, or a real Firestore
      // listener tearing itself down after a permission-denied) fires
      // `onDone` right after `onError` — track that onError already
      // decided what should happen next, so `onDone` doesn't also close
      // the outer stream out from under a just-scheduled retry.
      var handled = false;
      remoteSub = watchRemote().listen(
        null,
        onError: (Object error, StackTrace stackTrace) {
          if (cancelled) return;
          handled = true;
          if (!hasFallback) {
            controller.addError(error, stackTrace);
            controller.close();
            return;
          }
          retryTimer = Timer(retryDelay, () {
            if (!cancelled) subscribeRemote();
          });
        },
        onDone: () {
          if (!cancelled && !handled) controller.close();
        },
      );
      remoteSub!.onData((value) {
        remoteSub!.pause();
        hasFallback = true;
        onRemoteData(value).then((_) {
          if (cancelled) return;
          controller.add(value);
          remoteSub!.resume();
        });
      });
    }

    readCache().then((cached) {
      if (cancelled) return;
      hasFallback = !isEmpty(cached);
      if (hasFallback) controller.add(cached);
      subscribeRemote();
    });
  });
}
