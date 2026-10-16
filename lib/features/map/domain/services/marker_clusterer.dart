import 'dart:math' as math;

import '../../../properties/domain/entities/property.dart';
import '../entities/map_cluster.dart';

/// Pure grid clustering in screen space (no map SDK needed, fully unit-tested).
///
/// Properties are projected to world pixels at the current zoom (Web Mercator) and
/// bucketed in square cells of [cellPx]. A cell with several properties becomes one
/// cluster. Because cells are fixed in world space, panning never changes the clusters;
/// only zooming does.
class MarkerClusterer {
  const MarkerClusterer._();

  static const defaultCellPx = 64.0;

  /// From this zoom on we stop grid-clustering and only group listings that sit on
  /// (almost) the same point, so stacked markers can never hide each other.
  static const individualZoom = 17.0;

  /// [pinnedId] is never absorbed into a group (the selected listing stays visible).
  static List<MapCluster> cluster(
    List<Property> properties, {
    required double zoom,
    String? pinnedId,
    double cellPx = defaultCellPx,
  }) {
    final groups = <Object, List<Property>>{};
    final pinned = <Property>[];

    for (final p in properties) {
      if (!p.hasCoordinates) continue;
      if (p.id == pinnedId) {
        pinned.add(p);
        continue;
      }
      final Object key = zoom >= individualZoom
          ? '${p.latitude!.toStringAsFixed(5)}|${p.longitude!.toStringAsFixed(5)}'
          : _cell(p.latitude!, p.longitude!, zoom, cellPx);
      (groups[key] ??= []).add(p);
    }

    return [
      for (final g in groups.values) MapCluster.of(g),
      // Pinned last => drawn on top.
      for (final p in pinned) MapCluster.of([p]),
    ];
  }

  static (int, int) _cell(double lat, double lng, double zoom, double cellPx) {
    final scale = 256 * math.pow(2, zoom);
    final x = (lng + 180) / 360 * scale;
    final sinLat = math.sin(lat.clamp(-85.0511, 85.0511) * math.pi / 180);
    final y = (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return ((x / cellPx).floor(), (y / cellPx).floor());
  }
}
