import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/search_enums.dart';

/// All user-facing search strings in one place (easy to localise to French later).
class SearchStrings {
  SearchStrings._();

  static const emptyTitle = 'No properties match your search';
  static const emptyMessage = 'Try changing the filters or widening the search area.';
  static const emptyFeedTitle = 'No listings yet';
  static const emptyFeedMessage = 'New properties will appear here soon.';
  static const errorTitle = "The search couldn't be loaded";
  static const errorFallback = 'Check your connection and try again.';
}

extension ListingTabLabel on ListingTab {
  String get label => switch (this) {
        ListingTab.all => 'All',
        ListingTab.buy => 'Buy',
        ListingTab.rent => 'Rent',
        ListingTab.newBuild => 'New',
      };
}

extension PropertyTypeLabel on PropertyType {
  String get label => switch (this) {
        PropertyType.apartment => 'Apartment',
        PropertyType.villa => 'Villa',
        PropertyType.house => 'House',
        PropertyType.duplex => 'Duplex',
        PropertyType.triplex => 'Triplex',
        PropertyType.land => 'Land',
        PropertyType.office => 'Office',
        PropertyType.commercial => 'Commercial',
        PropertyType.industrial => 'Industrial',
        PropertyType.other => 'Other',
      };
}

/// Types offered in the filter panel (everything except the catch-all).
final searchablePropertyTypes = [
  for (final t in PropertyType.values)
    if (t != PropertyType.other) t,
];
