import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/map/domain/services/marker_clusterer.dart';
import 'test_helpers.dart';

void main() {
  final near = [
    prop('a', lat: 36.8000, lng: 10.1800),
    prop('b', lat: 36.8001, lng: 10.1801), // ~15 m from a
  ];

  test('close listings group at a wide zoom, split at street level', () {
    final wide = MarkerClusterer.cluster(near, zoom: 10);
    expect(wide, hasLength(1));
    expect(wide.single.count, 2);

    final close = MarkerClusterer.cluster(near, zoom: 18);
    expect(close, hasLength(2));
    expect(close.every((c) => c.isSingle), isTrue);
  });

  test('far listings never group at country zoom', () {
    final far = [prop('tunis', lat: 36.8, lng: 10.18), prop('sfax', lat: 34.74, lng: 10.76)];
    expect(MarkerClusterer.cluster(far, zoom: 8), hasLength(2));
  });

  test('identical coordinates stay grouped even at max zoom (and cannot be split by zoom)', () {
    final same = [prop('a', lat: 36.8, lng: 10.18), prop('b', lat: 36.8, lng: 10.18)];
    final c = MarkerClusterer.cluster(same, zoom: 19);
    expect(c, hasLength(1));
    expect(c.single.isDegenerate, isTrue);
    expect(c.single.canZoomFurther(19), isFalse);
  });

  test('a real cluster can be zoomed into', () {
    final c = MarkerClusterer.cluster(near, zoom: 10).single;
    expect(c.canZoomFurther(10), isTrue);
    expect(c.canZoomFurther(18), isFalse);
  });

  test('pinned (selected) listing is never absorbed', () {
    final out = MarkerClusterer.cluster(near, zoom: 10, pinnedId: 'a');
    expect(out, hasLength(2));
    expect(out.last.single.id, 'a'); // drawn last = on top
  });

  test('listings without coordinates are ignored, centroid is the mean', () {
    final out = MarkerClusterer.cluster([...near, prop('x')], zoom: 10);
    expect(out.single.count, 2);
    expect(out.single.latitude, closeTo(36.80005, 1e-9));
  });
}
