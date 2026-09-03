import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validation_messages.dart';
import '../../../../core/utils/validators.dart';

/// Title + description + start/end date fields shared by the create and
/// edit travel book screens. Stateless by design — the parent screen owns
/// the [TextEditingController]s and the date values.
class TravelBookFormFields extends StatelessWidget {
  const TravelBookFormFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = MaterialLocalizations.of(context).formatMediumDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: titleController,
          decoration: InputDecoration(labelText: l10n.travelBookTitleLabel),
          validator: (value) =>
              validationErrorMessage(context, Validators.title(value)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: l10n.travelBookDescriptionLabel,
          ),
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _pickDate(context, startDate, onStartDateChanged),
                child: Text(
                  startDate == null
                      ? l10n.travelBookStartDateLabel
                      : dateFormat(startDate!),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickDate(context, endDate, onEndDateChanged),
                child: Text(
                  endDate == null
                      ? l10n.travelBookEndDateLabel
                      : dateFormat(endDate!),
                ),
              ),
            ),
          ],
        ),
        if (Validators.dateRange(startDate, endDate) != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            validationErrorMessage(
              context,
              Validators.dateRange(startDate, endDate),
            )!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
