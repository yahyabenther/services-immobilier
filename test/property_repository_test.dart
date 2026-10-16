import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/property_failure.dart';
import 'package:team_app/features/properties/data/property_remote_data_source.dart';
import 'package:team_app/features/properties/data/property_repository_impl.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/properties/domain/services/similar_property_ranker.dart';

import 'support_properties.dart';

RawPropertyDoc doc(String id, {String status = 'published', String tx = 'buy', String type = 'villa', num price = 100000, String? city, bool bad = false}) => (
      id: id,
      data: {
        'ownerId': 'o',
        if (!bad) 'title': 'T $id',
        'transactionType': tx,
        'propertyType': type,
        'price': price,
        'governorate': 'Tunis',
        'city': ?city,
        'status': status,
        'verificationStatus': 'approved',
        'publishedAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
      },
    );

class FakeDs implements PropertyRemoteDataSource {
  Map<String, RawPropertyDoc> byId = {};
  List<RawPropertyDoc> inGov = [];
  Object? error;

  @override
  Future<RawPropertyDoc?> getById(String id) async {
    if (error != null) throw error!;
    return byId[id];
  }

  @override
  Future<List<RawPropertyDoc>> fetchRecentInGovernorate(String g, {required int limit}) async => inGov;
}

void main() {
  late FakeDs ds;
  late PropertyRepositoryImpl repo;
  setUp(() {
    ds = FakeDs();
    repo = PropertyRepositoryImpl(ds);
  });


  test('getPropertyById returns a published property', () async {
    ds.byId['a'] = doc('a');
    final p = await repo.getPropertyById('a');
    expect(p.id, 'a');
  });

  test('missing id -> notFound', () async {
    await expectLater(repo.getPropertyById('nope'),
        throwsA(isA<PropertyFailure>().having((e) => e.type, 'type', PropertyFailureType.notFound)));
    await expectLater(repo.getPropertyById(' '),
        throwsA(isA<PropertyFailure>().having((e) => e.type, 'type', PropertyFailureType.notFound)));
  });

  test('unpublished or malformed -> unavailable (never shown)', () async {
    ds.byId['d'] = doc('d', status: 'draft');
    ds.byId['b'] = doc('b', bad: true);
    for (final id in ['d', 'b']) {
      await expectLater(repo.getPropertyById(id),
          throwsA(isA<PropertyFailure>().having((e) => e.type, 'type', PropertyFailureType.unavailable)));
    }
  });

  test('backend errors map to failure types', () async {
    ds.error = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    await expectLater(repo.getPropertyById('a'),
        throwsA(isA<PropertyFailure>().having((e) => e.type, 'type', PropertyFailureType.network)));
    ds.error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    await expectLater(repo.getPropertyById('a'),
        throwsA(isA<PropertyFailure>().having((e) => e.type, 'type', PropertyFailureType.unavailable)));
    ds.error = FirebaseException(plugin: 'cloud_firestore', code: 'weird');
    await expectLater(repo.getPropertyById('a'),
        throwsA(isA<PropertyFailure>().having((e) => e.type, 'type', PropertyFailureType.unknown)));
  });

  group('similar properties', () {
    test('never includes the property itself, other transactions or unpublished listings', () async {
      ds.inGov = [
        doc('self'),
        doc('same'),
        doc('rental', tx: 'rent'),
        doc('draft', status: 'draft'),
        doc('bad', bad: true),
      ];
      final current = makeProperty(id: 'self');
      final r = await repo.getSimilarProperties(current);
      expect(r.map((p) => p.id), ['same']);
    });

    test('same type and similar price rank first; respects the limit', () {
      final current = makeProperty(id: 'cur', type: PropertyType.villa, price: 100000, city: 'La Marsa');
      final cands = [
        makeProperty(id: 'otherType', type: PropertyType.land, price: 100000),
        makeProperty(id: 'best', type: PropertyType.villa, price: 110000, city: 'La Marsa'),
        makeProperty(id: 'sameTypeFar', type: PropertyType.villa, price: 900000),
      ];
      final r = SimilarPropertyRanker.rank(current, cands, limit: 2);
      expect(r.map((p) => p.id), ['best', 'sameTypeFar']);
    });
  });
}
