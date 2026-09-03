import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/edit_experience_controller.dart';
import '../providers/experience_providers.dart';
import '../widgets/experience_form_fields.dart';

class EditExperienceScreen extends ConsumerStatefulWidget {
  const EditExperienceScreen({
    super.key,
    required this.travelBookId,
    required this.experienceId,
  });

  final String travelBookId;
  final String experienceId;

  @override
  ConsumerState<EditExperienceScreen> createState() =>
      _EditExperienceScreenState();
}

class _EditExperienceScreenState extends ConsumerState<EditExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(editExperienceControllerProvider.notifier)
        .saveChanges(
          travelBookId: widget.travelBookId,
          id: widget.experienceId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          locationName: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.experienceDeleteConfirmTitle),
        content: Text(l10n.experienceDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(editExperienceControllerProvider.notifier)
        .delete(travelBookId: widget.travelBookId, id: widget.experienceId);
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final experienceAsync = ref.watch(
      experienceProvider((
        travelBookId: widget.travelBookId,
        id: widget.experienceId,
      )),
    );
    final state = ref.watch(editExperienceControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(editExperienceControllerProvider, (previous, next) {
      final error = next.error;
      if (error is AppException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.experienceEditTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: isLoading ? null : _confirmDelete,
          ),
        ],
      ),
      body: experienceAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: l10n.commonError),
        data: (experience) {
          if (experience == null) return const SizedBox.shrink();
          if (!_initialized) {
            _titleController.text = experience.title;
            _descriptionController.text = experience.description;
            _locationController.text = experience.locationName ?? '';
            _initialized = true;
          }
          return SafeArea(
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
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: isLoading ? null : _save,
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
          );
        },
      ),
    );
  }
}
