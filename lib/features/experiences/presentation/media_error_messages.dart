import 'package:flutter/widgets.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/localization/generated/app_localizations.dart';

/// Maps a [MediaException.code] to a localized, user-safe message.
String mediaErrorMessage(BuildContext context, MediaException exception) {
  final l10n = AppLocalizations.of(context)!;
  return switch (exception.code) {
    'image-too-large' => l10n.mediaErrorImageTooLarge,
    'video-too-large' => l10n.mediaErrorVideoTooLarge,
    null => l10n.mediaErrorProcessingFailed,
    _ => l10n.mediaErrorUnknown,
  };
}
