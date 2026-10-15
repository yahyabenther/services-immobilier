import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/discovery_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../../property_discovery/domain/repositories/location_service.dart';
import '../../property_discovery/presentation/providers/property_discovery_providers.dart';
import'../data/datasources/firestore_search_datasource.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/entities/property_search_filter.dart';
import '../domain/entities/search_enums.dart';
import '../domain/repositories/search_repository.dart';
import '../domain/usecases/search_properties.dart';
import 'search_state.dart';

// ---- infrastructure (override in tests) -----------------------------------
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(FirestoreSearchDatasource(ref.watch(firestoreProvider))),
);

final searchPropertiesProvider =
    Provider((ref) => SearchProperties(ref.watch(searchRepositoryProvider)));

const searchPageSize = 20;
const searchDebounce = Duration(milliseconds: 400);

/// Result of choosing "Closest".
enum ClosestOutcome { applied, denied, deniedForever, serviceDisabled, error }

final searchResultsProvider =
    NotifierProvider<SearchResultsController, SearchState>(SearchResultsController.new);

/// Owns the applied filter and the paginated results.
/// Not auto-disposed: filters and results survive opening a property and coming back.
class SearchResultsController extends Notifier<SearchState> {
  Object? _cursor;
  int _seq = 0; // newest request wins
  Timer? _debounce;

  @override
  SearchState build() {
    // User-scoped: filters and results are rebuilt from scratch whenever the
    // signed-in user changes (logout, account switch).
    ref.watch(currentUserProvider.select((u) => u?.id));
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  // ---- loading ---------------------------------------------------------------
  /// First visit: show the default published feed (spec §7.1).
  Future<void> ensureLoaded() async {
    if (state.status == SearchStatus.idle) await _run(state.filter);
  }

  Future<void> refresh() => _run(state.filter, keepItems: true);

  Future<void> retry() => _run(state.filter);

  Future<void> _run(PropertySearchFilter f, {bool keepItems = false}) async {
    final seq = ++_seq;
    _cursor = null;
    state = state.copyWith(
      filter: f,
      status: keepItems && state.items.isNotEmpty ? state.status : SearchStatus.loading,
      items: keepItems ? state.items : const [],
      errorMessage: null,
      isLoadingMore: false,
      loadMoreFailed: false,
      hasMore: keepItems ? state.hasMore : false,
    );
    try {
      final page = await ref.read(searchPropertiesProvider)(f, pageSize: searchPageSize);
      if (seq != _seq) return; // a newer request replaced this one
      _cursor = page.nextCursor;
      state = state.copyWith(
        status: page.items.isEmpty ? SearchStatus.empty : SearchStatus.success,
        items: page.items,
        distancesKm: page.distancesKm,
        hasMore: page.hasMore,
        errorMessage: null,
      );
    } on InvalidSearchFilter {
      if (seq != _seq) return;
      state = state.copyWith(status: SearchStatus.error, errorMessage: 'Please check the filter values.');
    } on DiscoveryFailure catch (e) {
      if (seq != _seq) return;
      state = state.copyWith(status: SearchStatus.error, errorMessage: e.message);
    } catch (_) {
      if (seq != _seq) return;
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: const DiscoveryFailure(DiscoveryFailureType.unknown).message,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.status != SearchStatus.success) return;
    final seq = _seq;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await ref
          .read(searchPropertiesProvider)(state.filter, cursor: _cursor, pageSize: searchPageSize);
      if (seq != _seq) return; // filters changed meanwhile
      _cursor = page.nextCursor;
      final known = {for (final p in state.items) p.id};
      state = state.copyWith(
        items: [...state.items, ...page.items.where((p) => !known.contains(p.id))],
        distancesKm: {...state.distancesKm, ...page.distancesKm},
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      if (seq != _seq) return;
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  // ---- changing the query ------------------------------------------------------
  /// Debounced: typing quickly does not fire a request per keystroke.
  void setQueryText(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      final t = text.trim();
      final current = state.filter.queryText ?? '';
      if (t == current) return;
      _run(state.filter.copyWith(queryText: t.isEmpty ? null : t));
    });
  }

  Future<void> applyFilter(PropertySearchFilter f) {
    _debounce?.cancel();
    return _run(f);
  }

  Future<void> setTab(ListingTab tab) => applyFilter(state.filter.withTab(tab));

  /// Removes everything the user selected (query, tab, filters); keeps sort and reference.
  Future<void> clearAll() => applyFilter(state.filter.cleared());

  /// Entry from Home / other modules: `/search?transactionType=buy&governorate=Tunis&...`.
  /// Starts from a clean filter so a shortcut always shows what it promises.
  Future<void> applyRouteParams(Map<String, String> params) async {
    if (params.isEmpty) return;
    final next = PropertySearchFilter.fromQueryParameters(params);
    if (next == state.filter && state.status != SearchStatus.idle) return;
    await applyFilter(next);
  }

  void setViewMode(SearchViewMode mode) => state = state.copyWith(viewMode: mode);

  // ---- sorting ------------------------------------------------------------------
  /// "Closest" needs a real reference location: the Home selection if it has
  /// coordinates, otherwise the device position (asked only now, on this tap).
  Future<ClosestOutcome> setSort(SortOption sort) async {
    if (sort != SortOption.closest) {
      await applyFilter(state.filter.copyWith(sort: sort));
      return ClosestOutcome.applied;
    }
    if (state.filter.hasReference) {
      await applyFilter(state.filter.copyWith(sort: sort));
      return ClosestOutcome.applied;
    }
    final home = ref.read(selectedLocationProvider);
    if (home != null && home.hasCoordinates) {
      await applyFilter(state.filter.copyWith(
        sort: sort,
        referenceLatitude: home.latitude,
        referenceLongitude: home.longitude,
      ));
      return ClosestOutcome.applied;
    }
    final result = await ref.read(locationServiceProvider).getCurrentPosition();
    switch (result) {
      case DeviceLocationGranted(:final latitude, :final longitude):
        await applyFilter(state.filter.copyWith(
          sort: sort,
          referenceLatitude: latitude,
          referenceLongitude: longitude,
        ));
        return ClosestOutcome.applied;
      case DeviceLocationDenied():
        return ClosestOutcome.denied;
      case DeviceLocationDeniedForever():
        return ClosestOutcome.deniedForever;
      case DeviceLocationServiceDisabled():
        return ClosestOutcome.serviceDisabled;
      case DeviceLocationError():
        return ClosestOutcome.error;
    }
  }
}
