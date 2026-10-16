import '../../../properties/domain/entities/property.dart';

/// One thing drawn on the map: a single listing or a group of nearby listings.
class MapCluster {
  const MapCluster._({
    required this.properties,
    required this.latitude,
    required this.longitude,
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });

  /// [properties] must be non-empty and every property must have coordinates.
  factory MapCluster.of(List<Property> properties) {
    assert(properties.isNotEmpty);
    var south = double.infinity, north = -double.infinity;
    var west = double.infinity, east = -double.infinity;
    var sumLat = 0.0, sumLng = 0.0;
    for (final p in properties) {
      final lat = p.latitude!, lng = p.longitude!;
      if (lat < south) south = lat;
      if (lat > north) north = lat;
      if (lng < west) west = lng;
      if (lng > east) east = lng;
      sumLat += lat;
      sumLng += lng;
    }
    return MapCluster._(
      properties: List.unmodifiable(properties),
      latitude: sumLat / properties.length,
      longitude: sumLng / properties.length,
      south: south,
      north: north,
      west: west,
      east: east,
    );
  }

  final List<Property> properties;

  /// Centroid for groups, the property's own point for singles.
  final double latitude;
  final double longitude;
  final double south;
  final double north;
  final double west;
  final double east;

  /// Highest zoom at which we still try to split a cluster by zooming.
  static const maxSplitZoom = 17.5;

  int get count => properties.length;
  bool get isSingle => properties.length == 1;
  Property get single => properties.first;

  /// All members share (almost) the same point: zooming can never separate them.
  bool get isDegenerate => (north - south).abs() < 1e-5 && (east - west).abs() < 1e-5;

  bool canZoomFurther(double currentZoom) => !isDegenerate && currentZoom < maxSplitZoom;
}
