import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/experience.dart';
import '../controllers/edit_experience_controller.dart';
import '../media_error_messages.dart';
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

  void _showMediaPicker() {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(editExperienceControllerProvider.notifier);
    void addPhoto(ImageSource source) {
      Navigator.of(context).pop();
      controller.addPhoto(
        travelBookId: widget.travelBookId,
        id: widget.experienceId,
        source: source,
      );
    }

    void addVideo(ImageSource source) {
      Navigator.of(context).pop();
      controller.addVideo(
        travelBookId: widget.travelBookId,
        id: widget.experienceId,
        source: source,
      );
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.experiencePickPhoto),
              onTap: () => addPhoto(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.experienceTakePhoto),
              onTap: () => addPhoto(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: Text(l10n.experiencePickVideo),
              onTap: () => addVideo(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l10n.experienceRecordVideo),
              onTap: () => addVideo(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
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
      if (error is StorageException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.commonError)));
      } else if (error is MediaException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(mediaErrorMessage(context, error))),
          );
      } else if (error is AppException) {
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
                    _MediaSection(
                      experience: experience,
                      isLoading: isLoading,
                      onTapAdd: _showMediaPicker,
                      onRemove: () => ref
                          .read(editExperienceControllerProvider.notifier)
                          .removeMedia(
                            travelBookId: widget.travelBookId,
                            id: widget.experienceId,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.experience,
    required this.isLoading,
    required this.onTapAdd,
    required this.onRemove,
  });

  final Experience experience;
  final bool isLoading;
  final VoidCallback onTapAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final hasMedia = experience.mediaType != ExperienceMediaType.text;

    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: isLoading ? null : onTapAdd,
              child: hasMedia
                  ? _MediaPreview(experience: experience)
                  : ColoredBox(
                      color: scheme.surfaceContainerHigh,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.experienceAddMedia,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
            ),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (hasMedia && !isLoading)
              Positioned(
                right: AppSpacing.sm,
                top: AppSpacing.sm,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.experience});

  final Experience experience;

  @override
  Widget build(BuildContext context) {
    if (experience.mediaType == ExperienceMediaType.image &&
        experience.mediaUrl != null) {
      return CachedNetworkImage(
        imageUrl: experience.mediaUrl!,
        fit: BoxFit.cover,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        experience.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: experience.thumbnailUrl!,
                fit: BoxFit.cover,
              )
            : ColoredBox(color: scheme.surfaceContainerHigh),
        Center(
          child: Icon(
            Icons.play_circle_fill,
            size: 48,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
