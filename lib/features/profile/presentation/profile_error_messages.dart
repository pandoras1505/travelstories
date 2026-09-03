import 'package:flutter/widgets.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/localization/generated/app_localizations.dart';

/// Maps a [StorageException.code] to a localized, user-safe message.
String storageErrorMessage(BuildContext context, StorageException exception) {
  final l10n = AppLocalizations.of(context)!;
  return switch (exception.code) {
    'unauthorized' || 'unauthenticated' => l10n.storageErrorUnauthorized,
    'object-not-found' ||
    'bucket-not-found' ||
    'project-not-found' => l10n.storageErrorUnavailable,
    _ => l10n.storageErrorUnknown,
  };
}
