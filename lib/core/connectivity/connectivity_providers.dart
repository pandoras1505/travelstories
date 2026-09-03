import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_plus_service.dart';
import 'connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityPlusService();
});

/// Live online/offline status — drives the offline banner ([OfflineBanner])
/// and lets repositories fall back to the local cache.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onStatusChanged;
});
