import 'dart:async';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../search/domain/entities/property_search_filter.dart';
import '../../../search/domain/entities/search_enums.dart';
import '../../../search/presentation/widgets/active_filter_chips.dart';
import '../../../search/presentation/widgets/listing_tab_bar.dart';
import '../../../search/presentation/widgets/search_filter_sheet.dart';
import '../../../search/providers/search_providers.dart';
import '../../../search/providers/search_state.dart';
import '../../domain/entities/map_initial_camera.dart';
import '../../domain/entities/map_state.dart';
import '../../domain/entities/map_viewport.dart';
import '../../domain/services/map_filter_resolver.dart';
import '../../domain/services/marker_clusterer.dart';
import '../../domain/usecases/get_current_location.dart';
import '../providers/map_providers.dart';
import '../widgets/cluster_sheet.dart';
import '../widgets/map_canvas.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_location_ui.dart';
import '../widgets/map_state_overlay.dart';
import '../widgets/map_strings.dart';
import '../widgets/search_this_area_button.dart';
import '../widgets/selected_property_preview.dart';

/// Module 06 screen. [params] are the route query parameters
/// (`/map?governorate=Sfax`, `/map?lat=..&lng=..`, `/map?source=search`).
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key, this.params = const {}});

  final Map<String, String> params;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _map = MapController();
  late MapInitialCamera _initial;
  Timer? _idle;
  bool _byUser = false; // a gesture happened since the camera last settled
  bool _locationExplained = false;

  @override
  void initState() {
    super.initState();
    final filter = resolveMapFilter(widget.params, searchFilter: ref.read(searchResultsProvider).filter);
    _initial = MapInitialCamera.fromHints(widget.params, governorate: filter.governorate) ??
        MapInitialCamera.tunisia;
    Future.microtask(() {
      if (mounted) ref.read(mapScreenProvider.notifier).applyRouteParams(widget.params);
    });
  }

  @override
  void didUpdateWidget(MapPage old) {
    super.didUpdateWidget(old);
    if (mapEquals(old.params, widget.params) || widget.params.isEmpty) return;
    final ctl = ref.read(mapScreenProvider.notifier);
    ctl.applyRouteParams(widget.params);
    final target = MapInitialCamera.fromHints(widget.params,
        governorate: ref.read(mapScreenProvider).filter.governorate);
    if (target != null) _map.move(LatLng(target.latitude, target.longitude), target.zoom);
    _syncAndSearchAfterFrame();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _map.dispose();
    super.dispose();
  }

  // ---- camera <-> controller ---------------------------------------------------------
  MapViewport _viewportOf(MapCamera c) {
    final b = c.visibleBounds;
    return MapViewport.normalized(north: b.north, south: b.south, east: b.east, west: b.west, zoom: c.zoom);
  }

  void _onMapReady() => ref.read(mapScreenProvider.notifier).onMapReady(_viewportOf(_map.camera));

  /// Debounced: intermediate gesture events never reach the controller.
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _byUser = _byUser || hasGesture;
    _idle?.cancel();
    _idle = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final byUser = _byUser;
      _byUser = false;
      ref.read(mapScreenProvider.notifier).onCameraIdle(_viewportOf(_map.camera), byUser: byUser);
    });
  }

  void _syncAndSearchAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctl = ref.read(mapScreenProvider.notifier);
      ctl.onCameraIdle(_viewportOf(_map.camera), byUser: false);
      ctl.searchCurrentArea();
    });
  }

  void _zoomBy(double delta) {
    _byUser = true; // button zoom is a user action: may offer "Search this area"
    final c = _map.camera;
    _map.move(c.center, (c.zoom + delta).clamp(5.0, 19.0).toDouble());
  }

  // ---- actions ---------------------------------------------------------------------------
  Future<void> _locate() async {
    final ctl = ref.read(mapScreenProvider.notifier);
    if (!_locationExplained && ref.read(mapScreenProvider).userLocation == null) {
      final ok = await showMapLocationExplainer(context);
      _locationExplained = true;
      if (!ok || !mounted) return;
    }
    final r = await ctl.locateMe();
    if (r == null || !mounted) return;
    if (r.outcome == LocateOutcome.located) {
      _map.move(LatLng(r.latitude!, r.longitude!), 14);
      _syncAndSearchAfterFrame();
    } else {
      showLocateFailure(context, ref, r.outcome);
    }
  }

  void _onMarkerTap(Property p) {
    ref.read(mapScreenProvider.notifier).selectProperty(p.id);
    // Keep the marker clear of the preview card (bottom of the screen).
    final vp = ref.read(mapScreenProvider).viewport;
    if (vp == null) return;
    final span = vp.north - vp.south;
    if (span <= 0) return;
    final fromTop = (vp.north - p.latitude!) / span;
    if (fromTop > 0.5) _map.move(LatLng(p.latitude! - 0.15 * span, p.longitude!), _map.camera.zoom);
  }

  Future<void> _openFilters() async {
    final current = ref.read(mapScreenProvider).filter;
    final result = await showSearchFilterSheet(context, current);
    if (result != null && mounted) await ref.read(mapScreenProvider.notifier).applyFilter(result);
  }

  /// Back to list view keeping the map's criteria (spec §13.1).
  void _showAsList() {
    final search = ref.read(searchResultsProvider.notifier);
    search.applyFilter(ref.read(mapScreenProvider).filter);
    search.setViewMode(SearchViewMode.list);
    context.go(Routes.search);
  }

  void _openDetails(Property p) => context.push(Routes.propertyDetails(p.id));

  // ---- build -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(mapScreenProvider);
    final ctl = ref.read(mapScreenProvider.notifier);
    final zoom = s.viewport?.zoom ?? _initial.zoom;
    final clusters = MarkerClusterer.cluster(s.properties, zoom: zoom, pinnedId: s.selectedId);
    final selected = s.selectedProperty;
    final hasCriteria = s.filter != s.filter.cleared();

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: MapCanvas(
            controller: _map,
            clusters: clusters,
            selectedId: s.selectedId,
            userLocation: s.userLocation,
            initialCenter: LatLng(_initial.latitude, _initial.longitude),
            initialZoom: _initial.zoom,
            onMapReady: _onMapReady,
            onPositionChanged: _onPositionChanged,
            onMarkerTap: _onMarkerTap,
            onClusterTap: (c) => zoomIntoCluster(
              context: context,
              controller: _map,
              cluster: c,
              onPropertyChosen: ctl.selectProperty,
            ),
            onMapTap: ctl.clearSelection,
          ),
        ),

        // ---- top overlay: summary, filters, status, "search this area" ----
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _TopCard(
                  state: s,
                  onTab: (t) => ctl.applyFilter(s.filter.withTab(t)),
                  onFilters: _openFilters,
                  onList: _showAsList,
                  onChanged: ctl.applyFilter,
                  onClearAll: ctl.clearFilters,
                ),
                const SizedBox(height: 8),
                if (s.isLoading)
                  const MapLoadingPill()
                else if (s.status == MapLoadStatus.error)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: MapMessageCard(
                      icon: Icons.cloud_off_rounded,
                      isError: true,
                      title: MapStrings.errorTitle,
                      message: s.errorMessage ?? 'Check your connection and try again.',
                      actionLabel: 'Retry',
                      onAction: ctl.retry,
                    ),
                  )
                else if (s.viewportChanged)
                  SearchThisAreaButton(onPressed: ctl.searchCurrentArea),
              ]),
            ),
          ),
        ),

        // ---- controls ----
        Positioned(
          right: 12,
          bottom: selected != null ? 236 : (s.status == MapLoadStatus.empty ? 150 : 52),
          child: MapControls(
            isLocating: s.isLocating,
            onZoomIn: () => _zoomBy(1),
            onZoomOut: () => _zoomBy(-1),
            onMyLocation: _locate,
          ),
        ),

        // ---- preview / empty state ----
        if (selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 36,
            child: SelectedPropertyPreview(
              key: ValueKey(selected.id),
              property: selected,
              onOpen: () => _openDetails(selected),
              onClose: ctl.clearSelection,
            ),
          )
        else if (s.status == MapLoadStatus.empty)
          Positioned(
            left: 12,
            right: 76,
            bottom: 36,
            child: MapMessageCard(
              icon: Icons.search_off_rounded,
              title: MapStrings.emptyTitle,
              message: MapStrings.emptyMessage,
              actionLabel: hasCriteria ? 'Clear filters' : null,
              onAction: ctl.clearFilters,
            ),
          ),
      ]),
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({
    required this.state,
    required this.onTab,
    required this.onFilters,
    required this.onList,
    required this.onChanged,
    required this.onClearAll,
  });

  final MapState state;
  final ValueChanged<ListingTab> onTab;
  final VoidCallback onFilters;
  final VoidCallback onList;
  final ValueChanged<PropertySearchFilter> onChanged;
  final VoidCallback onClearAll;

  String get _summary {
    final n = state.properties.length;
    final plus = state.truncated ? '+' : '';
    final noun = n == 1 && !state.truncated ? 'property' : 'properties';
    return switch (state.status) {
      MapLoadStatus.idle || MapLoadStatus.loading => state.properties.isEmpty ? MapStrings.loading : '$n$plus $noun',
      MapLoadStatus.empty => 'No properties here',
      MapLoadStatus.error => state.properties.isEmpty ? '' : '$n$plus $noun',
      MapLoadStatus.ready => state.truncated ? '$n+ $noun · zoom in for more' : '$n $noun on the map',
    };
  }

  @override
  Widget build(BuildContext context) {
    final f = state.filter;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Row(children: [
              Expanded(
                child: Text(_summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
              ),
              IconButton(tooltip: 'Show as list', onPressed: onList, icon: const Icon(Icons.view_agenda_outlined)),
              Badge(
                label: Text('${f.activeFilterCount}'),
                isLabelVisible: f.activeFilterCount > 0,
                child: IconButton(tooltip: 'Filters', onPressed: onFilters, icon: const Icon(Icons.tune_rounded)),
              ),
            ]),
          ),
          ListingTabBar(selected: f.tab, onSelected: onTab),
          if (f.hasQuery)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('“${f.queryText!.trim()}”', style: const TextStyle(fontSize: 12)),
                  onDeleted: () => onChanged(f.copyWith(queryText: null)),
                  deleteButtonTooltipMessage: 'Remove search text',
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFE8F0FE),
                  side: BorderSide.none,
                ),
              ),
            ),
          ActiveFilterChips(filter: f, onChanged: onChanged, onClearAll: onClearAll),
        ]),
      ),
    );
  }
}
