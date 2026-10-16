import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/errors/discovery_failure.dart';
import '../../../lib/features/map/data/map_property_data_source.dart';
import '../../../lib/features/map/data/map_repository_impl.dart';
import '../../../lib/features/map/domain/entities/map_viewport.dart';
import '../../../lib/features/properties/domain/entities/property.dart';
import '../../../lib/features/search/domain/entities/property_search_filter.dart';
import 'test_helpers.dart';

class FakeDataSource implements MapDataSource {
  FakeDataSource(this.docs, {this.error});
  final List<({String id, Map<String, dynamic> data})> docs;
  final Object? error;
  int calls = 0;

  @override
  Future<RawMapBatch> fetchLatitudeBand({
    required double south,
    required double north,
    Object? cursor,
    required int batchSize,
  }) async {
    calls++;
    if (error != null) throw error!;
    final start = (cursor as int?) ?? 0;
    final slice = docs.skip(start).take(batchSize).toList();
    return RawMapBatch(docs: slice, lastCursor: start + slice.length, exhausted: slice.length < batchSize);
  }
}

const vp = MapViewport(north: 37, south: 36, east: 11, west: 10, zoom: 9);

void main() {
  test('keeps only published listings with coordinates inside the viewport', () async {
    final ds = FakeDataSource([
      (id: 'ok', data: doc()),
      (id: 'draft', data: doc(status: 'draft')),
      (id: 'pending', data: doc(status: 'pending_review')),
      (id: 'outside', data: doc(lng: 12.0)),
      (id: 'badcoords', data: doc(lat: 123.0)),
      (id: 'nocoords', data: doc(lat: null, lng: null)),
    ]);
    final r = await MapRepositoryImpl(ds).getPropertiesInViewport(viewport: vp);
    expect([for (final p in r.items) p.id], ['ok']);
    expect(r.truncated, isFalse);
  });

  test('applies the same filters as Search', () async {
    final ds = FakeDataSource([
      (id: 'rent', data: doc(tx: 'rent')),
      (id: 'buy', data: doc(tx: 'buy')),
    ]);
    final r = await MapRepositoryImpl(ds).getPropertiesInViewport(
      viewport: vp,
      filter: const PropertySearchFilter(transactionType: TransactionType.buy),
    );
    expect([for (final p in r.items) p.id], ['buy']);
  });

  test('limit truncates and flags it', () async {
    final ds = FakeDataSource([for (var i = 0; i < 10; i++) (id: 'p$i', data: doc())]);
    final r = await MapRepositoryImpl(ds).getPropertiesInViewport(viewport: vp, limit: 4);
    expect(r.items, hasLength(4));
    expect(r.truncated, isTrue);
  });

  test('scan cap prevents reading the whole collection', () async {
    final ds = FakeDataSource([for (var i = 0; i < 1000; i++) (id: 'p$i', data: doc(lng: 50.0))]);
    final r = await MapRepositoryImpl(ds).getPropertiesInViewport(viewport: vp);
    expect(r.items, isEmpty);
    expect(r.truncated, isTrue);
    expect(ds.calls, MapRepositoryImpl.maxScan ~/ MapRepositoryImpl.batchSize);
  });

  test('invalid viewport returns nothing without querying', () async {
    final ds = FakeDataSource([(id: 'ok', data: doc())]);
    const bad = MapViewport(north: 0, south: 5, east: 1, west: 0, zoom: 1);
    final r = await MapRepositoryImpl(ds).getPropertiesInViewport(viewport: bad);
    expect(r.items, isEmpty);
    expect(ds.calls, 0);
  });

  test('Firestore errors become DiscoveryFailure without raw text', () async {
    Future<DiscoveryFailureType> typeFor(String code) async {
      final repo = MapRepositoryImpl(FakeDataSource(const [], error: FirebaseException(plugin: 'cloud_firestore', code: code)));
      try {
        await repo.getPropertiesInViewport(viewport: vp);
      } on DiscoveryFailure catch (e) {
        return e.type;
      }
      fail('expected a failure');
    }

    expect(await typeFor('unavailable'), DiscoveryFailureType.network);
    expect(await typeFor('permission-denied'), DiscoveryFailureType.permissionDenied);
    expect(await typeFor('failed-precondition'), DiscoveryFailureType.unknown);
  });
}
