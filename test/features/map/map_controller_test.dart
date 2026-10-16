import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/errors/discovery_failure.dart';
import '../../../lib/features/map/domain/entities/map_query_result.dart';
import '../../../lib/features/map/domain/entities/map_state.dart';
import '../../../lib/features/map/domain/entities/map_viewport.dart';
import '../../../lib/features/map/domain/repositories/map_repository.dart';
import '../../../lib/features/map/domain/usecases/get_current_location.dart';
import '../../../lib/features/map/presentation/providers/map_providers.dart';
import '../../../lib/features/property_discovery/domain/repositories/location_service.dart';
import '../../../lib/features/property_discovery/presentation/providers/property_discovery_providers.dart';
import '../../../lib/features/search/domain/entities/property_search_filter.dart';
import 'test_helpers.dart';

class FakeMapRepository implements MapRepository {
  int calls = 0;
  Future<MapQueryResult> Function(MapViewport vp) handler = (_) async => const MapQueryResult(items: []);

  @override
  Future<MapQueryResult> getPropertiesInViewport({
    required MapViewport viewport,
    PropertySearchFilter? filter,
    int limit = 150,
  }) {
    calls++;
    return handler(viewport);
  }
}

class FakeLocation implements LocationService {
  FakeLocation(this.result);
  final DeviceLocationResult result;
  @override
  Future<DeviceLocationResult> getCurrentPosition() async => result;
  @override
  Future<void> openSettings() async {}
}

const area1 = MapViewport(north: 37, south: 36, east: 11, west: 10, zoom: 9);
const area2 = MapViewport(north: 35, south: 34, east: 11, west: 10, zoom: 9);

ProviderContainer makeContainer(FakeMapRepository repo, {LocationService? location}) {
  final c = ProviderContainer(overrides: [
    mapRepositoryProvider.overrideWithValue(repo),
    if (location != null) locationServiceProvider.overrideWithValue(location),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('first load: loading -> ready, selection cleared when the property disappears', () async {
    final repo = FakeMapRepository()
      ..handler = (_) async => MapQueryResult(items: [prop('a', lat: 36.5, lng: 10.5), prop('b', lat: 36.6, lng: 10.6)]);
    final c = makeContainer(repo);
    final ctl = c.read(mapScreenProvider.notifier);

    await ctl.onMapReady(area1);
    expect(c.read(mapScreenProvider).status, MapLoadStatus.ready);
    expect(c.read(mapScreenProvider).properties, hasLength(2));

    ctl.selectProperty('a');
    expect(c.read(mapScreenProvider).selectedProperty?.id, 'a');

    repo.handler = (_) async => MapQueryResult(items: [prop('b', lat: 34.5, lng: 10.5)]);
    ctl.onCameraIdle(area2, byUser: true);
    await ctl.searchCurrentArea();
    expect(c.read(mapScreenProvider).selectedId, isNull);
    expect([for (final p in c.read(mapScreenProvider).properties) p.id], ['b']);
  });

  test('empty result -> empty status; failure -> error then retry works', () async {
    final repo = FakeMapRepository();
    final c = makeContainer(repo);
    final ctl = c.read(mapScreenProvider.notifier);

    await ctl.onMapReady(area1);
    expect(c.read(mapScreenProvider).status, MapLoadStatus.empty);

    repo.handler = (_) async => throw const DiscoveryFailure(DiscoveryFailureType.network);
    await ctl.retry();
    expect(c.read(mapScreenProvider).status, MapLoadStatus.error);
    expect(c.read(mapScreenProvider).errorMessage, isNotNull);

    repo.handler = (_) async => MapQueryResult(items: [prop('a', lat: 36.5, lng: 10.5)]);
    await ctl.retry();
    expect(c.read(mapScreenProvider).status, MapLoadStatus.ready);
  });

  test('same area + same filters is not requested twice', () async {
    final repo = FakeMapRepository()..handler = (_) async => MapQueryResult(items: [prop('a', lat: 36.5, lng: 10.5)]);
    final c = makeContainer(repo);
    final ctl = c.read(mapScreenProvider.notifier);
    await ctl.onMapReady(area1);
    await ctl.searchCurrentArea();
    expect(repo.calls, 1);
    await ctl.searchCurrentArea(force: true);
    expect(repo.calls, 2);
  });

  test('a late response for an old area never overwrites newer results', () async {
    final slow = Completer<MapQueryResult>();
    final repo = FakeMapRepository();
    final c = makeContainer(repo);
    final ctl = c.read(mapScreenProvider.notifier);

    repo.handler = (_) => slow.future;
    final first = ctl.onMapReady(area1); // request A (slow)

    repo.handler = (_) async => MapQueryResult(items: [prop('new', lat: 34.5, lng: 10.5)]);
    ctl.onCameraIdle(area2, byUser: true);
    await ctl.searchCurrentArea(); // request B (fast)

    slow.complete(MapQueryResult(items: [prop('old', lat: 36.5, lng: 10.5)]));
    await first;

    expect([for (final p in c.read(mapScreenProvider).properties) p.id], ['new']);
  });

  test('"Search this area" only appears after a USER move outside the searched area', () async {
    final repo = FakeMapRepository()..handler = (_) async => MapQueryResult(items: [prop('a', lat: 36.5, lng: 10.5)]);
    final c = makeContainer(repo);
    final ctl = c.read(mapScreenProvider.notifier);
    await ctl.onMapReady(area1);
    expect(c.read(mapScreenProvider).viewportChanged, isFalse);

    ctl.onCameraIdle(area2, byUser: false); // programmatic (e.g. cluster zoom)
    expect(c.read(mapScreenProvider).viewportChanged, isFalse);

    ctl.onCameraIdle(area2, byUser: true);
    expect(c.read(mapScreenProvider).viewportChanged, isTrue);

    await ctl.searchCurrentArea();
    expect(c.read(mapScreenProvider).viewportChanged, isFalse);
  });

  test('selecting an unknown id is ignored (selection is by ID, never by index)', () async {
    final repo = FakeMapRepository()..handler = (_) async => MapQueryResult(items: [prop('a', lat: 36.5, lng: 10.5)]);
    final c = makeContainer(repo);
    final ctl = c.read(mapScreenProvider.notifier);
    await ctl.onMapReady(area1);
    ctl.selectProperty('ghost');
    expect(c.read(mapScreenProvider).selectedId, isNull);
  });

  test('location denied never breaks the map; granted stores the point', () async {
    final repo = FakeMapRepository();
    final denied = makeContainer(repo, location: FakeLocation(const DeviceLocationDenied()));
    final r = await denied.read(mapScreenProvider.notifier).locateMe();
    expect(r!.outcome, LocateOutcome.denied);
    expect(denied.read(mapScreenProvider).userLocation, isNull);
    expect(denied.read(mapScreenProvider).isLocating, isFalse);

    final granted = makeContainer(repo, location: FakeLocation(const DeviceLocationGranted(36.8, 10.18)));
    final ok = await granted.read(mapScreenProvider.notifier).locateMe();
    expect(ok!.isLocated, isTrue);
    expect(granted.read(mapScreenProvider).userLocation?.latitude, 36.8);
  });
}
