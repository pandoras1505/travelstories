import 'package:travelstories/features/location/domain/entities/geo_position.dart';
import 'package:travelstories/features/location/domain/repositories/location_repository.dart';

/// In-memory [LocationRepository] for tests — no geolocator/geocoding
/// plugin touched. Set [nextError] to make [getCurrentPosition] throw it
/// instead of returning [positionToReturn] (cleared after one use); set
/// [placeNameToReturn] to control what [reverseGeocode] resolves to.
class FakeLocationRepository implements LocationRepository {
  GeoPosition positionToReturn = const GeoPosition(
    latitude: 6.1319,
    longitude: 1.2228,
  );
  String? placeNameToReturn = 'Lomé, Togo';
  Object? nextError;

  int openLocationSettingsCallCount = 0;
  int openAppSettingsCallCount = 0;

  @override
  Future<GeoPosition> getCurrentPosition() async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return positionToReturn;
  }

  @override
  Future<String?> reverseGeocode(GeoPosition position) async {
    return placeNameToReturn;
  }

  @override
  Future<void> openLocationSettings() async {
    openLocationSettingsCallCount++;
  }

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCallCount++;
  }
}
