import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validation_messages.dart';
import '../../../../core/utils/validators.dart';
import '../../../location/domain/entities/geo_position.dart';
import '../../../location/presentation/widgets/experience_map_preview.dart';

/// Title + description + location fields shared by the create and edit
/// experience screens. The location name is a free-text field the user can
/// also fill by tapping "use my location" (reverse-geocoded) or "pick on
/// map" — both of which also set [currentPosition], shown as a small map
/// preview when present.
class ExperienceFormFields extends StatelessWidget {
  const ExperienceFormFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.currentPosition,
    required this.isLocating,
    required this.onUseCurrentLocation,
    required this.onPickOnMap,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final GeoPosition? currentPosition;
  final bool isLocating;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onPickOnMap;

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
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLocating ? null : onUseCurrentLocation,
                icon: isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  l10n.experienceUseCurrentLocation,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickOnMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  l10n.experiencePickOnMap,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        if (currentPosition != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ExperienceMapPreview(position: currentPosition!),
        ],
      ],
    );
  }
}
