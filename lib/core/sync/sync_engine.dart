import 'dart:async';

import '../connectivity/connectivity_service.dart';
import 'pending_mutation.dart';
import 'pending_mutations_local_data_source.dart';

/// Replays a queued mutation against Firestore (or wherever it's actually
/// headed) and throws if that fails — [SyncEngine] leaves it queued and
/// stops so ordering is preserved.
typedef MutationApplier = Future<void> Function(PendingMutation mutation);

/// Persists writes made while offline and replays them, in order, once
/// connectivity returns.
///
/// Repositories apply a mutation to the local cache immediately (so the UI
/// reflects it right away, online or not) and call [enqueue] with enough
/// payload to redo it against Firestore later; they also [registerApplier]
/// for each mutation `type` they own, in their own constructor.
///
/// Mutations are replayed strictly in the order they were queued: a flush
/// stops at the first failure rather than skipping ahead, since a later
/// write for the same entity must never reach Firestore before an earlier
/// one. [start] begins listening for reconnection (and, since
/// `ConnectivityService.onStatusChanged` reports the current status
/// immediately on listen, also covers "app relaunched while already online
/// with mutations left over from last time").
class SyncEngine {
  SyncEngine({
    required PendingMutationsLocalDataSource queue,
    required ConnectivityService connectivity,
    Duration applyTimeout = const Duration(seconds: 15),
  }) : _queue = queue,
       _connectivity = connectivity,
       _applyTimeout = applyTimeout;

  final PendingMutationsLocalDataSource _queue;
  final ConnectivityService _connectivity;
  final Duration _applyTimeout;
  final Map<String, MutationApplier> _appliers = {};

  StreamSubscription<bool>? _connectivitySubscription;
  Future<void>? _inFlightFlush;

  void registerApplier(String type, MutationApplier applier) {
    _appliers[type] = applier;
  }

  void start() {
    _connectivitySubscription ??= _connectivity.onStatusChanged.listen((
      online,
    ) {
      if (online) unawaited(flush());
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    await _queue.enqueue(type: type, payload: payload);
    unawaited(flush());
  }

  /// Processes queued mutations oldest-first. Safe to call any time — a
  /// call made while one is already running shares that same in-flight
  /// pass rather than starting a redundant one or no-opping (so a caller
  /// that awaits [flush] always sees the queue as settled once it
  /// returns) — and cheap to call when there's nothing to do or no
  /// connectivity.
  ///
  /// `connectivity_plus` only reports whether a network *interface* is up,
  /// not that Firestore is actually reachable through it (see
  /// [ConnectivityService]), so a false "online" reading could still hang
  /// an applier — [_applyTimeout] bounds that instead of jamming the queue
  /// until the next app restart.
  Future<void> flush() {
    return _inFlightFlush ??= _runFlushLoop().whenComplete(() {
      _inFlightFlush = null;
    });
  }

  Future<void> _runFlushLoop() async {
    while (true) {
      if (!await _connectivity.isOnline) return;

      final next = await _queue.first();
      if (next == null) return;

      final applier = _appliers[next.type];
      if (applier == null) {
        // No handler for this type (shouldn't happen) — drop it rather
        // than block every mutation behind it forever.
        await _queue.remove(next.id);
        continue;
      }

      try {
        await applier(next).timeout(_applyTimeout);
        await _queue.remove(next.id);
      } catch (_) {
        // Leave it queued and stop: preserves ordering, and the next
        // reconnect (or explicit flush) retries from this mutation.
        return;
      }
    }
  }
}
