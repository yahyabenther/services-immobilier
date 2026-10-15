import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart' show mapEquals;

import '../../../../core/theme/app_colors.dart';
import '../../../favorites/presentation/widgets/favorite_property_card.dart';
import '../../providers/search_providers.dart';
import '../../providers/search_state.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/listing_tab_bar.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/search_map_view.dart';
import '../widgets/search_sort_sheet.dart';
import '../widgets/search_states.dart';

/// Module 04 screen: search box, tabs, filters, sort, list/map switch, paginated results.
///
/// [params] are the route query parameters (`/search?transactionType=buy&governorate=Tunis...`).
/// They are applied once when they change; otherwise the previous filters and results
/// are kept (so coming back from a property does not lose anything).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.params = const {}});

  final Map<String, String> params;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _scroll = ScrollController();
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(
      text: ref.read(searchResultsProvider).filter.queryText ?? '',
    );
    _scroll.addListener(_onScroll);
    Future.microtask(() async {
      final c = ref.read(searchResultsProvider.notifier);
      await c.applyRouteParams(widget.params);
      await c.ensureLoaded();
    });
  }

  @override
  void didUpdateWidget(SearchPage old) {
    super.didUpdateWidget(old);
    if (!mapEquals(old.params, widget.params)) {
      ref.read(searchResultsProvider.notifier).applyRouteParams(widget.params);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 320) {
      ref.read(searchResultsProvider.notifier).loadMore();
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openFilters() async {
    final current = ref.read(searchResultsProvider).filter;
    final result = await showSearchFilterSheet(context, current);
    if (result != null && mounted) {
      await ref.read(searchResultsProvider.notifier).applyFilter(result);
    }
  }

  Future<void> _openSort() async {
    final c = ref.read(searchResultsProvider.notifier);
    final picked = await showSearchSortSheet(
      context,
      ref.read(searchResultsProvider).filter.sort,
    );
    if (picked == null || !mounted) return;
    final outcome = await c.setSort(picked);
    if (!mounted) return;
    switch (outcome) {
      case ClosestOutcome.applied:
        break;
      case ClosestOutcome.denied:
        _snack('Location permission is needed to sort by distance.');
      case ClosestOutcome.deniedForever:
        _snack(
          'Location is blocked for ImmoFind. Enable it in system settings to sort by distance.',
        );
      case ClosestOutcome.serviceDisabled:
        _snack('Turn on location services to sort by distance.');
      case ClosestOutcome.error:
        _snack("Couldn't get your location. Sorting was not changed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(searchResultsProvider);
    final c = ref.read(searchResultsProvider.notifier);

    // Keep the text box in sync when the query is cleared elsewhere (Clear all, chips).
    ref.listen<String>(
      searchResultsProvider.select((st) => st.filter.queryText ?? ''),
      (_, next) {
        if (next != _query.text.trim()) _query.text = next;
      },
    );

    final count = s.items.length;
    final countLabel = s.isLoading
        ? 'Searching...'
        : s.status == SearchStatus.error
        ? ''
        : '$count${s.hasMore ? '+' : ''} ${count == 1 && !s.hasMore ? 'property' : 'properties'}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // ---- search box + filters button ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      onChanged: c.setQueryText,
                      onSubmitted: (v) => c.setQueryText(v),
                      decoration: InputDecoration(
                        hintText: 'City, neighborhood or keyword',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _query,
                          builder: (_, v, __) => v.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _query.clear();
                                    c.setQueryText('');
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Badge(
                    label: Text('${s.filter.activeFilterCount}'),
                    isLabelVisible: s.filter.activeFilterCount > 0,
                    child: IconButton.filledTonal(
                      tooltip: 'Filters',
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
            ),
            ListingTabBar(selected: s.filter.tab, onSelected: c.setTab),
            const SizedBox(height: 4),
            ActiveFilterChips(
              filter: s.filter,
              onChanged: c.applyFilter,
              onClearAll: c.clearAll,
            ),
            // ---- count / sort / view switch ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      countLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openSort,
                    icon: const Icon(Icons.swap_vert_rounded, size: 18),
                    label: Text(s.filter.sort.label),
                  ),
                  SegmentedButton<SearchViewMode>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: SearchViewMode.list,
                        icon: Icon(Icons.view_agenda_outlined),
                        tooltip: 'List',
                      ),
                      ButtonSegment(
                        value: SearchViewMode.map,
                        icon: Icon(Icons.map_outlined),
                        tooltip: 'Map',
                      ),
                    ],
                    selected: {s.viewMode},
                    onSelectionChanged: (v) => c.setViewMode(v.first),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _body(s)),
          ],
        ),
      ),
    );
  }

  Widget _body(SearchState s) {
    final c = ref.read(searchResultsProvider.notifier);

    if (s.viewMode == SearchViewMode.map && s.status == SearchStatus.success) {
      return SearchMapView(
        items: s.items,
        onShowList: () => c.setViewMode(SearchViewMode.list),
      );
    }

    switch (s.status) {
      case SearchStatus.idle:
      case SearchStatus.loading:
        return const SearchLoadingList();
      case SearchStatus.error:
        return SearchErrorState(message: s.errorMessage, onRetry: c.retry);
      case SearchStatus.empty:
        return RefreshIndicator(
          onRefresh: c.refresh,
          child: SearchEmptyState(
            hasActiveCriteria: !s.filter.isDefault,
            onClear: c.clearAll,
          ),
        );
      case SearchStatus.success:
        return RefreshIndicator(
          onRefresh: c.refresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720), // tablets
              child: ListView.builder(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: s.items.length + 1,
                itemBuilder: (context, i) {
                  if (i == s.items.length)
                    return _Footer(state: s, onMore: c.loadMore);
                  final p = s.items[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FavoritePropertyCard(
                      key: ValueKey(p.id),
                      property: p,
                      width: double.infinity,
                      distanceKm: s.distancesKm[p.id],
                    ),
                  );
                },
              ),
            ),
          ),
        );
    }
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onMore});

  final SearchState state;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }
    if (state.loadMoreFailed) {
      return Center(
        child: TextButton.icon(
          onPressed: onMore,
          icon: const Icon(Icons.refresh),
          label: const Text("Couldn't load more. Tap to retry"),
        ),
      );
    }
    if (state.hasMore) {
      return Center(
        child: TextButton(onPressed: onMore, child: const Text('Load more')),
      );
    }
    return const SizedBox(height: 8);
  }
}
