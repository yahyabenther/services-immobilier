import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/map/domain/entities/map_viewport.dart';

void main() {
  const tunis = MapViewport(north: 37, south: 36, east: 11, west: 10, zoom: 9);

  test('contains: inside, outside, borders, (0,0) is a valid point', () {
    expect(tunis.contains(36.5, 10.5), isTrue);
    expect(tunis.contains(37, 11), isTrue);
    expect(tunis.contains(35.9, 10.5), isFalse);
    expect(tunis.contains(36.5, 11.1), isFalse);
    expect(const MapViewport(north: 1, south: -1, east: 1, west: -1, zoom: 5).contains(0, 0), isTrue);
  });

  test('contains handles the antimeridian', () {
    const v = MapViewport(north: 10, south: -10, east: -170, west: 170, zoom: 3);
    expect(v.crossesAntimeridian, isTrue);
    expect(v.contains(0, 175), isTrue);
    expect(v.contains(0, -175), isTrue);
    expect(v.contains(0, 0), isFalse);
  });

  test('isValid rejects NaN, inverted and out-of-range bounds', () {
    expect(tunis.isValid, isTrue);
    expect(const MapViewport(north: double.nan, south: 0, east: 1, west: 0, zoom: 1).isValid, isFalse);
    expect(const MapViewport(north: 0, south: 1, east: 1, west: 0, zoom: 1).isValid, isFalse);
    expect(const MapViewport(north: 95, south: 0, east: 1, west: 0, zoom: 1).isValid, isFalse);
  });

  test('normalized clamps latitude and wraps longitude', () {
    final v = MapViewport.normalized(north: 100, south: -100, east: 190, west: 170, zoom: 2);
    expect(v.north, 90);
    expect(v.south, -90);
    expect(v.east, -170);
    expect(v.west, 170);
    final world = MapViewport.normalized(north: 10, south: 0, east: 200, west: -200, zoom: 1);
    expect([world.west, world.east], [-180, 180]);
  });

  test('containsViewport uses the tolerance', () {
    const inner = MapViewport(north: 36.9, south: 36.1, east: 10.9, west: 10.1, zoom: 10);
    const shifted = MapViewport(north: 37.05, south: 36.25, east: 11.05, west: 10.25, zoom: 9);
    expect(tunis.containsViewport(inner), isTrue);
    expect(tunis.containsViewport(shifted), isFalse);
    expect(tunis.containsViewport(shifted, tolerance: 0.1), isTrue);
  });

  test('cacheKey ignores sub-100m jitter and zoom', () {
    const a = MapViewport(north: 37.00001, south: 36, east: 11, west: 10, zoom: 9);
    const b = MapViewport(north: 37.00002, south: 36, east: 11, west: 10, zoom: 9.4);
    expect(a.cacheKey, b.cacheKey);
  });
}
