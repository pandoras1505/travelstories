import '../entities/geo_position.dart';

abstract class LocationRepository {
  /// Requests permission if needed, then returns the device's current
  /// position. Throws [LocationException] if permission is denied, denied
  /// forever, or the location service is disabled.
  Future<GeoPosition> getCurrentPosition();

  /// Best-effort human-readable place name (e.g. "Kpalimé, Togo") for a
  /// position — `null` if reverse geocoding found nothing.
  Future<String?> reverseGeocode(GeoPosition position);

  Future<void> openLocationSettings();

  Future<void> openAppSettings();
}
