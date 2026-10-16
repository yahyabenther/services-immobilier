import '../entities/property_search_filter.dart';
import '../entities/search_result_page.dart';

/// Throws [DiscoveryFailure] only.
abstract interface class SearchRepository {
  /// Returns every property of the page that satisfies ALL of [filter].
  /// For windowed sorts (Recommended, Closest) the whole ranked window is returned
  /// in the first call and [SearchResultPage.hasMore] is false.
  Future<SearchResultPage> search(
    PropertySearchFilter filter, {
    Object? cursor,
    int pageSize = 20,
  });
}
