import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../profile/presentation/profile_error_messages.dart';
import '../controllers/edit_travel_book_controller.dart';
import '../providers/travel_book_providers.dart';
import '../widgets/travel_book_form_fields.dart';

class EditTravelBookScreen extends ConsumerStatefulWidget {
  const EditTravelBookScreen({super.key, required this.travelBookId});

  final String travelBookId;

  @override
  ConsumerState<EditTravelBookScreen> createState() =>
      _EditTravelBookScreenState();
}

class _EditTravelBookScreenState extends ConsumerState<EditTravelBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCover(ImageSource source) async {
    Navigator.of(context).pop();
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final extension = picked.name.contains('.')
        ? picked.name.split('.').last
        : 'jpg';
    if (!mounted) return;
    await ref
        .read(editTravelBookControllerProvider.notifier)
        .uploadCover(
          id: widget.travelBookId,
          fileBytes: bytes,
          fileExtension: extension,
        );
  }

  void _showCoverPicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profileChoosePhoto),
              onTap: () => _pickCover(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profileTakePhoto),
              onTap: () => _pickCover(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (Validators.dateRange(_startDate, _endDate) != null) return;
    ref
        .read(editTravelBookControllerProvider.notifier)
        .saveChanges(
          id: widget.travelBookId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.travelBookDeleteConfirmTitle),
        content: Text(l10n.travelBookDeleteConfirmMessage),
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
        .read(editTravelBookControllerProvider.notifier)
        .delete(widget.travelBookId);
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookAsync = ref.watch(travelBookProvider(widget.travelBookId));
    final state = ref.watch(editTravelBookControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(editTravelBookControllerProvider, (previous, next) {
      final error = next.error;
      if (error is StorageException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(storageErrorMessage(context, error))),
          );
      } else if (error is AppException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.travelBookEditTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: isLoading ? null : _confirmDelete,
          ),
        ],
      ),
      body: bookAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: l10n.commonError),
        data: (book) {
          if (book == null) return const SizedBox.shrink();
          if (!_initialized) {
            _titleController.text = book.title;
            _descriptionController.text = book.description;
            _startDate = book.startDate;
            _endDate = book.endDate;
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
                    GestureDetector(
                      onTap: isLoading ? null : _showCoverPicker,
                      child: ClipRRect(
                        borderRadius: AppRadius.mdRadius,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              book.coverImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: book.coverImageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : ColoredBox(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh,
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 40,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                              Positioned(
                                right: AppSpacing.sm,
                                bottom: AppSpacing.sm,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    borderRadius: AppRadius.smRadius,
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TravelBookFormFields(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      startDate: _startDate,
                      endDate: _endDate,
                      onStartDateChanged: (value) =>
                          setState(() => _startDate = value),
                      onEndDateChanged: (value) =>
                          setState(() => _endDate = value),
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
                          : Text(l10n.travelBookSaveChanges),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => ref
                                .read(editTravelBookControllerProvider.notifier)
                                .togglePublish(
                                  id: widget.travelBookId,
                                  currentlyPublic: book.isPublic,
                                ),
                      child: Text(
                        book.isPublic
                            ? l10n.travelBookUnpublish
                            : l10n.travelBookPublish,
                      ),
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
