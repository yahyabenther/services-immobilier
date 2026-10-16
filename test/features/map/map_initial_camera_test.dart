import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/map/domain/entities/map_initial_camera.dart';
import '../../../lib/features/map/domain/services/map_filter_resolver.dart';
import '../../../lib/features/properties/domain/entities/property.dart';
import '../../../lib/features/search/domain/entities/property_search_filter.dart';

void main() {
  test('lat/lng hint wins, then governorate, otherwise no hint', () {
    final p = MapInitialCamera.fromHints({'lat': '36.8', 'lng': '10.18', 'governorate': 'Sfax'}, governorate: 'Sfax');
    expect(p!.latitude, 36.8);
    final g = MapInitialCamera.fromHints({}, governorate: 'Sfax');
    expect(g!.latitude, closeTo(34.74, 0.01));
    expect(MapInitialCamera.fromHints({}), isNull);
    expect(MapInitialCamera.fromHints({'lat': '999', 'lng': '10'}), isNull);
    expect(MapInitialCamera.fromHints({}, governorate: 'Atlantis'), isNull);
  });

  test('source=search keeps the Search filter; Home params start clean', () {
    const searchFilter = PropertySearchFilter(transactionType: TransactionType.buy, minPrice: 100000);
    final fromSearch = resolveMapFilter({'source': 'search', 't': '1'}, searchFilter: searchFilter);
    expect(fromSearch.transactionType, TransactionType.buy);
    expect(fromSearch.minPrice, 100000);

    final fromHome = resolveMapFilter({'governorate': 'Tunis'}, searchFilter: searchFilter);
    expect(fromHome.governorate, 'Tunis');
    expect(fromHome.minPrice, isNull);
  });
}
