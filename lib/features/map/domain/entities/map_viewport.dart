/// Visible geographic rectangle + zoom, independent of any map SDK
/// (the SDK's own bounds type is converted at the presentation edge).
class MapViewport {
  const MapViewport({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.zoom,
  });

  /// Clamps latitudes and wraps longitudes into the valid ranges. Use this when the
  /// numbers come from a map camera (which can report longitudes beyond +-180).
  factory MapViewport.normalized({
    required double north,
    required double south,
    required double east,
    required double west,
    required double zoom,
  }) {
    double lat(double v) => v.clamp(-90.0, 90.0).toDouble();
    double wrap(double v) {
      var x = (v + 180) % 360;
      if (x < 0) x += 360;
      return x - 180;
    }

    if (east - west >= 360) {
      return MapViewport(north: lat(north), south: lat(south), east: 180, west: -180, zoom: zoom);
    }
    return MapViewport(north: lat(north), south: lat(south), east: wrap(east), west: wrap(west), zoom: zoom);
  }

  final double north;
  final double south;
  final double east;
  final double west;
  final double zoom;

  bool get isValid =>
      [north, south, east, west, zoom].every((v) => v.isFinite) &&
      north >= south &&
      north <= 90 &&
      south >= -90 &&
      east.abs() <= 180 &&
      west.abs() <= 180;

  /// True when the rectangle crosses the antimeridian (west > east).
  bool get crossesAntimeridian => west > east;

  bool contains(double latitude, double longitude) {
    if (latitude < south || latitude > north) return false;
    return crossesAntimeridian
        ? (longitude >= west || longitude <= east)
        : (longitude >= west && longitude <= east);
  }

  /// True when [other] lies inside this viewport grown by [tolerance] (a fraction of
  /// this viewport's size). Conservative for antimeridian cases (returns false).
  bool containsViewport(MapViewport other, {double tolerance = 0}) {
    if (crossesAntimeridian || other.crossesAntimeridian) return false;
    final latPad = (north - south) * tolerance;
    final lngPad = (east - west) * tolerance;
    return other.north <= north + latPad &&
        other.south >= south - latPad &&
        other.east <= east + lngPad &&
        other.west >= west - lngPad;
  }

  /// Identity of the AREA (zoom excluded), rounded to ~100 m so tiny camera jitter does
  /// not count as a new area. Used to avoid duplicate requests.
  String get cacheKey => '${_r(north)},${_r(south)},${_r(east)},${_r(west)}';

  static String _r(double v) => v.toStringAsFixed(3);

  @override
  bool operator ==(Object other) =>
      other is MapViewport &&
      other.north == north &&
      other.south == south &&
      other.east == east &&
      other.west == west &&
      other.zoom == zoom;

  @override
  int get hashCode => Object.hash(north, south, east, west, zoom);

  @override
  String toString() => 'MapViewport(n:$north s:$south e:$east w:$west z:$zoom)';
}
