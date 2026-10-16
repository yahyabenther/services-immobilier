import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/discovery_failure.dart';
import 'package:team_app/features/properties/data/property_remote_data_source.dart' show RawPropertyDoc;
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/search/data/datasources/firestore_search_datasource.dart';
import 'package:team_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:team_app/features/search/domain/entities/property_search_filter.dart';
import 'package:team_app/features/search/domain/entities/search_enums.dart';
import 'package:team_app/features/search/domain/services/search_query_plan.dart';

RawPropertyDoc rawDoc(
  String id, {
  String tx = 'buy',
  String type = 'apartment',
  String governorate = 'Tunis',
  String status = 'published',
  String verification = 'not_submitted',
  num price = 100000,
  bool malformed = false,
  double? lat,
  double? lng,
  int days = 1,
}) =>
    (
      id: id,
      data: {
        'ownerId': 'o',
        if (!malformed) 'title': 'T $id',
        'transactionType': tx,
        'propertyType': type,
        'price': price,
        'governorate': governorate,
        'status': status,
        'verificationStatus': verification,
        'publishedAt': Timestamp.fromDate(DateTime(2026, 10, 10).subtract(Duration(days: days))),
        'latitude': ?lat,
        'longitude': ?lng,
      },
    );

/// Emulates the backend: equality filters of the plan, then slices by cursor (an int offset).
class FakeSearchDataSource implements SearchDataSource {
  FakeSearchDataSource(this.all);
  final List<RawPropertyDoc> all;
  int calls = 0;
  Object? error;
  SearchQueryPlan? lastPlan;

  @override
  Future<RawSearchBatch> fetchBatch(SearchQueryPlan plan, {Object? cursor, required int batchSize}) async {
    calls++;
    lastPlan = plan;
    if (error != null) throw error!;
    final filtered = all.where((d) {
      if (plan.transactionType != null && d.data['transactionType'] != plan.transactionType!.name) return false;
      if (plan.governorate != null && d.data['governorate'] != plan.governorate) return false;
      return true;
    }).toList();
    final start = (cursor as int?) ?? 0;
    final slice = filtered.skip(start).take(batchSize).toList();
    return RawSearchBatch(docs: slice, lastCursor: start + slice.length, exhausted: slice.length < batchSize);
  }
}

