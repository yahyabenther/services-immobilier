import 'package:flutter_test/flutter_test.dart';

import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/publishing/domain/entities/listing_draft.dart';
import 'package:team_app/features/publishing/domain/photo_rules.dart';
import 'package:team_app/features/publishing/domain/services/listing_validator.dart';
import 'test_support.dart';

void main() {
  group('ListingValidator', () {
    test('a complete draft has no errors', () {
      expect(ListingValidator.validate(validDraft()), isEmpty);
    });

    test('title and description are required and trimmed', () {
      final e = ListingValidator.validate(validDraft().copyWith(title: '   ', description: '\n  '));
      expect(e.keys, containsAll([ListingField.title, ListingField.description]));
    });

    test('title / description length limits', () {
      expect(ListingValidator.validate(validDraft().copyWith(title: 'abc')).containsKey(ListingField.title), isTrue);
      expect(ListingValidator.validate(validDraft().copyWith(title: 'x' * 101)).containsKey(ListingField.title), isTrue);
      expect(ListingValidator.validate(validDraft().copyWith(description: 'too short')).containsKey(ListingField.description), isTrue);
    });

    test('price must be a whole number strictly greater than zero', () {
      for (final bad in ['', '0', '000', 'abc', '12.5', '1e5', '-5']) {
        expect(ListingValidator.validate(validDraft().copyWith(priceText: bad)).containsKey(ListingField.price), isTrue, reason: bad);
      }
      expect(ListingValidator.validate(validDraft().copyWith(priceText: '250 000')), isEmpty);
    });

    test('surface accepts , or . decimals and rejects zero / garbage', () {
      expect(ListingValidator.parseSurface('120,5'), 120.5);
      expect(ListingValidator.parseSurface('120.5'), 120.5);
      expect(ListingValidator.parseSurface('1,200.5'), isNull);
      for (final bad in ['', '0', '0,0', 'x', '-3']) {
        expect(ListingValidator.validate(validDraft().copyWith(surfaceText: bad)).containsKey(ListingField.surface), isTrue, reason: bad);
      }
    });

    test('at least one photo, at most ten', () {
      expect(ListingValidator.validate(validDraft(photos: [])).containsKey(ListingField.photos), isTrue);
      final eleven = [for (var i = 0; i < 11; i++) photo('p$i')];
      expect(ListingValidator.validate(validDraft(photos: eleven)).containsKey(ListingField.photos), isTrue);
    });

    test('type and transaction are required', () {
      final e = ListingValidator.validate(const ListingDraft());
      expect(e.keys, containsAll([ListingField.propertyType, ListingField.transactionType, ListingField.governorate, ListingField.city]));
    });

    test('unknown governorate is rejected', () {
      expect(ListingValidator.validate(validDraft().copyWith(governorate: 'Atlantis')).containsKey(ListingField.governorate), isTrue);
    });

    test('pin outside Tunisia is rejected, no pin is fine', () {
      expect(ListingValidator.validate(validDraft().copyWith(coordinates: const ListingCoordinates(48.8, 2.3))).containsKey(ListingField.coordinates), isTrue);
      expect(ListingValidator.validate(validDraft().copyWith(clearCoordinates: true)), isEmpty);
    });

    test('rooms: land has none, studio needs no bedroom, villa needs bedrooms + bathroom', () {
      final land = validDraft().copyWith(propertyType: PropertyType.land, bedrooms: 0, bathrooms: 0);
      expect(ListingValidator.validate(land), isEmpty);

      final studio = validDraft().copyWith(isStudio: true, bedrooms: 0);
      expect(ListingValidator.validate(studio), isEmpty);

      final villa = validDraft().copyWith(propertyType: PropertyType.villa, bedrooms: 0);
      expect(ListingValidator.validate(villa).containsKey(ListingField.bedrooms), isTrue);
      expect(ListingValidator.validate(validDraft().copyWith(bathrooms: 0)).containsKey(ListingField.bathrooms), isTrue);
    });

    test('unknown amenity is rejected', () {
      expect(ListingValidator.validate(validDraft().copyWith(amenities: {'jacuzzi'})).containsKey(ListingField.amenities), isTrue);
    });

    test('validateStep only reports the errors of that screen', () {
      const empty = ListingDraft();
      final type = ListingValidator.validateStep(PublishStep.type, empty);
      expect(type.keys.toSet(), {ListingField.propertyType, ListingField.transactionType});
      expect(ListingValidator.validateStep(PublishStep.amenities, empty), isEmpty);
      expect(ListingValidator.validateStep(PublishStep.preview, empty).length, greaterThan(5));
    });
  });

  group('PhotoRules', () {
    test('accepts jpg / png / webp by extension or mime type', () {
      expect(PhotoRules.check(name: 'a.JPG', length: 100), isNull);
      expect(PhotoRules.check(name: 'a.webp', length: 100), isNull);
      expect(PhotoRules.check(name: 'image_picker_123', mimeType: 'image/png', length: 100), isNull);
    });
    test('rejects other formats, empty and oversized files', () {
      expect(PhotoRules.check(name: 'a.gif', length: 100), isNotNull);
      expect(PhotoRules.check(name: 'a.pdf', mimeType: 'application/pdf', length: 100), isNotNull);
      expect(PhotoRules.check(name: 'a.jpg', length: 0), isNotNull);
      expect(PhotoRules.check(name: 'a.jpg', length: 5 * 1024 * 1024 + 1), isNotNull);
      expect(PhotoRules.check(name: 'a.jpg', length: 5 * 1024 * 1024), isNull);
    });
  });

  test('step order matches the journey', () {
    expect(PublishStep.type.previous, isNull);
    expect(PublishStep.type.next, PublishStep.location);
    expect(PublishStep.preview.next, isNull);
  });
}
