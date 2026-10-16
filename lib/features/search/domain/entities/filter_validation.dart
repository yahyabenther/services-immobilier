import 'property_search_filter.dart';

/// Field-level errors for the filter panel (spec §7.1). Null = valid.
class FilterErrors {
  const FilterErrors({this.price, this.surface});

  final String? price;
  final String? surface;

  bool get hasErrors => price != null || surface != null;
}

class FilterValidator {
  const FilterValidator._();

  static FilterErrors validate(PropertySearchFilter f) {
    String? range(double? min, double? max, String name) {
      if ((min != null && min < 0) || (max != null && max < 0)) return '$name cannot be negative';
      if (min != null && max != null && min > max) return 'Minimum $name must not exceed maximum';
      return null;
    }

    return FilterErrors(
      price: range(f.minPrice, f.maxPrice, 'price'),
      surface: range(f.minSurface, f.maxSurface, 'surface'),
    );
  }

  /// "closest" can only run with a real reference location.
  static bool canSortByClosest(PropertySearchFilter f) => f.hasReference;
}
