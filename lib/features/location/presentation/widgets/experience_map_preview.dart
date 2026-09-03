import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    final latLng = LatLng(position.latitude, position.longitude);
    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: SizedBox(
        height: 160,
        child: IgnorePointer(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: latLng, zoom: 13),
            markers: {
              Marker(markerId: const MarkerId('experience'), position: latLng),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            scrollGesturesEnabled: false,
            liteModeEnabled: true,
          ),
        ),
      ),
    );
  }
}
