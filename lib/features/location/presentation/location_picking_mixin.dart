import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/geo_position.dart';
import 'location_error_messages.dart';
import 'providers/location_providers.dart';
import 'screens/location_picker_screen.dart';

/// Shared "use my location" / "pick on map" behavior for any
/// [ConsumerState] that has a location name [TextEditingController] to
/// fill in — used by both the create and edit experience screens so the
/// GPS/reverse-geocoding/navigation logic isn't duplicated between them.
mixin LocationPickingMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  GeoPosition? position;
  bool isLocating = false;

  TextEditingController get locationController;

  Future<void> useCurrentLocation() async {
    setState(() => isLocating = true);
    try {
      final repository = ref.read(locationRepositoryProvider);
      final picked = await repository.getCurrentPosition();
      final placeName = await repository.reverseGeocode(picked);
      if (!mounted) return;
      setState(() {
        position = picked;
        if (placeName != null) locationController.text = placeName;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(locationErrorMessage(context, e))),
        );
    } finally {
      if (mounted) setState(() => isLocating = false);
    }
  }

  Future<void> pickOnMap() async {
    final picked = await Navigator.of(context).push<GeoPosition>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPosition: position),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => position = picked);
    final placeName = await ref
        .read(locationRepositoryProvider)
        .reverseGeocode(picked);
    if (placeName != null && mounted) {
      setState(() => locationController.text = placeName);
    }
  }
}
