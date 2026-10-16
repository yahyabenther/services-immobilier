import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/properties/data/property_mapper.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';

Map<String, dynamic> valid() => {
      'ownerId': 'o1',
      'title': 'Villa',
      'transactionType': 'buy',
      'propertyType': 'villa',
      'price': 850000,
      'governorate': 'Tunis',
      'status': 'published',
      'verificationStatus': 'approved',
    };

void main() {
  test('maps a valid document', () {
    final p = PropertyMapper.tryFromMap('id1', {
      ...valid(),
      'city': 'La Marsa',
      'area': 'Gammarth',
      'bedrooms': 4,
      'isNewBuild': true,
      'publishedAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
      'images': ['a.jpg', 5, ''],
    })!;
    expect(p.id, 'id1');
    expect(p.isVerified, isTrue);
    expect(p.isPublic, isTrue);
    expect(p.isNewBuild, isTrue);
    expect(p.currency, 'TND'); // default
    expect(p.images, ['a.jpg']); // junk entries dropped
    expect(p.locationLabel, 'Gammarth, Tunis');
    expect(p.publishedAt, DateTime(2026, 10, 1));
  });

  test('malformed required fields -> null (document skipped)', () {
    for (final key in ['title', 'price', 'governorate', 'ownerId', 'transactionType']) {
      final d = valid()..remove(key);
      expect(PropertyMapper.tryFromMap('x', d), isNull, reason: key);
    }
    expect(PropertyMapper.tryFromMap('x', {...valid(), 'price': 'cheap'}), isNull);
    expect(PropertyMapper.tryFromMap('x', {...valid(), 'price': -5}), isNull);
    expect(PropertyMapper.tryFromMap('x', {...valid(), 'transactionType': 'swap'}), isNull);
  });

  test('legacy documents: governorate falls back to a governorate-named city', () {
    final d = valid()..remove('governorate');
    final p = PropertyMapper.tryFromMap('x', {...d, 'city': 'Sousse'})!;
    expect(p.governorate, 'Sousse');
    expect(p.city, isNull); // same as governorate, no duplicate
    // ...but a non-governorate city is NOT guessed into a governorate
    expect(PropertyMapper.tryFromMap('x', {...d, 'city': 'La Marsa'}), isNull);
  });

  test('zero / missing facts become null, never "0 bedrooms"; studio is explicit', () {
    final p = PropertyMapper.tryFromMap('x', {...valid(), 'bedrooms': 0, 'surface': 0, 'isStudio': true})!;
    expect(p.bedrooms, isNull);
    expect(p.surface, isNull);
    expect(p.bathrooms, isNull);
    expect(p.isStudio, isTrue);
  });

  test('invalid coordinates are ignored', () {
    final p = PropertyMapper.tryFromMap('x', {...valid(), 'latitude': 999, 'longitude': 10})!;
    expect(p.hasCoordinates, isFalse);
  });

  test('unknown status never becomes public', () {
    final p = PropertyMapper.tryFromMap('x', {...valid(), 'status': 'weird'})!;
    expect(p.status, PropertyStatus.draft);
    expect(p.isPublic, isFalse);
  });

  test('verification: only approved shows the badge', () {
    bool badge(String v) => PropertyMapper.tryFromMap('x', {...valid(), 'verificationStatus': v})!.isVerified;
    expect(badge('approved'), isTrue);
    expect(badge('verified'), isTrue); // legacy alias
    for (final v in ['pending', 'rejected', 'expired', 'not_submitted', 'unverified', 'weird']) {
      expect(badge(v), isFalse, reason: v);
    }
  });

  test('"sale" is accepted as buy; pending_review parses', () {
    expect(TransactionType.parse('sale'), TransactionType.buy);
    expect(PropertyStatus.parse('pending_review'), PropertyStatus.pendingReview);
  });

  test('property types: new values parse, unknown -> other', () {
    expect(PropertyType.parse('duplex'), PropertyType.duplex);
    expect(PropertyType.parse('industrial'), PropertyType.industrial);
    expect(PropertyType.parse('castle'), PropertyType.other);
  });
}
