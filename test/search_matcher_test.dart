import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/utils/text_normalizer.dart';
import 'package:team_app/features/properties/domain/entities/amenity.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/search/domain/entities/property_search_filter.dart';
import 'package:team_app/features/search/domain/entities/search_enums.dart';
import 'package:team_app/features/search/domain/services/search_matcher.dart';
import 'package:team_app/features/search/domain/services/search_query_plan.dart';
import 'package:team_app/features/search/domain/services/search_sorter.dart';

import 'support_properties.dart';

bool m(Property p, PropertySearchFilter f) => SearchMatcher.matches(p, f);

void main() {
  const base = PropertySearchFilter();

  test('an empty filter matches everything', () => expect(m(makeProperty(), base), isTrue));

  group('transaction / new / type', () {
    test('buy vs rent', () {
      expect(m(makeProperty(tx: TransactionType.rent), base.withTab(ListingTab.buy)), isFalse);
      expect(m(makeProperty(tx: TransactionType.rent), base.withTab(ListingTab.rent)), isTrue);
    });
    test('New = new-build, any transaction', () {
      final f = base.withTab(ListingTab.newBuild);
      expect(m(makeProperty(isNewBuild: true, tx: TransactionType.rent), f), isTrue);
      expect(m(makeProperty(isNewBuild: false), f), isFalse);
    });
    test('property type', () {
      final f = base.copyWith(propertyType: PropertyType.land);
      expect(m(makeProperty(type: PropertyType.land), f), isTrue);
      expect(m(makeProperty(type: PropertyType.villa), f), isFalse);
    });
  });

  group('location (case and accent insensitive)', () {
    test('governorate must be the same', () {
      final f = base.copyWith(governorate: 'béja');
      expect(m(makeProperty(governorate: 'Béja'), f), isTrue);
      expect(m(makeProperty(governorate: 'Beja'), f), isTrue);
      expect(m(makeProperty(governorate: 'Tunis'), f), isFalse);
    });
    test('city / area match by containment; unknown city never matches', () {
      expect(m(makeProperty(city: 'La Marsa'), base.copyWith(city: 'marsa')), isTrue);
      expect(m(makeProperty(city: null), base.copyWith(city: 'marsa')), isFalse);
      expect(m(makeProperty(area: 'Sidi Bou Said'), base.copyWith(area: 'sidi bou')), isTrue);
      expect(m(makeProperty(area: null), base.copyWith(area: 'sidi')), isFalse);
    });
  });

  group('price and surface', () {
    test('price bounds are inclusive', () {
      final f = base.copyWith(minPrice: 100, maxPrice: 200);
      expect(m(makeProperty(price: 100), f), isTrue);
      expect(m(makeProperty(price: 200), f), isTrue);
      expect(m(makeProperty(price: 99), f), isFalse);
      expect(m(makeProperty(price: 201), f), isFalse);
    });
    test('unknown surface never matches a surface filter', () {
      expect(m(makeProperty(surface: null), base.copyWith(minSurface: 50)), isFalse);
      expect(m(makeProperty(surface: 80), base.copyWith(minSurface: 50, maxSurface: 100)), isTrue);
      expect(m(makeProperty(surface: 120), base.copyWith(maxSurface: 100)), isFalse);
    });
  });

  group('bedrooms / bathrooms', () {
    test('studio is NOT zero bedrooms of other listings', () {
      final studio = makeProperty(isStudio: true, bedrooms: null);
      final f = base.copyWith(bedrooms: BedroomChoice.studio);
      expect(m(studio, f), isTrue);
      expect(m(makeProperty(bedrooms: 2), f), isFalse);
      expect(m(makeProperty(bedrooms: null), f), isFalse); // unknown is not a studio
      expect(m(studio, base.copyWith(bedrooms: BedroomChoice.one)), isFalse);
    });
    test('exact counts and 4+', () {
      expect(m(makeProperty(bedrooms: 2), base.copyWith(bedrooms: BedroomChoice.two)), isTrue);
      expect(m(makeProperty(bedrooms: 3), base.copyWith(bedrooms: BedroomChoice.two)), isFalse);
      expect(m(makeProperty(bedrooms: 4), base.copyWith(bedrooms: BedroomChoice.fourPlus)), isTrue);
      expect(m(makeProperty(bedrooms: 7), base.copyWith(bedrooms: BedroomChoice.fourPlus)), isTrue);
      expect(m(makeProperty(bedrooms: 3), base.copyWith(bedrooms: BedroomChoice.fourPlus)), isFalse);
    });
    test('listings without bedroom info are excluded by a bedroom filter (nothing invented)', () {
      expect(m(makeProperty(bedrooms: null), base.copyWith(bedrooms: BedroomChoice.one)), isFalse);
    });
    test('bathrooms', () {
      expect(m(makeProperty(bathrooms: 3), base.copyWith(bathrooms: BathroomChoice.threePlus)), isTrue);
      expect(m(makeProperty(bathrooms: 2), base.copyWith(bathrooms: BathroomChoice.threePlus)), isFalse);
      expect(m(makeProperty(bathrooms: null), base.copyWith(bathrooms: BathroomChoice.one)), isFalse);
    });
  });

  test('amenities use AND semantics', () {
    final p = makeProperty(amenities: ['pool', 'garden']);
    expect(m(p, base.copyWith(amenities: {Amenity.pool})), isTrue);
    expect(m(p, base.copyWith(amenities: {Amenity.pool, Amenity.garden})), isTrue);
    expect(m(p, base.copyWith(amenities: {Amenity.pool, Amenity.parking})), isFalse);
  });

  group('text query', () {
    test('all words must appear in title / location / type', () {
      final p = makeProperty(title: 'Villa avec piscine', city: 'La Marsa');
      expect(m(p, base.copyWith(queryText: 'marsa piscine')), isTrue);
      expect(m(p, base.copyWith(queryText: 'VILLA')), isTrue);
      expect(m(p, base.copyWith(queryText: 'marsa garage')), isFalse);
    });
    test('accents are ignored', () {
      final p = makeProperty(title: 'Maison à Gabès', governorate: 'Gabès', city: null);
      expect(m(p, base.copyWith(queryText: 'maison a gabes')), isTrue);
    });
    test('blank query matches', () => expect(m(makeProperty(), base.copyWith(queryText: '  ')), isTrue));
  });

  test('combined filters must ALL hold', () {
    final f = base.withTab(ListingTab.buy).copyWith(
          propertyType: PropertyType.villa,
          minPrice: 500000,
          bedrooms: BedroomChoice.fourPlus,
          amenities: {Amenity.pool},
        );
    final ok = makeProperty(price: 850000, bedrooms: 4, amenities: ['pool']);
    expect(m(ok, f), isTrue);
    expect(m(makeProperty(price: 400000, bedrooms: 4, amenities: ['pool']), f), isFalse);
    expect(m(makeProperty(price: 850000, bedrooms: 4, amenities: []), f), isFalse);
  });

  group('text normalizer', () {
    test('lowercase, accents, spaces', () {
      expect(TextNormalizer.normalize('  Béja  Nord '), 'beja nord');
      expect(TextNormalizer.normalize(null), '');
      expect(TextNormalizer.tokens('La  Marsa'), ['la', 'marsa']);
    });
  });

  group('query plan', () {
    test('newest / recommended / closest are served by publishedAt desc', () {
      for (final s in [SortOption.newest, SortOption.recommended, SortOption.closest]) {
        final p = SearchQueryPlan.fromFilter(base.copyWith(sort: s));
        expect(p.orderField, 'publishedAt');
        expect(p.descending, isTrue);
      }
    });
    test('price sorts push the price range to the server; others do not', () {
      final p = SearchQueryPlan.fromFilter(base.copyWith(sort: SortOption.lowestPrice, minPrice: 1, maxPrice: 9));
      expect(p.orderField, 'price');
      expect(p.descending, isFalse);
      expect(p.minPrice, 1);
      final n = SearchQueryPlan.fromFilter(base.copyWith(sort: SortOption.newest, minPrice: 1, maxPrice: 9));
      expect(n.minPrice, isNull);
      expect(SearchQueryPlan.fromFilter(base.copyWith(sort: SortOption.highestPrice)).descending, isTrue);
    });
    test('surface sort', () {
      final p = SearchQueryPlan.fromFilter(base.copyWith(sort: SortOption.largestSurface, minSurface: 50));
      expect(p.orderField, 'surface');
      expect(p.minSurface, 50);
    });
    test('only transaction type and governorate are server-side equality filters', () {
      final p = SearchQueryPlan.fromFilter(
        base.withTab(ListingTab.rent).copyWith(governorate: ' Tunis ', city: 'x', propertyType: PropertyType.villa),
      );
      expect(p.transactionType, TransactionType.rent);
      expect(p.governorate, 'Tunis');
    });
  });

  group('sorter', () {
    final now = DateTime(2026, 10, 10);
    test('closest: nearest first, distances filled, no-coordinate listings left out', () {
      final window = [
        makeProperty(id: 'far', lat: 36.95, lng: 10.20),
        makeProperty(id: 'near', lat: 36.805, lng: 10.20),
        makeProperty(id: 'none'),
      ];
      final f = base.copyWith(sort: SortOption.closest, referenceLatitude: 36.80, referenceLongitude: 10.20);
      final r = SearchSorter.sortWindow(window, f, now: now);
      expect(r.items.map((p) => p.id), ['near', 'far']);
      expect(r.distancesKm['near'], lessThan(1));
      expect(r.distancesKm.containsKey('none'), isFalse);
    });
    test('recommended uses the Home ranking (approved first)', () {
      final window = [
        makeProperty(id: 'plain', verification: VerificationStatus.notSubmitted, publishedAt: now),
        makeProperty(id: 'ok', verification: VerificationStatus.approved, publishedAt: now),
      ];
      final r = SearchSorter.sortWindow(window, base.copyWith(sort: SortOption.recommended), now: now);
      expect(r.items.first.id, 'ok');
    });
  });
}
