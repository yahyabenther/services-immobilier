import 'dart:async';

import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/property_discovery/domain/repositories/location_service.dart';
import 'package:team_app/features/search/domain/entities/property_search_filter.dart';
import 'package:team_app/features/search/domain/entities/search_result_page.dart';
import 'package:team_app/features/search/domain/repositories/search_repository.dart';

typedef SearchHandler = Future<SearchResultPage> Function(PropertySearchFilter filter, Object? cursor);

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository(this.handler);

  SearchHandler handler;
  final calls = <({PropertySearchFilter filter, Object? cursor})>[];

  @override
  Future<SearchResultPage> search(PropertySearchFilter filter, {Object? cursor, int pageSize = 20}) {
    calls.add((filter: filter, cursor: cursor));
    return handler(filter, cursor);
  }
}

SearchResultPage pageOf(List<Property> items, {bool hasMore = false, Object? next, Map<String, double> distances = const {}}) =>
    SearchResultPage(items: items, hasMore: hasMore, nextCursor: next, distancesKm: distances);

class FakeLocationService implements LocationService {
  FakeLocationService([this.result = const DeviceLocationDenied()]);

  DeviceLocationResult result;
  int requests = 0;

  @override
  Future<DeviceLocationResult> getCurrentPosition() async {
    requests++;
    return result;
  }

  @override
  Future<void> openSettings() async {}
}
