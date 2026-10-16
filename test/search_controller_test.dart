import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/discovery_failure.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/property_discovery/domain/repositories/location_service.dart';
import 'package:team_app/features/property_discovery/presentation/providers/property_discovery_providers.dart';
import 'package:team_app/features/search/domain/entities/property_search_filter.dart';
import 'package:team_app/features/search/domain/entities/search_enums.dart';
import 'package:team_app/features/search/providers/search_providers.dart';
import 'package:team_app/features/search/providers/search_state.dart';

import 'fake_search_repository.dart';
import 'support_properties.dart';

List<Property> props(String prefix, int n) => [for (var i = 0; i < n; i++) makeProperty(id: '$prefix$i')];

ProviderContainer make(FakeSearchRepository repo, {FakeLocationService? location}) {
  final c = ProviderContainer(overrides: [
    searchRepositoryProvider.overrideWithValue(repo),
    locationServiceProvider.overrideWithValue(location ?? FakeLocationService()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('first visit loads the default feed once', () async {
    final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 3)));
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);
    expect(c.read(searchResultsProvider).status, SearchStatus.idle);

    await ctrl.ensureLoaded();
    await ctrl.ensureLoaded(); // second call must not reload
    expect(repo.calls.length, 1);
    final s = c.read(searchResultsProvider);
    expect(s.status, SearchStatus.success);
    expect(s.items.length, 3);
  });

  test('no results -> empty state', () async {
    final c = make(FakeSearchRepository((_, _) async => pageOf(const [])));
    await c.read(searchResultsProvider.notifier).ensureLoaded();
    expect(c.read(searchResultsProvider).status, SearchStatus.empty);
  });

  test('failure -> error with a friendly message; retry recovers and keeps the filter', () async {
    var fail = true;
    final repo = FakeSearchRepository((_, _) async {
      if (fail) throw const DiscoveryFailure(DiscoveryFailureType.network);
      return pageOf(props('a', 2));
    });
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);
    await ctrl.applyFilter(const PropertySearchFilter().withTab(ListingTab.rent));
    var s = c.read(searchResultsProvider);
    expect(s.status, SearchStatus.error);
    expect(s.errorMessage, isNotEmpty);
    expect(s.filter.tab, ListingTab.rent);

    fail = false;
    await ctrl.retry();
    s = c.read(searchResultsProvider);
    expect(s.status, SearchStatus.success);
    expect(s.filter.tab, ListingTab.rent); // filters survived the failure
  });

  test('an older, slower response never overwrites a newer one', () async {
    final slow = Completer<SearchResultPage>();
    var n = 0;
    final repo = FakeSearchRepository((_, _) {
      n++;
      return n == 1 ? slow.future : Future.value(pageOf(props('new', 2)));
    });
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);

    final first = ctrl.applyFilter(const PropertySearchFilter());
    await ctrl.applyFilter(const PropertySearchFilter(minPrice: 1));
    slow.complete(pageOf(props('old', 5)));
    await first;

    final ids = c.read(searchResultsProvider).items.map((p) => p.id).toList();
    expect(ids, ['new0', 'new1']);
  });

  test('loadMore appends the next page, dedupes and stops at the end', () async {
    final repo = FakeSearchRepository((_, cursor) async {
      if (cursor == null) return pageOf(props('p', 3), hasMore: true, next: 'c1');
      return pageOf([...props('p', 1), ...props('q', 2)], hasMore: false); // p0 repeated on purpose
    });
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);
    await ctrl.ensureLoaded();
    await ctrl.loadMore();

    final s = c.read(searchResultsProvider);
    expect(s.items.map((p) => p.id), ['p0', 'p1', 'p2', 'q0', 'q1']);
    expect(s.hasMore, isFalse);
    expect(repo.calls.last.cursor, 'c1');

    await ctrl.loadMore(); // nothing more
    expect(repo.calls.length, 2);
  });

  test('a failed loadMore keeps the results and allows retry', () async {
    var failNext = true;
    final repo = FakeSearchRepository((_, cursor) async {
      if (cursor == null) return pageOf(props('p', 2), hasMore: true, next: 'c1');
      if (failNext) throw const DiscoveryFailure(DiscoveryFailureType.network);
      return pageOf(props('q', 1));
    });
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);
    await ctrl.ensureLoaded();
    await ctrl.loadMore();
    var s = c.read(searchResultsProvider);
    expect(s.loadMoreFailed, isTrue);
    expect(s.items.length, 2);
    expect(s.status, SearchStatus.success);

    failNext = false;
    await ctrl.loadMore();
    s = c.read(searchResultsProvider);
    expect(s.items.length, 3);
    expect(s.loadMoreFailed, isFalse);
  });

  test('typing is debounced: one request for a burst of keystrokes', () async {
    final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 1)));
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);
    await ctrl.ensureLoaded();
    final before = repo.calls.length;

    ctrl.setQueryText('v');
    ctrl.setQueryText('vi');
    ctrl.setQueryText('villa');
    await Future<void>.delayed(searchDebounce + const Duration(milliseconds: 150));

    expect(repo.calls.length, before + 1);
    expect(repo.calls.last.filter.queryText, 'villa');
  });

  test('clearAll removes filters but keeps the sort', () async {
    final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 1)));
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);
    await ctrl.applyFilter(const PropertySearchFilter(sort: SortOption.lowestPrice, minPrice: 5)
        .withTab(ListingTab.buy));
    await ctrl.clearAll();
    final f = c.read(searchResultsProvider).filter;
    expect(f.activeFilterCount, 0);
    expect(f.tab, ListingTab.all);
    expect(f.sort, SortOption.lowestPrice);
  });

  test('Home shortcut params set the real filter, and the same params do not reload', () async {
    final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 1)));
    final c = make(repo);
    final ctrl = c.read(searchResultsProvider.notifier);
    await ctrl.applyRouteParams({'transactionType': 'rent', 'governorate': 'Sousse'});
    var f = c.read(searchResultsProvider).filter;
    expect(f.transactionType, TransactionType.rent);
    expect(f.governorate, 'Sousse');

    final calls = repo.calls.length;
    await ctrl.applyRouteParams({'transactionType': 'rent', 'governorate': 'Sousse'});
    expect(repo.calls.length, calls);

    await ctrl.applyRouteParams({'transactionType': 'buy'});
    f = c.read(searchResultsProvider).filter;
    expect(f.transactionType, TransactionType.buy);
    expect(f.governorate, isNull); // a shortcut starts clean
  });

  group('Closest sort', () {
    test('without any location and with permission denied -> not applied', () async {
      final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 1)));
      final location = FakeLocationService(const DeviceLocationDenied());
      final c = make(repo, location: location);
      final ctrl = c.read(searchResultsProvider.notifier);
      await ctrl.ensureLoaded();

      final outcome = await ctrl.setSort(SortOption.closest);
      expect(outcome, ClosestOutcome.denied);
      expect(c.read(searchResultsProvider).filter.sort, isNot(SortOption.closest));
      expect(location.requests, 1);
    });

    test('permission granted -> applied with a real reference location', () async {
      final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 1)));
      final c = make(repo, location: FakeLocationService(const DeviceLocationGranted(36.8, 10.2)));
      final ctrl = c.read(searchResultsProvider.notifier);
      final outcome = await ctrl.setSort(SortOption.closest);
      expect(outcome, ClosestOutcome.applied);
      final f = c.read(searchResultsProvider).filter;
      expect(f.sort, SortOption.closest);
      expect(f.referenceLatitude, 36.8);
    });

    test('reuses the device location chosen on Home (no second permission prompt)', () async {
      final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 1)));
      final location = FakeLocationService(const DeviceLocationGranted(35.8, 10.6));
      final c = make(repo, location: location);
      await c.read(selectedLocationProvider.notifier).useDeviceLocation();
      expect(location.requests, 1);

      final outcome = await c.read(searchResultsProvider.notifier).setSort(SortOption.closest);
      expect(outcome, ClosestOutcome.applied);
      expect(location.requests, 1); // not asked again
      expect(c.read(searchResultsProvider).filter.referenceLatitude, 35.8);
    });

    test('other sorts never touch location', () async {
      final repo = FakeSearchRepository((_, _) async => pageOf(props('a', 1)));
      final location = FakeLocationService();
      final c = make(repo, location: location);
      await c.read(searchResultsProvider.notifier).setSort(SortOption.highestPrice);
      expect(location.requests, 0);
      expect(c.read(searchResultsProvider).filter.sort, SortOption.highestPrice);
    });
  });
}
