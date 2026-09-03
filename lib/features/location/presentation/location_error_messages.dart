import 'package:flutter/widgets.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/localization/generated/app_localizations.dart';

String locationErrorMessage(BuildContext context, LocationException exception) {
  final l10n = AppLocalizations.of(context)!;
  return switch (exception.code) {
    'service-disabled' => l10n.locationErrorServiceDisabled,
    'permission-denied' => l10n.locationErrorPermissionDenied,
    'permission-denied-forever' => l10n.locationErrorPermissionDeniedForever,
    _ => l10n.locationErrorUnknown,
  };
}
