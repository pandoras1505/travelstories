import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a [Stream] to go_router's `refreshListenable`, so the router
/// re-evaluates `redirect` whenever the stream emits — used here to react
/// to auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
