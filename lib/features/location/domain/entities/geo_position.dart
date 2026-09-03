import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_position.freezed.dart';

@freezed
abstract class GeoPosition with _$GeoPosition {
  const factory GeoPosition({
    required double latitude,
    required double longitude,
  }) = _GeoPosition;
}
