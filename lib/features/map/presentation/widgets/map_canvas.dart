import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/map_cluster.dart';
import '../../domain/entities/map_initial_camera.dart';
import '../../domain/entities/map_state.dart';
import '../../map_config.dart';
import 'property_cluster_marker.dart';
import 'property_marker.dart';

/// The map SDK adapter (spec §7.2): tiles, markers, clusters, user dot, attribution.
/// It only turns SDK events into app-level callbacks and holds no business logic, so
/// the page and the embedded Search map view share it.
class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.controller,
    required this.clusters,
    required this.selectedId,
    required this.onMarkerTap,
    required this.onClusterTap,
    required this.onMapTap,
    this.userLocation,
    this.initialCenter,
    this.initialZoom,
    this.initialFit,
    this.onMapReady,
    this.onPositionChanged,
  });

  final MapController controller;
  final List<MapCluster> clusters;
  final String? selectedId;
  final ValueChanged<Property> onMarkerTap;
  final ValueChanged<MapCluster> onClusterTap;
  final VoidCallback onMapTap;
  final MapUserLocation? userLocation;
  final LatLng? initialCenter;
  final double? initialZoom;
  final CameraFit? initialFit;
  final VoidCallback? onMapReady;
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;

  Marker _marker(MapCluster c) {
    final point = LatLng(c.latitude, c.longitude);
    if (c.isSingle) {
      final p = c.single;
      final selected = p.id == selectedId;
      final size = selected ? 60.0 : 48.0;
      return Marker(
        point: point,
        width: size,
        height: size,
        alignment: Alignment.topCenter, // pin tip sits on the coordinate
        child: PropertyMarkerPin(property: p, selected: selected, onTap: () => onMarkerTap(p)),
      );
    }
    final size = c.count > 99 ? 58.0 : (c.count > 9 ? 52.0 : 46.0);
    return Marker(
      point: point,
      width: size,
      height: size,
      child: PropertyClusterMarker(count: c.count, onTap: () => onClusterTap(c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallback = MapInitialCamera.tunisia;
    final user = userLocation;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter ?? LatLng(fallback.latitude, fallback.longitude),
        initialZoom: initialZoom ?? fallback.zoom,
        initialCameraFit: initialFit,
        minZoom: mapMinZoom,
        maxZoom: mapMaxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: onMapReady,
        onPositionChanged: onPositionChanged,
        onTap: (_, __) => onMapTap(),
      ),
      children: [
        TileLayer(
          urlTemplate: mapTileUrlTemplate,
          userAgentPackageName: mapUserAgentPackageName,
          maxNativeZoom: 19,
        ),
        if (user != null)
          MarkerLayer(markers: [
            Marker(
              point: LatLng(user.latitude, user.longitude),
              width: 24,
              height: 24,
              child: IgnorePointer(
                child: Semantics(
                  label: 'Your location',
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        MarkerLayer(markers: [for (final c in clusters) _marker(c)]),
        const RichAttributionWidget(attributions: [TextSourceAttribution(mapAttribution)]),
      ],
    );
  }
}
