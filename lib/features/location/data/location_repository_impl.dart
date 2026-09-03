import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/geo_position.dart';
import '../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({geocoding.Geocoding? geocoder})
    : _geocoder = geocoder ?? geocoding.Geocoding();

  final geocoding.Geocoding _geocoder;

  @override
  Future<GeoPosition> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Location services are disabled.',
        code: 'service-disabled',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission denied.',
        code: 'permission-denied',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission permanently denied.',
        code: 'permission-denied-forever',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      throw LocationException('Failed to read current position.', cause: e);
    }
  }

  @override
  Future<String?> reverseGeocode(GeoPosition position) async {
    try {
      final placemarks = await _geocoder.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final parts = [
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((part) => part != null && part.isNotEmpty);
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      // Reverse geocoding is a nice-to-have (pre-fills the location name
      // field) — a failure here shouldn't block picking a location.
      return null;
    }
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
