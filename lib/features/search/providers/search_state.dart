import '../../properties/domain/entities/property.dart';
import '../domain/entities/property_search_filter.dart';

const _unset = Object();

/// Spec §4.4: idle -> loading -> results | empty | error.
enum SearchStatus { idle, loading, success, empty, error }

enum SearchViewMode { list, map }

class SearchState {
  const SearchState({
    this.filter = const PropertySearchFilter(),
    this.status = SearchStatus.idle,
    this.items = const [],
    this.distancesKm = const {},
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.errorMessage,
    this.viewMode = SearchViewMode.list,
  });

  /// The APPLIED filter (what the visible results were computed with).
  final PropertySearchFilter filter;
  final SearchStatus status;
  final List<Property> items;
  final Map<String, double> distancesKm;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final String? errorMessage;
  final SearchViewMode viewMode;

  bool get isLoading => status == SearchStatus.loading;

  SearchState copyWith({
    PropertySearchFilter? filter,
    SearchStatus? status,
    List<Property>? items,
    Map<String, double>? distancesKm,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Object? errorMessage = _unset,
    SearchViewMode? viewMode,
  }) =>
      SearchState(
        filter: filter ?? this.filter,
        status: status ?? this.status,
        items: items ?? this.items,
        distancesKm: distancesKm ?? this.distancesKm,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
        viewMode: viewMode ?? this.viewMode,
      );
}
