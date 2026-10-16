import '../../../search/domain/entities/property_search_filter.dart';
import '../entities/map_query_result.dart';
import '../entities/map_viewport.dart';

/// Throws [DiscoveryFailure] only.
abstract interface class MapRepository {
  /// PUBLISHED properties with valid coordinates inside [viewport] that satisfy ALL of
  /// [filter] (same matcher as Module 04). Bounded by [limit].
  Future<MapQueryResult> getPropertiesInViewport({
    required MapViewport viewport,
    PropertySearchFilter? filter,
    int limit = 150,
  });
}
