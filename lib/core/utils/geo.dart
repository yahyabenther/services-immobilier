import 'dart:math' as math;

/// Great-circle distance in kilometres (haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

typedef LatLngBounds = ({double minLat, double maxLat, double minLng, double maxLng});

/// Bounding box around a point; used to narrow the Firestore query before the
/// exact distance filter. (Does not handle the antimeridian — irrelevant for Tunisia.)
LatLngBounds boundingBox(double lat, double lng, double radiusKm) {
  final dLat = radiusKm / 111.0;
  final dLng = radiusKm / (111.0 * math.cos(lat * math.pi / 180).abs().clamp(0.01, 1.0));
  return (minLat: lat - dLat, maxLat: lat + dLat, minLng: lng - dLng, maxLng: lng + dLng);
}
