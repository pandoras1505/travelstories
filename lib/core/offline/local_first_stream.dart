/// A local-first stream for a *collection* query: emits whatever
/// [readCache] currently holds right away (if non-empty), so the UI has
/// something to show instantly — even offline, or before the remote's
/// first snapshot arrives — then switches to live [watchRemote] updates,
/// mirroring every remote emission into the cache via [onRemoteData]
/// before yielding it.
///
/// If [watchRemote] errors (typically: no connectivity) after a non-empty
/// cache snapshot was already emitted, the error is swallowed rather than
/// propagated: the caller just keeps the last known cache and the stream
/// ends. It's only rethrown when there was nothing to fall back to.
Stream<List<T>> localFirstStream<T>({
  required Future<List<T>> Function() readCache,
  required Stream<List<T>> Function() watchRemote,
  required Future<void> Function(List<T> items) onRemoteData,
}) async* {
  final cached = await readCache();
  if (cached.isNotEmpty) yield cached;

  try {
    await for (final items in watchRemote()) {
      await onRemoteData(items);
      yield items;
    }
  } catch (error) {
    if (cached.isEmpty) rethrow;
  }
}

/// Same as [localFirstStream], for a single-entity watch (`null` meaning
/// "doesn't exist" / "was deleted").
Stream<T?> localFirstSingleStream<T>({
  required Future<T?> Function() readCache,
  required Stream<T?> Function() watchRemote,
  required Future<void> Function(T? item) onRemoteData,
}) async* {
  final cached = await readCache();
  if (cached != null) yield cached;

  try {
    await for (final item in watchRemote()) {
      await onRemoteData(item);
      yield item;
    }
  } catch (error) {
    if (cached == null) rethrow;
  }
}
