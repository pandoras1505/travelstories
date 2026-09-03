import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/geo_position.dart';
import '../providers/location_providers.dart';

/// Full-screen map (OpenStreetMap tiles via `flutter_map` — no API key or
/// billing account required, unlike Google Maps): tap anywhere to drop a
/// pin, or tap the "my location" button to center on the device's current
/// position. Confirming returns the picked [GeoPosition] via
/// `Navigator.pop`.
///
/// All `flutter_map` usage in the app is confined to this file (and
/// [ExperienceMapPreview]) — swapping map providers later only touches
/// these two widgets, not the rest of the app, per the "don't couple the
/// whole app to one map provider" requirement.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key, this.initialPosition});

  final GeoPosition? initialPosition;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _mapController = MapController();
  LatLng? _picked;
  bool _locating = false;

  static const LatLng _fallbackCenter = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _picked = LatLng(
        widget.initialPosition!.latitude,
        widget.initialPosition!.longitude,
      );
    } else {
      _useCurrentLocation(recenter: false);
    }
  }

  Future<void> _useCurrentLocation({bool recenter = true}) async {
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationRepositoryProvider)
          .getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _picked = latLng);
      if (recenter) _mapController.move(latLng, 14);
    } catch (_) {
      // Permission denied / service disabled / no fix yet — the map still
      // works for manual tap-to-pick, so this failure is silent.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final picked = _picked;
    if (picked == null) return;
    Navigator.of(
      context,
    ).pop(GeoPosition(latitude: picked.latitude, longitude: picked.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initialCenter = _picked ?? _fallbackCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationPickerTitle),
        actions: [
          TextButton(
            onPressed: _picked == null ? null : _confirm,
            child: Text(l10n.locationPickerConfirm),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: _picked == null ? 1 : 14,
              onTap: (tapPosition, point) => setState(() => _picked = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travelstories.app',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: FloatingActionButton(
              onPressed: _locating ? null : () => _useCurrentLocation(),
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
