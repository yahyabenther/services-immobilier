import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:team_app/features/properties/data/property_mapper.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/publishing/data/property_write_mapper.dart';
import 'test_support.dart';

const _urls = ['https://res.cloudinary.com/demo/image/upload/a.jpg'];

void main() {
  group('PropertyWriteMapper.newListing', () {
    test('status is pending_review and the listing starts clean', () {
      final m = PropertyWriteMapper.newListing(draft: validDraft(), user: owner, imageUrls: _urls);
      expect(m['status'], 'pending_review');
      expect(m['verificationStatus'], 'not_submitted');
      expect(m['views'], 0);
      expect(m['favoritesCount'], 0);
      expect(m['publishedAt'], isNull);
      expect(m['createdAt'], isA<FieldValue>());
    });

    test('price and surface are numbers, currency is TND, wire values match the app enums', () {
      final m = PropertyWriteMapper.newListing(draft: validDraft().copyWith(priceText: '250 000'), user: owner, imageUrls: _urls);
      expect(m['price'], 250000);
      expect(m['surface'], isA<num>());
      expect(m['currency'], 'TND');
      expect(m['transactionType'], 'rent');
      expect(m['propertyType'], 'apartment');
      expect(m['images'], _urls);
      expect(m['amenities'], ['balcony', 'parking']);
    });

    test('owner vs agent identity', () {
      final o = PropertyWriteMapper.newListing(draft: validDraft(), user: owner, imageUrls: _urls);
      expect(o['ownerId'], 'u1');
      expect(o['agentId'], isNull);
      expect(o['ownerRole'], 'owner');
      final a = PropertyWriteMapper.newListing(draft: validDraft(), user: agent, imageUrls: _urls);
      expect(a['ownerId'], 'a1');
      expect(a['agentId'], 'a1');
      expect(a['ownerRole'], 'agent');
    });

    test('non-applicable fields are omitted, a studio has no bedrooms', () {
      final land = PropertyWriteMapper.newListing(draft: validDraft().copyWith(propertyType: PropertyType.land), user: owner, imageUrls: _urls);
      expect(land.containsKey('bedrooms'), isFalse);
      expect(land.containsKey('bathrooms'), isFalse);
      final studio = PropertyWriteMapper.newListing(draft: validDraft().copyWith(isStudio: true, bedrooms: 0), user: owner, imageUrls: _urls);
      expect(studio['isStudio'], isTrue);
      expect(studio.containsKey('bedrooms'), isFalse);
    });

    test('coordinates are written only when the user pinned the property', () {
      final none = PropertyWriteMapper.newListing(draft: validDraft().copyWith(clearCoordinates: true), user: owner, imageUrls: _urls);
      expect(none.containsKey('latitude'), isFalse);
      final pinned = PropertyWriteMapper.newListing(draft: validDraft(), user: owner, imageUrls: _urls);
      expect(pinned['latitude'], 36.88);
    });

    test('only keys allowed by firestore.rules (validNewListing)', () {
      const allowed = {
        'ownerId', 'agentId', 'ownerName', 'ownerRole', 'title', 'description', 'transactionType', 'propertyType',
        'price', 'currency', 'surface', 'bedrooms', 'bathrooms', 'isStudio', 'isNewBuild', 'governorate', 'city',
        'area', 'latitude', 'longitude', 'images', 'amenities', 'status', 'verificationStatus', 'views',
        'favoritesCount', 'createdAt', 'updatedAt', 'publishedAt',
      };
      final m = PropertyWriteMapper.newListing(draft: validDraft(), user: owner, imageUrls: _urls);
      expect(allowed.containsAll(m.keys), isTrue, reason: '${m.keys.toSet().difference(allowed)}');
    });

    test('round trip: the read mapper (Module 05) accepts what we write', () {
      final m = PropertyWriteMapper.newListing(draft: validDraft(), user: owner, imageUrls: _urls)
        ..['createdAt'] = DateTime(2026)
        ..['updatedAt'] = DateTime(2026);
      final p = PropertyMapper.tryFromMap('x', m);
      expect(p, isNotNull);
      expect(p!.status, PropertyStatus.pendingReview);
      expect(p.isPublic, isFalse); // never shown publicly before approval
      expect(p.governorate, 'Tunis');
      expect(p.city, 'La Marsa');
      expect(p.bedrooms, 2);
      expect(p.hasCoordinates, isTrue);
    });
  });
}
