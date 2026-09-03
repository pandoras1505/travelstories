import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../location/presentation/location_picking_mixin.dart';
import '../controllers/create_experience_controller.dart';
import '../widgets/experience_form_fields.dart';

class CreateExperienceScreen extends ConsumerStatefulWidget {
  const CreateExperienceScreen({super.key, required this.travelBookId});

  final String travelBookId;

  @override
  ConsumerState<CreateExperienceScreen> createState() =>
      _CreateExperienceScreenState();
}

class _CreateExperienceScreenState extends ConsumerState<CreateExperienceScreen>
    with LocationPickingMixin<CreateExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  TextEditingController get locationController => _locationController;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newId = await ref
        .read(createExperienceControllerProvider.notifier)
        .create(
          travelBookId: widget.travelBookId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          locationName: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          latitude: position?.latitude,
          longitude: position?.longitude,
        );

    if (newId != null && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createExperienceControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(createExperienceControllerProvider, (previous, next) {
      final error = next.error;
      if (error is AppException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.experienceNewTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExperienceFormFields(
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  locationController: _locationController,
                  currentPosition: position,
                  isLocating: isLocating,
                  onUseCurrentLocation: useCurrentLocation,
                  onPickOnMap: pickOnMap,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
