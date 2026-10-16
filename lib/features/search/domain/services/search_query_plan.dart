import '../../../properties/domain/entities/property.dart';
import '../entities/property_search_filter.dart';
import '../entities/search_enums.dart';

/// What the BACKEND is asked to do for a filter; everything else is applied on the
/// device by [SearchMatcher] while scanning pages in order.
///
/// Server side (kept small so only a handful of composite indexes are needed):
///   status == published
///   [transactionType ==]  [governorate ==]
///   orderBy `orderField`  (+ price / surface range when it is the order field)
///
/// Index shapes: (status, [transactionType], [governorate], orderField) for the three
/// order fields publishedAt / price / surface  =>  4 combinations x 3 = 12 indexes
/// (see firebase/firestore.indexes.json).
class SearchQueryPlan {
  const SearchQueryPlan({
    this.transactionType,
    this.governorate,
    required this.orderField,
    required this.descending,
    this.minPrice,
    this.maxPrice,
    this.minSurface,
    this.maxSurface,
  });

  final TransactionType? transactionType;
  final String? governorate;
  final String orderField;
  final bool descending;
  final double? minPrice;
  final double? maxPrice;
  final double? minSurface;
  final double? maxSurface;

  factory SearchQueryPlan.fromFilter(PropertySearchFilter f) {
    final (field, desc) = switch (f.sort) {
      SortOption.lowestPrice => ('price', false),
      SortOption.highestPrice => ('price', true),
      SortOption.largestSurface => ('surface', true),
      // newest, and the windowed sorts (they re-rank the newest matches)
      _ => ('publishedAt', true),
    };
    final gov = f.governorate?.trim();
    return SearchQueryPlan(
      transactionType: f.transactionType,
      governorate: (gov == null || gov.isEmpty) ? null : gov,
      orderField: field,
      descending: desc,
      minPrice: field == 'price' ? f.minPrice : null,
      maxPrice: field == 'price' ? f.maxPrice : null,
      minSurface: field == 'surface' ? f.minSurface : null,
      maxSurface: field == 'surface' ? f.maxSurface : null,
    );
  }
}
