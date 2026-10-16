import '../../../../core/constants/tunisia_governorate_centers.dart';

/// Where the map camera starts.
class MapInitialCamera {
  const MapInitialCamera({required this.latitude, required this.longitude, required this.zoom});

  final double latitude;
  final double longitude;
  final double zoom;

  /// Documented default: the whole of Tunisia.
  static const tunisia = MapInitialCamera(latitude: 33.8869, longitude: 9.5375, zoom: 6.2);

  static const _pointZoom = 13.5;
  static const _governorateZoom = 10.5;

  /// Camera hinted by the navigation context: `lat`/`lng` route params (device position
  /// from Home) or a governorate. Null when there is no usable hint.
  static MapInitialCamera? fromHints(Map<String, String> params, {String? governorate}) {
    final lat = double.tryParse(params['lat'] ?? '');
    final lng = double.tryParse(params['lng'] ?? '');
    if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
      return MapInitialCamera(latitude: lat, longitude: lng, zoom: _pointZoom);
    }
    final center = governorate == null ? null : tunisiaGovernorateCenters[governorate];
    if (center != null) {
      return MapInitialCamera(latitude: center.lat, longitude: center.lng, zoom: _governorateZoom);
    }
    return null;
  }
}
