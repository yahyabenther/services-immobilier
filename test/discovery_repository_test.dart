import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/discovery_failure.dart';
import 'package:team_app/features/property_discovery/data/datasources/property_discovery_remote_data_source.dart';
import 'package:team_app/features/property_discovery/data/repositories/property_discovery_repository_impl.dart';
import 'package:team_app/features/property_discovery/domain/entities/discovery_location.dart';

RawProperty raw(String id, {String status = 'published', double? lat, double? lng, bool malformed = false, String governorate = 'Tunis', String verification = 'not_submitted', int views = 0}) => (
      id: id,
      data: {
        'ownerId': 'o',
        if (!malformed) 'title': 'T $id',
        'transactionType': 'buy',
        'propertyType': 'house',
        'price': 100000,
        'governorate': governorate,
        'status': status,
        'verificationStatus': verification,
        'views': views,
        'publishedAt': Timestamp.fromDate(DateTime(2026, 10, 9)),
        'latitude': ?lat,
        'longitude': ?lng,
      },
    );

class FakeDataSource implements PropertyDiscoveryRemoteDataSource {
  List<RawProperty> recent = [];
  List<RawProperty> inGovernorate = [];
  List<RawProperty> band = [];
  Object? error;

  @override
  Future<List<RawProperty>> fetchRecent({required int limit}) async {
    if (error != null) throw error!;
    return recent;
  }

  @override
  Future<List<RawProperty>> fetchRecentInGovernorate(String g, {required int limit}) async => inGovernorate;

  @override
  Future<List<RawProperty>> fetchInLatitudeBand(double minLat, double maxLat, {required int limit}) async => band;
}

void main() {
  late FakeDataSource ds;
  late PropertyDiscoveryRepositoryImpl repo;

  setUp(() {
    ds = FakeDataSource();
    repo = PropertyDiscoveryRepositoryImpl(ds, clock: () => DateTime(2026, 10, 10));
  });

  test('non-public listings are excluded even if the query returns them', () async {
    ds.recent = [raw('ok'), raw('draft', status: 'draft'), raw('exp', status: 'expired'), raw('pend', status: 'pending_review')];
    final r = await repo.getRecommendedProperties();
    expect(r.map((p) => p.id), ['ok']);
  });

  test('malformed documents are skipped, not fatal', () async {
    ds.recent = [raw('bad', malformed: true), raw('ok')];
    expect((await repo.getRecommendedProperties()).map((p) => p.id), ['ok']);
  });

  test('recommended follows the documented ranking (verified first)', () async {
    ds.recent = [raw('plain'), raw('verified', verification: 'approved')];
    expect((await repo.getRecommendedProperties()).first.id, 'verified');
  });

  test('limit is applied', () async {
    ds.recent = [for (var i = 0; i < 20; i++) raw('p$i')];
    expect((await repo.getRecommendedProperties(limit: 4)).length, 4);
  });

  test('nearby by device: filters by real distance and sorts nearest first', () async {
    ds.band = [
      raw('far', lat: 36.95, lng: 10.20), // ~15 km north: outside 10 km
      raw('mid', lat: 36.84, lng: 10.20), // ~4.4 km
      raw('near', lat: 36.805, lng: 10.20), // ~0.5 km
      raw('nocoords'),
    ];
    final r = await repo.getNearbyProperties(
      location: const DiscoveryLocation.device(latitude: 36.80, longitude: 10.20),
    );
    expect(r.map((p) => p.id), ['near', 'mid']);
  });

  test('nearby by governorate uses the governorate query', () async {
    ds.inGovernorate = [raw('c1'), raw('c2', status: 'draft')];
    final r = await repo.getNearbyProperties(location: const DiscoveryLocation.governorate('Tunis'));
    expect(r.map((p) => p.id), ['c1']);
  });

  test('backend errors become DiscoveryFailure, never raw Firebase errors', () async {
    ds.error = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable', message: 'RAW');
    await expectLater(
      repo.getRecommendedProperties(),
      throwsA(isA<DiscoveryFailure>().having((e) => e.type, 'type', DiscoveryFailureType.network)),
    );
    ds.error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    await expectLater(
      repo.getRecommendedProperties(),
      throwsA(isA<DiscoveryFailure>().having((e) => e.type, 'type', DiscoveryFailureType.permissionDenied)),
    );
  });
}
