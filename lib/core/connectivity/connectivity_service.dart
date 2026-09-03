/// Best-effort network-reachability signal, used to show the offline
/// banner and to let repositories fall back to the local cache without
/// waiting on a hanging Firestore call.
///
/// Backed by `connectivity_plus`, which only reports whether a network
/// *interface* is up (wifi/mobile/ethernet), not that the internet is
/// actually reachable through it — a captive portal or a dead upstream
/// link would still read as "online" here. Good enough for this app's
/// purpose (deciding whether to expect Firestore to respond), not a
/// substitute for a real reachability check.
abstract class ConnectivityService {
  /// The current status, immediately, then again on every change.
  Stream<bool> get onStatusChanged;

  Future<bool> get isOnline;
}