void main() {
  final now = DateTime(2026, 10, 10);
  SearchRepositoryImpl repoOf(FakeSearchDataSource ds) => SearchRepositoryImpl(ds, clock: () => now);
  const newest = PropertySearchFilter(sort: SortOption.newest);

  test('pages without duplicates or gaps until exhausted', () async {
    final ds = FakeSearchDataSource([for (var i = 0; i < 50; i++) rawDoc('p$i')]);
    final repo = repoOf(ds);

    final p1 = await repo.search(newest, pageSize: 20);
    expect(p1.items.length, 20);
    expect(p1.hasMore, isTrue);
    final p2 = await repo.search(newest, cursor: p1.nextCursor, pageSize: 20);
    final p3 = await repo.search(newest, cursor: p2.nextCursor, pageSize: 20);
    expect(p3.hasMore, isFalse);

    final ids = [...p1.items, ...p2.items, ...p3.items].map((p) => p.id).toList();
    expect(ids.length, 50);
    expect(ids.toSet().length, 50);
    expect(ids, [for (var i = 0; i < 50; i++) 'p$i']);
  });

  test('device-side filters keep scanning until the page is filled, results all match', () async {
    final docs = [
      for (var i = 0; i < 100; i++) rawDoc('p$i', type: i % 10 == 0 ? 'land' : 'apartment'),
    ];
    final ds = FakeSearchDataSource(docs);
    final page = await repoOf(ds).search(newest.copyWith(propertyType: PropertyType.land), pageSize: 20);
    expect(page.items.length, 10); // every 10th document, 100 scanned
    expect(page.items.every((p) => p.propertyType == PropertyType.land), isTrue);
    expect(page.hasMore, isFalse); // the end was reached
  });

  test('the scan is capped so one request cannot read the whole collection', () async {
    final ds = FakeSearchDataSource([for (var i = 0; i < 1000; i++) rawDoc('p$i')]);
    final page = await repoOf(ds).search(newest.copyWith(propertyType: PropertyType.land), pageSize: 20);
    expect(page.items, isEmpty);
    expect(page.hasMore, isTrue); // more exists: the UI offers "Load more"
    expect(ds.calls, lessThanOrEqualTo(8));
    // continuing from the cursor keeps going
    final next = await repoOf(ds).search(newest.copyWith(propertyType: PropertyType.land),
        cursor: page.nextCursor, pageSize: 20);
    expect(next.hasMore, isTrue);
  });

  test('transaction type and governorate are sent to the backend plan', () async {
    final ds = FakeSearchDataSource([
      rawDoc('a', tx: 'rent', governorate: 'Sousse'),
      rawDoc('b', tx: 'buy', governorate: 'Sousse'),
      rawDoc('c', tx: 'rent', governorate: 'Tunis'),
    ]);
    final f = newest.withTab(ListingTab.rent).copyWith(governorate: 'Sousse');
    final page = await repoOf(ds).search(f);
    expect(page.items.map((p) => p.id), ['a']);
    expect(ds.lastPlan!.transactionType, TransactionType.rent);
    expect(ds.lastPlan!.governorate, 'Sousse');
  });

  test('non-public and malformed documents never reach the results', () async {
    final ds = FakeSearchDataSource([
      rawDoc('ok'),
      rawDoc('draft', status: 'draft'),
      rawDoc('pending', status: 'pending_review'),
      rawDoc('expired', status: 'expired'),
      rawDoc('bad', malformed: true),
    ]);
    final page = await repoOf(ds).search(newest);
    expect(page.items.map((p) => p.id), ['ok']);
  });

  test('Recommended: ranked window, approved listings first, no further pages', () async {
    final ds = FakeSearchDataSource([
      rawDoc('plain', days: 1),
      rawDoc('approved', verification: 'approved', days: 1),
    ]);
    final page = await repoOf(ds).search(const PropertySearchFilter(sort: SortOption.recommended));
    expect(page.items.first.id, 'approved');
    expect(page.hasMore, isFalse);
    expect(page.nextCursor, isNull);
  });

  test('Closest with a reference: nearest first with distances', () async {
    final ds = FakeSearchDataSource([
      rawDoc('far', lat: 36.95, lng: 10.20),
      rawDoc('near', lat: 36.805, lng: 10.20),
      rawDoc('nocoords'),
    ]);
    final f = const PropertySearchFilter(
        sort: SortOption.closest, referenceLatitude: 36.80, referenceLongitude: 10.20);
    final page = await repoOf(ds).search(f);
    expect(page.items.map((p) => p.id), ['near', 'far']);
    expect(page.distancesKm['near'], isNotNull);
  });

  test('Closest WITHOUT a reference falls back to newest and invents no distances', () async {
    final ds = FakeSearchDataSource([rawDoc('a', lat: 36.8, lng: 10.2), rawDoc('b')]);
    final page = await repoOf(ds).search(const PropertySearchFilter(sort: SortOption.closest));
    expect(page.items.length, 2);
    expect(page.distancesKm, isEmpty);
  });

  test('backend errors become DiscoveryFailure', () async {
    final ds = FakeSearchDataSource([])..error = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    await expectLater(
      repoOf(ds).search(newest),
      throwsA(isA<DiscoveryFailure>().having((e) => e.type, 'type', DiscoveryFailureType.network)),
    );
    ds.error = FirebaseException(plugin: 'cloud_firestore', code: 'failed-precondition', message: 'index');
    await expectLater(
      repoOf(ds).search(newest),
      throwsA(isA<DiscoveryFailure>().having((e) => e.type, 'type', DiscoveryFailureType.unknown)),
    );
    ds.error = StateError('boom');
    await expectLater(repoOf(ds).search(newest), throwsA(isA<DiscoveryFailure>()));
  });
}
