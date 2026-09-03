import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import 'profile_providers.dart';

/// Side-effect-only provider: on every sign-in, makes sure a `users/{uid}`
/// document exists, seeded from the auth provider's own data. Watched once
/// from [TravelStoriesApp] to stay alive for the app's lifetime — this is
/// how Profile depends on Authentication (not the other way around, so
/// Authentication has no knowledge of the Firestore schema).
final profileBootstrapProvider = Provider<void>((ref) {
  // fireImmediately: the app can start with a session already active (auth
  // state restored from disk before this provider is first watched), and
  // that initial value must trigger the same profile check as any later
  // sign-in — otherwise a returning user launching the app would never get
  // their profile document ensured.
  ref.listen(authStateChangesProvider, (previous, next) {
    final user = next.value;
    if (user == null) return;
    ref
        .read(ensureUserProfileUseCaseProvider)
        .call(
          uid: user.uid,
          displayName: user.displayName ?? '',
          photoUrl: user.photoUrl,
        );
  }, fireImmediately: true);
});
