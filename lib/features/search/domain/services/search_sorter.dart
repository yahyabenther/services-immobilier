import '../../../../core/utils/geo.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../property_discovery/domain/services/recommendation_ranker.dart';
import '../entities/property_search_filter.dart';
import '../entities/search_enums.dart';

class SortedWindow {
  const SortedWindow(this.items, this.distancesKm);
  final List<Property> items;
  final Map<String, double> distancesKm;
}

/// Device-side ordering for the two windowed sorts.
class SearchSorter {
  const SearchSorter._();

  /// Recommended = the Home ranking (recent + verified + popular).
  /// Closest = nearest first; listings without coordinates are left out because
  /// their distance cannot be known (never fabricated).
  static SortedWindow sortWindow(List<Property> window, PropertySearchFilter f, {required DateTime now}) {
    if (f.sort == SortOption.closest && f.hasReference) {
      final lat = f.referenceLatitude!;
      final lng = f.referenceLongitude!;
      final withDistance = [
        for (final p in window)
          if (p.hasCoordinates) (p: p, d: distanceKm(lat, lng, p.latitude!, p.longitude!)),
      ]..sort((a, b) {
          final c = a.d.compareTo(b.d);
          return c != 0 ? c : a.p.id.compareTo(b.p.id);
        });
      return SortedWindow(
        [for (final e in withDistance) e.p],
        {for (final e in withDistance) e.p.id: e.d},
      );
    }
    if (f.sort == SortOption.recommended) {
      return SortedWindow(RecommendationRanker.rank(window, now: now, limit: window.length), const {});
    }
    return SortedWindow(window, const {}); // already in server order (newest)
  }
}
