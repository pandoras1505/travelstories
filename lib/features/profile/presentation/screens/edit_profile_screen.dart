import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_image_cache.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validation_messages.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/edit_profile_controller.dart';
import '../profile_error_messages.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    Navigator.of(context).pop();
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final extension = picked.name.contains('.')
        ? picked.name.split('.').last
        : 'jpg';
    if (!mounted) return;
    final saved = await ref
        .read(editProfileControllerProvider.notifier)
        .uploadAvatar(fileBytes: bytes, fileExtension: extension);
    if (saved && mounted) _showSavedSnackbar();
  }

  void _showAvatarPicker() {
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
              onTap: () => _pickAvatar(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profileTakePhoto),
              onTap: () => _pickAvatar(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await ref
        .read(editProfileControllerProvider.notifier)
        .saveDisplayName(_displayNameController.text.trim());
    if (saved && mounted) _showSavedSnackbar();
  }

  void _showSavedSnackbar() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final state = ref.watch(editProfileControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(editProfileControllerProvider, (previous, next) {
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
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => Center(child: Text(l10n.commonError)),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          if (!_initialized) {
            _displayNameController.text = profile.displayName;
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
                      onTap: isLoading ? null : _showAvatarPicker,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: profile.photoUrl != null
                                ? appImageProvider(
                                    profile.photoUrl!,
                                    maxWidth: AppImageCache.largeAvatar,
                                    maxHeight: AppImageCache.largeAvatar,
                                  )
                                : null,
                            // See profile_screen.dart — avoid reporting the
                            // expected "local avatar file doesn't exist on
                            // this device" case to Crashlytics.
                            onBackgroundImageError: profile.photoUrl != null
                                ? (error, stackTrace) {}
                                : null,
                            child: profile.photoUrl == null
                                ? Text(
                                    profile.displayName.isNotEmpty
                                        ? profile.displayName[0].toUpperCase()
                                        : '?',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: l10n.authDisplayNameLabel,
                      ),
                      validator: (value) => validationErrorMessage(
                        context,
                        Validators.displayName(value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: isLoading ? null : _save,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.profileSaveButton),
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
