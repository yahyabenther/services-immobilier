import '../../../properties/domain/entities/property.dart';
/// One page of results.
class SearchResultPage {
  const SearchResultPage({
    required this.items,
    this.distancesKm = const {},
    this.nextCursor,
    this.hasMore = false,
  });

  final List<Property> items;

  /// property id -> distance in km. Only filled for a real reference location.
  final Map<String, double> distancesKm;

  /// Opaque token for the next page (the data layer decides what it is).
  final Object? nextCursor;
  final bool hasMore;
}
