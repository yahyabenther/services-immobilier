import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../map/domain/entities/map_initial_camera.dart';
import '../../../map/domain/entities/map_state.dart';
import '../../../map/domain/services/marker_clusterer.dart';
import '../../../map/domain/usecases/get_current_location.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../../map/presentation/widgets/cluster_sheet.dart';
import '../../../map/presentation/widgets/map_canvas.dart';
import '../../../map/presentation/widgets/map_controls.dart';
import '../../../map/presentation/widgets/map_location_ui.dart';
import '../../../map/presentation/widgets/map_state_overlay.dart';
import '../../../map/presentation/widgets/map_strings.dart';
import '../../../map/presentation/widgets/selected_property_preview.dart';
import '../../../properties/domain/entities/property.dart';

/// Map side of the List/Map switch (Module 04 -> Module 06).
///
/// Shows EXACTLY the results of the list (same applied filter, same items), so switching
/// views never changes the result set. To explore other areas, "Search by area" opens the
/// full map with the same filter.
class SearchMapView extends ConsumerStatefulWidget {
  const SearchMapView({super.key, required this.items, required this.onShowList});

  final List<Property> items;
  final VoidCallback onShowList;

  @override
  ConsumerState<SearchMapView> createState() => _SearchMapViewState();
}

class _SearchMapViewState extends ConsumerState<SearchMapView> {
  final _map = MapController();
  String? _selectedId;
  double _zoom = MapInitialCamera.tunisia.zoom;
  MapUserLocation? _user;
  bool _isLocating = false;
  bool _explained = false;
  bool _ready = false;

  List<Property> get _mapped => [
        for (final p in widget.items)
          if (p.isPublic && p.hasCoordinates) p,
      ];

  CameraFit? _fit(List<Property> ps) => ps.isEmpty
      ? null
      : CameraFit.coordinates(
          coordinates: [for (final p in ps) LatLng(p.latitude!, p.longitude!)],
          padding: const EdgeInsets.all(56),
          maxZoom: 15,
        );

  @override
  void didUpdateWidget(SearchMapView old) {
    super.didUpdateWidget(old);
    final a = [for (final p in old.items) p.id].join(',');
    final b = [for (final p in widget.items) p.id].join(',');
    if (a == b) return;
    if (_selectedId != null && !widget.items.any((p) => p.id == _selectedId)) _selectedId = null;
    final fit = _fit(_mapped);
    if (fit != null && _ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _map.fitCamera(fit);
      });
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _onMapReady() {
    _ready = true;
    setState(() => _zoom = _map.camera.zoom);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if ((camera.zoom - _zoom).abs() < 0.1) return;
    _zoom = camera.zoom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _zoomBy(double d) {
    final c = _map.camera;
    _map.move(c.center, (c.zoom + d).clamp(5.0, 19.0).toDouble());
  }

  Future<void> _locate() async {
    if (_isLocating) return;
    if (!_explained && _user == null) {
      final ok = await showMapLocationExplainer(context);
      _explained = true;
      if (!ok || !mounted) return;
    }
    setState(() => _isLocating = true);
    final r = await ref.read(getCurrentLocationProvider)();
    if (!mounted) return;
    setState(() => _isLocating = false);
    if (r.outcome == LocateOutcome.located) {
      setState(() => _user = MapUserLocation(r.latitude!, r.longitude!));
      _map.move(LatLng(r.latitude!, r.longitude!), 14);
    } else {
      showLocateFailure(context, ref, r.outcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapped = _mapped;
    Property? selected;
    for (final p in mapped) {
      if (p.id == _selectedId) selected = p;
    }
    final clusters = MarkerClusterer.cluster(mapped, zoom: _zoom, pinnedId: _selectedId);

    return Stack(children: [
      Positioned.fill(
        child: MapCanvas(
          controller: _map,
          clusters: clusters,
          selectedId: _selectedId,
          userLocation: _user,
          initialFit: _fit(mapped),
          onMapReady: _onMapReady,
          onPositionChanged: _onPositionChanged,
          onMarkerTap: (p) => setState(() => _selectedId = p.id),
          onClusterTap: (c) => zoomIntoCluster(
            context: context,
            controller: _map,
            cluster: c,
            onPropertyChosen: (id) => setState(() => _selectedId = id),
          ),
          onMapTap: () => setState(() => _selectedId = null),
        ),
      ),
      Positioned(
        top: 8,
        left: 12,
        right: 12,
        child: Row(children: [
          if (mapped.length != widget.items.length)
            Material(
              elevation: 3,
              shape: const StadiumBorder(),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('${mapped.length} of ${widget.items.length} on the map',
                    style: const TextStyle(fontSize: 12, color: AppColors.text)),
              ),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.go(Routes.mapFromSearch()),
            icon: const Icon(Icons.travel_explore, size: 18),
            label: const Text('Search by area'),
            style: ElevatedButton.styleFrom(elevation: 4, shape: const StadiumBorder()),
          ),
        ]),
      ),
      Positioned(
        right: 12,
        bottom: selected != null ? 236 : 52,
        child: MapControls(
          isLocating: _isLocating,
          onZoomIn: () => _zoomBy(1),
          onZoomOut: () => _zoomBy(-1),
          onMyLocation: _locate,
        ),
      ),
      if (selected != null)
        Positioned(
          left: 12,
          right: 12,
          bottom: 36,
          child: SelectedPropertyPreview(
            key: ValueKey(selected.id),
            property: selected,
            onOpen: () => context.push(Routes.propertyDetails(selected!.id)),
            onClose: () => setState(() => _selectedId = null),
          ),
        )
      else if (mapped.isEmpty && widget.items.isNotEmpty)
        Positioned(
          left: 12,
          right: 76,
          bottom: 36,
          child: MapMessageCard(
            icon: Icons.location_off_outlined,
            title: MapStrings.noCoordsTitle,
            message: MapStrings.noCoordsMessage,
            actionLabel: 'Back to list',
            onAction: widget.onShowList,
          ),
        ),
    ]);
  }
}
