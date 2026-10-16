import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/discovery_failure.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../property_discovery/presentation/providers/property_discovery_providers.dart';
import '../../../search/domain/entities/property_search_filter.dart';
import '../../../search/providers/search_providers.dart';
import '../../data/map_property_data_source.dart';
import '../../data/map_repository_impl.dart';
import '../../domain/entities/map_state.dart';
import '../../domain/entities/map_viewport.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/services/map_filter_resolver.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_properties_in_viewport.dart';
import '../../map_config.dart';

// ---- infrastructure (override in tests) -----------------------------------
final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepositoryImpl(FirestoreMapDataSource(ref.watch(firestoreProvider))),
);

final getPropertiesInViewportProvider =
    Provider((ref) => GetPropertiesInViewport(ref.watch(mapRepositoryProvider)));

/// Uses the shared location service; permission is only asked when [call] runs.
final getCurrentLocationProvider = Provider((ref) => GetCurrentLocation(ref.watch(locationServiceProvider)));

final mapScreenProvider = NotifierProvider<MapScreenController, MapState>(MapScreenController.new);

/// Owns the map state (spec §7.2). Not auto-disposed: camera-independent state
/// (filters, results, selection) survives opening a property and coming back.
class MapScreenController extends Notifier<MapState> {
  int _seq = 0; // newest request wins
  String? _lastKey;
  PropertySearchFilter? _lastFilter;
  String? _pendingKey;
  PropertySearchFilter? _pendingFilter;

  @override
  MapState build() => const MapState();

  // ---- lifecycle ---------------------------------------------------------------
  /// The map widget is laid out: remember the visible area and load it.
  Future<void> onMapReady(MapViewport viewport) async {
    state = state.copyWith(viewport: viewport);
    await _search(viewport, state.filter);
  }

  /// Route entry (Home / Search): sets the filter only. The page moves the camera and
  /// then calls [searchCurrentArea], so one entry never fires two requests.
  void applyRouteParams(Map<String, String> params) {
    if (params.isEmpty) return;
    final next = resolveMapFilter(params, searchFilter: ref.read(searchResultsProvider).filter);
    if (next != state.filter) state = state.copyWith(filter: next);
  }

  // ---- camera ------------------------------------------------------------------
  /// Called when the camera has settled. [byUser] separates a pan/zoom gesture from a
  /// programmatic move (my location, cluster zoom, route entry): only the former can
  /// offer "Search this area".
  void onCameraIdle(MapViewport viewport, {required bool byUser}) {
    final searched = state.searchedViewport;
    var changed = state.viewportChanged;
    if (byUser && searched != null) {
      changed = !searched.containsViewport(viewport, tolerance: 0.1) ||
          (state.truncated && viewport.zoom > searched.zoom + 0.75);
    }
    state = state.copyWith(viewport: viewport, viewportChanged: changed);
  }

  Future<void> searchCurrentArea({bool force = false}) async {
    final vp = state.viewport;
    if (vp == null) return;
    await _search(vp, state.filter, force: force);
  }

  Future<void> retry() => searchCurrentArea(force: true);

  // ---- filters -------------------------------------------------------------------
  Future<void> applyFilter(PropertySearchFilter f) async {
    if (f == state.filter && state.status != MapLoadStatus.idle) return;
    state = state.copyWith(filter: f);
    final vp = state.viewport;
    if (vp != null) await _search(vp, f);
  }

  Future<void> clearFilters() => applyFilter(state.filter.cleared());

  // ---- selection (by ID, never by index) -------------------------------------------
  void selectProperty(String id) {
    if (state.properties.any((p) => p.id == id)) state = state.copyWith(selectedId: id);
  }

  void clearSelection() {
    if (state.selectedId != null) state = state.copyWith(selectedId: null);
  }

  // ---- current location --------------------------------------------------------------
  /// Null when a request is already running. The caller moves the camera and shows the
  /// message for failures; a failure never affects the property query.
  Future<LocateResult?> locateMe() async {
    if (state.isLocating) return null;
    state = state.copyWith(isLocating: true);
    final result = await ref.read(getCurrentLocationProvider)();
    state = result.isLocated
        ? state.copyWith(isLocating: false, userLocation: MapUserLocation(result.latitude!, result.longitude!))
        : state.copyWith(isLocating: false);
    return result;
  }

  // ---- query ---------------------------------------------------------------------------
  Future<void> _search(MapViewport vp, PropertySearchFilter f, {bool force = false}) async {
    if (!vp.isValid) return;
    final key = vp.cacheKey;

    if (!force) {
      final settled = state.status == MapLoadStatus.ready || state.status == MapLoadStatus.empty;
      if (settled && key == _lastKey && f == _lastFilter) {
        state = state.copyWith(viewportChanged: false); // same area + filters: nothing to fetch
        return;
      }
      if (state.isLoading && key == _pendingKey && f == _pendingFilter) return; // already in flight
    }

    final seq = ++_seq;
    _pendingKey = key;
    _pendingFilter = f;
    state = state.copyWith(filter: f, status: MapLoadStatus.loading, errorMessage: null);
    try {
      final result = await ref.read(getPropertiesInViewportProvider)(
        viewport: vp,
        filter: f,
        limit: mapPropertyLimit,
      );
      if (seq != _seq) return; // a newer request replaced this one
      final items = [
        for (final p in result.items)
          if (p.isPublic && p.hasCoordinates) p,
      ];
      _lastKey = key;
      _lastFilter = f;
      final selected = state.selectedId;
      final current = state.viewport ?? vp;
      state = state.copyWith(
        status: items.isEmpty ? MapLoadStatus.empty : MapLoadStatus.ready,
        properties: items,
        truncated: result.truncated,
        searchedViewport: vp,
        viewportChanged: !vp.containsViewport(current, tolerance: 0.1),
        // Selected listing no longer in the result set -> close the preview.
        selectedId: items.any((p) => p.id == selected) ? selected : null,
        errorMessage: null,
      );
    } on DiscoveryFailure catch (e) {
      if (seq != _seq) return;
      state = state.copyWith(status: MapLoadStatus.error, errorMessage: e.message);
    } catch (_) {
      if (seq != _seq) return;
      state = state.copyWith(
        status: MapLoadStatus.error,
        errorMessage: const DiscoveryFailure(DiscoveryFailureType.unknown).message,
      );
    }
  }
}
