import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/search/domain/entities/filter_validation.dart';
import 'package:team_app/features/search/domain/entities/property_search_filter.dart';

// NOTE: replace `immofind` with the `name:` in your pubspec.yaml.
void main() {
  group('FilterValidator', () {
    test('accepts empty and ordered ranges', () {
      expect(FilterValidator.validate(const PropertySearchFilter()).hasErrors, isFalse);
      expect(FilterValidator.validate(const PropertySearchFilter(minPrice: 100, maxPrice: 200)).hasErrors, isFalse);
    });

    test('rejects min > max and negatives', () {
      final price = FilterValidator.validate(const PropertySearchFilter(minPrice: 300, maxPrice: 200));
      expect(price.price, isNotNull);
      final surface = FilterValidator.validate(const PropertySearchFilter(minSurface: -1));
      expect(surface.surface, isNotNull);
    });

    test('closest sort needs a reference location', () {
      expect(FilterValidator.canSortByClosest(const PropertySearchFilter()), isFalse);
      expect(
        FilterValidator.canSortByClosest(const PropertySearchFilter(referenceLatitude: 36.8, referenceLongitude: 10.1)),
        isTrue,
      );
    });

    test('cleared() keeps sort and reference only', () {
      const f = PropertySearchFilter(minPrice: 1, queryText: 'villa', referenceLatitude: 1, referenceLongitude: 2);
      final c = f.cleared();
      expect(c.minPrice, isNull);
      expect(c.queryText, isNull);
      expect(c.hasReference, isTrue);
    });
  });
}
