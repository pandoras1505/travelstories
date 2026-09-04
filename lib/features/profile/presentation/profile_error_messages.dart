import 'package:flutter/widgets.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/localization/generated/app_localizations.dart';

/// Maps a [StorageException.code] to a localized, user-safe message.
///
/// `'io-error'` is what the app's storage data sources actually produce
/// today (local on-disk storage — Firebase Storage isn't activated, see
/// HANDOFF.md §4.3/§8). The Firebase Storage codes below are dormant, not
/// dead: they'd fire again unchanged if those data sources were switched
/// back to real Storage, since nothing else would need to change for that.
String storageErrorMessage(BuildContext context, StorageException exception) {
  final l10n = AppLocalizations.of(context)!;
  return switch (exception.code) {
    'io-error' => l10n.storageErrorUnavailable,
    'unauthorized' || 'unauthenticated' => l10n.storageErrorUnauthorized,
    'object-not-found' ||
    'bucket-not-found' ||
    'project-not-found' => l10n.storageErrorUnavailable,
    _ => l10n.storageErrorUnknown,
  };
}
