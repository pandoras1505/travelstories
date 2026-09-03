import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validation_messages.dart';
import '../../../../core/utils/validators.dart';

/// Title + description + location-name fields shared by the create and
/// edit experience screens. `locationName` is a plain text field for now —
/// "use current location" / "pick on map" (which would also populate
/// latitude/longitude) ship in the Geolocation phase.
class ExperienceFormFields extends StatelessWidget {
  const ExperienceFormFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: titleController,
          decoration: InputDecoration(labelText: l10n.experienceTitleLabel),
          validator: (value) =>
              validationErrorMessage(context, Validators.title(value)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: l10n.experienceDescriptionLabel,
          ),
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: l10n.experienceLocationLabel,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        ),
      ],
    );
  }
}
