import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/create_travel_book_controller.dart';
import '../widgets/travel_book_form_fields.dart';

/// The "Create" tab: the only creatable entity in the MVP is a travel book,
/// so this screen *is* the create-travel-book form (basic info only — a
/// cover photo and experiences are added afterward, from the book's detail/
/// edit screens, since both need the book to already exist).
class CreateTravelBookScreen extends ConsumerStatefulWidget {
  const CreateTravelBookScreen({super.key});

  @override
  ConsumerState<CreateTravelBookScreen> createState() =>
      _CreateTravelBookScreenState();
}

class _CreateTravelBookScreenState
    extends ConsumerState<CreateTravelBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublic = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (Validators.dateRange(_startDate, _endDate) != null) return;

    final newId = await ref
        .read(createTravelBookControllerProvider.notifier)
        .create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          isPublic: _isPublic,
        );

    if (newId != null && mounted) {
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _isPublic = false;
      });
      unawaited(context.push('${RoutePaths.travelBooks}/$newId'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createTravelBookControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(createTravelBookControllerProvider, (previous, next) {
      final error = next.error;
      if (error is AppException) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.travelBookNewTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TravelBookFormFields(
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateChanged: (value) =>
                      setState(() => _startDate = value),
                  onEndDateChanged: (value) => setState(() => _endDate = value),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.travelBookPublicToggle),
                  subtitle: Text(l10n.travelBookPublicToggleSubtitle),
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
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
                      : Text(
                          _isPublic
                              ? l10n.travelBookPublish
                              : l10n.travelBookSaveDraft,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
