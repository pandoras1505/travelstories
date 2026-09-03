import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_radius.dart';
import '../../domain/entities/geo_position.dart';

/// Small non-interactive map showing a single marker — used wherever an
/// experience already has a location and we just want to show where it is
/// (as opposed to [LocationPickerScreen], which is for picking one).
class ExperienceMapPreview extends StatelessWidget {
  const ExperienceMapPreview({super.key, required this.position});

  final GeoPosition position;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(position.latitude, position.longitude);
    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: SizedBox(
        height: 160,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travelstories.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 32,
                    height: 32,
                    child: Icon(
                      Icons.location_pin,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
