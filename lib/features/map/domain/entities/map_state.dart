import '../../../properties/domain/entities/property.dart';
import '../../../search/domain/entities/property_search_filter.dart';
import 'map_viewport.dart';

const _unset = Object();

/// idle -> loading -> ready | empty | error. While a new area is loading the previous
/// markers stay on screen (the map never goes blank).
enum MapLoadStatus { idle, loading, ready, empty, error }

class MapUserLocation {
  const MapUserLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class MapState {
  const MapState({
    this.filter = const PropertySearchFilter(),
    this.status = MapLoadStatus.idle,
    this.properties = const [],
    this.truncated = false,
    this.viewport,
    this.searchedViewport,
    this.selectedId,
    this.viewportChanged = false,
    this.isLocating = false,
    this.userLocation,
    this.errorMessage,
  });

  /// Criteria applied to every area search (same semantics as Module 04).
  final PropertySearchFilter filter;
  final MapLoadStatus status;

  /// Public listings with valid coordinates for [searchedViewport].
  final List<Property> properties;
  final bool truncated;

  /// Latest visible area (updated when the camera settles).
  final MapViewport? viewport;

  /// Area the current [properties] were loaded for.
  final MapViewport? searchedViewport;

  /// Selected listing by ID (never by marker index).
  final String? selectedId;

  /// The user moved/zoomed away from [searchedViewport]: show "Search this area".
  final bool viewportChanged;

  final bool isLocating;
  final MapUserLocation? userLocation;
  final String? errorMessage;

  bool get isLoading => status == MapLoadStatus.loading;

  Property? get selectedProperty {
    final id = selectedId;
    if (id == null) return null;
    for (final p in properties) {
      if (p.id == id) return p;
    }
    return null;
  }

  MapState copyWith({
    PropertySearchFilter? filter,
    MapLoadStatus? status,
    List<Property>? properties,
    bool? truncated,
    Object? viewport = _unset,
    Object? searchedViewport = _unset,
    Object? selectedId = _unset,
    bool? viewportChanged,
    bool? isLocating,
    Object? userLocation = _unset,
    Object? errorMessage = _unset,
  }) =>
      MapState(
        filter: filter ?? this.filter,
        status: status ?? this.status,
        properties: properties ?? this.properties,
        truncated: truncated ?? this.truncated,
        viewport: identical(viewport, _unset) ? this.viewport : viewport as MapViewport?,
        searchedViewport:
            identical(searchedViewport, _unset) ? this.searchedViewport : searchedViewport as MapViewport?,
        selectedId: identical(selectedId, _unset) ? this.selectedId : selectedId as String?,
        viewportChanged: viewportChanged ?? this.viewportChanged,
        isLocating: isLocating ?? this.isLocating,
        userLocation: identical(userLocation, _unset) ? this.userLocation : userLocation as MapUserLocation?,
        errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      );
}
