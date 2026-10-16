import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/properties/domain/entities/amenity.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/search/domain/entities/filter_validation.dart';
import 'package:team_app/features/search/domain/entities/property_search_filter.dart';
import 'package:team_app/features/search/domain/entities/search_enums.dart';

void main() {
  test('copyWith can clear a field with null and keeps it when omitted', () {
    final f = const PropertySearchFilter().copyWith(
      propertyType: PropertyType.villa,
      bedrooms: BedroomChoice.two,
      minPrice: 100000,
      governorate: 'Tunis',
    );
    expect(f.propertyType, PropertyType.villa);
    final kept = f.copyWith(minPrice: 200000);
    expect(kept.propertyType, PropertyType.villa);
    expect(kept.governorate, 'Tunis');

    final cleared = f.copyWith(propertyType: null, bedrooms: null, minPrice: null, governorate: null);
    expect(cleared.propertyType, isNull);
    expect(cleared.bedrooms, isNull);
    expect(cleared.minPrice, isNull);
    expect(cleared.governorate, isNull);
    expect(cleared.activeFilterCount, 0);
  });

  test('tabs change the real filter model', () {
    const f = PropertySearchFilter();
    expect(f.withTab(ListingTab.buy).transactionType, TransactionType.buy);
    expect(f.withTab(ListingTab.rent).transactionType, TransactionType.rent);
    final nb = f.withTab(ListingTab.buy).withTab(ListingTab.newBuild);
    expect(nb.newBuildOnly, isTrue);
    expect(nb.transactionType, isNull);
    expect(nb.tab, ListingTab.newBuild);
    expect(nb.withTab(ListingTab.all).newBuildOnly, isFalse);
    expect(nb.withTab(ListingTab.all).tab, ListingTab.all);
  });

  test('value equality incl. amenity sets', () {
    final a = const PropertySearchFilter().copyWith(amenities: {Amenity.pool, Amenity.garden});
    final b = const PropertySearchFilter().copyWith(amenities: {Amenity.garden, Amenity.pool});
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == a.copyWith(minPrice: 1), isFalse);
  });

  test('activeFilterCount counts each selected filter and each amenity', () {
    final f = const PropertySearchFilter().copyWith(
      propertyType: PropertyType.land,
      minPrice: 1,
      maxPrice: 2,
      amenities: {Amenity.pool, Amenity.parking},
    );
    expect(f.activeFilterCount, 5);
  });

  test('cleared() drops filters, tab and query but keeps sort and reference', () {
    final f = const PropertySearchFilter().copyWith(
      queryText: 'villa',
      propertyType: PropertyType.villa,
      sort: SortOption.closest,
      referenceLatitude: 36.8,
      referenceLongitude: 10.2,
    ).withTab(ListingTab.buy);
    final c = f.cleared();
    expect(c.hasQuery, isFalse);
    expect(c.activeFilterCount, 0);
    expect(c.tab, ListingTab.all);
    expect(c.sort, SortOption.closest);
    expect(c.hasReference, isTrue);
  });

  test('route parameters build the filter (Home shortcuts)', () {
    final buy = PropertySearchFilter.fromQueryParameters({'transactionType': 'buy'});
    expect(buy.transactionType, TransactionType.buy);
    final rent = PropertySearchFilter.fromQueryParameters({'transactionType': 'rent', 'governorate': 'Sousse'});
    expect(rent.transactionType, TransactionType.rent);
    expect(rent.governorate, 'Sousse');
    final rec = PropertySearchFilter.fromQueryParameters({'section': 'recommended'});
    expect(rec.sort, SortOption.recommended);
    final near = PropertySearchFilter.fromQueryParameters({'section': 'nearby', 'lat': '36.8', 'lng': '10.2'});
    expect(near.sort, SortOption.closest);
    expect(near.hasReference, isTrue);
    // nearby WITHOUT coordinates cannot be "closest"
    expect(PropertySearchFilter.fromQueryParameters({'section': 'nearby'}).sort, isNot(SortOption.closest));
    // junk is ignored
    expect(PropertySearchFilter.fromQueryParameters({'transactionType': 'swap', 'lat': 'x'}).isDefault, isTrue);
  });

  group('validation', () {
    test('min greater than max is an error', () {
      final e = FilterValidator.validate(const PropertySearchFilter(minPrice: 500, maxPrice: 100));
      expect(e.price, isNotNull);
      expect(e.hasErrors, isTrue);
    });
    test('negative values are errors', () {
      expect(FilterValidator.validate(const PropertySearchFilter(minSurface: -1)).surface, isNotNull);
    });
    test('valid / partial ranges pass', () {
      expect(FilterValidator.validate(const PropertySearchFilter(minPrice: 1, maxPrice: 1)).hasErrors, isFalse);
      expect(FilterValidator.validate(const PropertySearchFilter(maxSurface: 300)).hasErrors, isFalse);
    });
    test('closest needs a reference', () {
      expect(FilterValidator.canSortByClosest(const PropertySearchFilter()), isFalse);
      expect(
        FilterValidator.canSortByClosest(const PropertySearchFilter(referenceLatitude: 1, referenceLongitude: 2)),
        isTrue,
      );
    });
  });
}
