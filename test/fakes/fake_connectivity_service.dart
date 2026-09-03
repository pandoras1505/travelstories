import 'dart:async';

import 'package:travelstories/core/connectivity/connectivity_service.dart';

/// In-memory [ConnectivityService] for tests — no platform channel touched.
/// Call [setOnline] to simulate connectivity changes.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool initiallyOnline = true})
    : _online = initiallyOnline;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onStatusChanged async* {
    yield _online;
    yield* _controller.stream;
  }

  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }
}
