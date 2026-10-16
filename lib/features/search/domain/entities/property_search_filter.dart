import '../../../properties/domain/entities/amenity.dart';
import '../../../properties/domain/entities/property.dart';
import 'search_enums.dart';

const _unset = Object();

/// Everything the user can ask for. Immutable, with value equality.
///
/// Product decisions (see README):
/// - "New" = new-build property (`isNewBuild == true`), any transaction type.
/// - Several amenities use AND semantics (a listing must have every one).
/// - Rent prices are per month.
class PropertySearchFilter {
  const PropertySearchFilter({
    this.queryText,
    this.transactionType,
    this.newBuildOnly = false,
    this.propertyType,
    this.governorate,
    this.city,
    this.area,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.minSurface,
    this.maxSurface,
    this.amenities = const {},
    this.sort = SortOption.recommended,
    this.referenceLatitude,
    this.referenceLongitude,
  });

  final String? queryText;
  final TransactionType? transactionType;
  final bool newBuildOnly;
  final PropertyType? propertyType;
  final String? governorate;
  final String? city;
  final String? area;
  final double? minPrice;
  final double? maxPrice;
  final BedroomChoice? bedrooms;
  final BathroomChoice? bathrooms;
  final double? minSurface;
  final double? maxSurface;
  final Set<Amenity> amenities;
  final SortOption sort;

  /// Needed by [SortOption.closest]. Never fabricated.
  final double? referenceLatitude;
  final double? referenceLongitude;

  bool get hasReference => referenceLatitude != null && referenceLongitude != null;

  ListingTab get tab => newBuildOnly
      ? ListingTab.newBuild
      : switch (transactionType) {
          TransactionType.buy => ListingTab.buy,
          TransactionType.rent => ListingTab.rent,
          null => ListingTab.all,
        };

  /// copyWith that CAN set a field back to null: pass `null` explicitly to clear it,
  /// omit the argument to keep the current value.
  PropertySearchFilter copyWith({
    Object? queryText = _unset,
    Object? transactionType = _unset,
    bool? newBuildOnly,
    Object? propertyType = _unset,
    Object? governorate = _unset,
    Object? city = _unset,
    Object? area = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    Object? bedrooms = _unset,
    Object? bathrooms = _unset,
    Object? minSurface = _unset,
    Object? maxSurface = _unset,
    Set<Amenity>? amenities,
    SortOption? sort,
    Object? referenceLatitude = _unset,
    Object? referenceLongitude = _unset,
  }) {
    T? pick<T>(Object? v, T? current) => identical(v, _unset) ? current : v as T?;
    return PropertySearchFilter(
      queryText: pick<String>(queryText, this.queryText),
      transactionType: pick<TransactionType>(transactionType, this.transactionType),
      newBuildOnly: newBuildOnly ?? this.newBuildOnly,
      propertyType: pick<PropertyType>(propertyType, this.propertyType),
      governorate: pick<String>(governorate, this.governorate),
      city: pick<String>(city, this.city),
      area: pick<String>(area, this.area),
      minPrice: pick<double>(minPrice, this.minPrice),
      maxPrice: pick<double>(maxPrice, this.maxPrice),
      bedrooms: pick<BedroomChoice>(bedrooms, this.bedrooms),
      bathrooms: pick<BathroomChoice>(bathrooms, this.bathrooms),
      minSurface: pick<double>(minSurface, this.minSurface),
      maxSurface: pick<double>(maxSurface, this.maxSurface),
      amenities: amenities ?? this.amenities,
      sort: sort ?? this.sort,
      referenceLatitude: pick<double>(referenceLatitude, this.referenceLatitude),
      referenceLongitude: pick<double>(referenceLongitude, this.referenceLongitude),
    );
  }

  /// Select a tab: Buy/Rent set the transaction type, New = new-build (any
  /// transaction), All clears both.
  PropertySearchFilter withTab(ListingTab tab) => switch (tab) {
        ListingTab.all => copyWith(transactionType: null, newBuildOnly: false),
        ListingTab.buy => copyWith(transactionType: TransactionType.buy, newBuildOnly: false),
        ListingTab.rent => copyWith(transactionType: TransactionType.rent, newBuildOnly: false),
        ListingTab.newBuild => copyWith(transactionType: null, newBuildOnly: true),
      };

  /// Filters the user can see and remove (the tab, sort and reference are not counted).
  int get activeFilterCount =>
      [propertyType, governorate, city, area, minPrice, maxPrice, bedrooms, bathrooms, minSurface, maxSurface]
          .where((e) => e != null)
          .length +
      amenities.length;

  bool get hasQuery => (queryText ?? '').trim().isNotEmpty;

  /// True when nothing narrows the results (the default published feed).
  bool get isDefault =>
      !hasQuery && tab == ListingTab.all && activeFilterCount == 0 && sort == SortOption.recommended;

  /// Clears everything the user selected but keeps sort and reference location.
  PropertySearchFilter cleared() => PropertySearchFilter(
        sort: sort,
        referenceLatitude: referenceLatitude,
        referenceLongitude: referenceLongitude,
      );

  // ---- deep links (Home -> /search?...) --------------------------------------
  /// Builds a filter from route query parameters. Unknown values are ignored.
  static PropertySearchFilter fromQueryParameters(Map<String, String> q, {PropertySearchFilter? base}) {
    var f = base ?? const PropertySearchFilter();
    final tx = TransactionType.parse(q['transactionType']);
    if (tx != null) f = f.withTab(tx == TransactionType.buy ? ListingTab.buy : ListingTab.rent);
    if (q['tab'] == 'new') f = f.withTab(ListingTab.newBuild);
    final gov = q['governorate'];
    if (gov != null && gov.trim().isNotEmpty) f = f.copyWith(governorate: gov.trim());
    final lat = double.tryParse(q['lat'] ?? '');
    final lng = double.tryParse(q['lng'] ?? '');
    if (lat != null && lng != null) f = f.copyWith(referenceLatitude: lat, referenceLongitude: lng);
    switch (q['section']) {
      case 'recommended':
        f = f.copyWith(sort: SortOption.recommended);
      case 'nearby':
        if (f.hasReference) f = f.copyWith(sort: SortOption.closest);
    }
    return f;
  }

  @override
  bool operator ==(Object other) =>
      other is PropertySearchFilter &&
      other.queryText == queryText &&
      other.transactionType == transactionType &&
      other.newBuildOnly == newBuildOnly &&
      other.propertyType == propertyType &&
      other.governorate == governorate &&
      other.city == city &&
      other.area == area &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.bedrooms == bedrooms &&
      other.bathrooms == bathrooms &&
      other.minSurface == minSurface &&
      other.maxSurface == maxSurface &&
      other.sort == sort &&
      other.referenceLatitude == referenceLatitude &&
      other.referenceLongitude == referenceLongitude &&
      other.amenities.length == amenities.length &&
      other.amenities.containsAll(amenities);

  @override
  int get hashCode => Object.hash(
        queryText,
        transactionType,
        newBuildOnly,
        propertyType,
        governorate,
        city,
        area,
        minPrice,
        maxPrice,
        bedrooms,
        bathrooms,
        minSurface,
        maxSurface,
        sort,
        referenceLatitude,
        referenceLongitude,
        Object.hashAllUnordered(amenities),
      );
}
