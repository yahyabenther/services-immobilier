import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/discovery_failure.dart';
import '../../../properties/data/property_mapper.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/property_search_filter.dart';
import '../../domain/entities/search_enums.dart';
import '../../domain/entities/search_result_page.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/services/search_matcher.dart';
import '../../domain/services/search_query_plan.dart';
import '../../domain/services/search_sorter.dart';
import '../datasources/firestore_search_datasource.dart';

/// Scans the backend in sort order, keeps only the properties that match EVERY
/// filter, and continues from the last scanned document. Consequences:
/// - results are always correct (each returned property satisfies the whole filter),
/// - no duplicates / gaps between pages,
/// - a very selective filter may need several scanned batches; the scan is capped
///   ([maxScan]) so one request never reads the whole collection, and `hasMore`
///   tells the UI to offer "Load more".
class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._ds, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final SearchDataSource _ds;
  final DateTime Function() _now;

  /// Size of the ranked window for Recommended / Closest.
  static const windowSize = 60;
  static const _windowBatch = 40;
  static const _windowMaxScan = 200;
  static const _maxScan = 160;

  @override
  Future<SearchResultPage> search(
    PropertySearchFilter filter, {
    Object? cursor,
    int pageSize = 20,
  }) async {
    try {
      // "Closest" without a reference location cannot be computed: fall back to
      // newest order instead of faking distances.
      final effective = (filter.sort == SortOption.closest && !filter.hasReference)
          ? filter.copyWith(sort: SortOption.newest)
          : filter;
      final windowed = effective.sort.isWindowed;
      final plan = SearchQueryPlan.fromFilter(effective);

      final target = windowed ? windowSize : pageSize;
      final batchSize = windowed ? _windowBatch : math.max(pageSize, 20);
      final maxScan = windowed ? _windowMaxScan : _maxScan;

      Object? cur = windowed ? null : cursor;
      var scanned = 0;
      var exhausted = false;
      final matched = <Property>[];
      final seen = <String>{};

      while (matched.length < target && scanned < maxScan && !exhausted) {
        final batch = await _ds.fetchBatch(plan, cursor: cur, batchSize: batchSize);
        scanned += batch.docs.length;
        cur = batch.lastCursor;
        exhausted = batch.exhausted;
        for (final raw in batch.docs) {
          final p = PropertyMapper.tryFromMap(raw.id, raw.data);
          if (p == null) {
            debugPrint('Skipping malformed property ${raw.id}');
            continue;
          }
          // Defence in depth: never trust the query alone for visibility.
          if (!p.isPublic || !seen.add(p.id)) continue;
          if (SearchMatcher.matches(p, effective)) matched.add(p);
        }
      }

      if (windowed) {
        final sorted = SearchSorter.sortWindow(matched, effective, now: _now());
        return SearchResultPage(items: sorted.items, distancesKm: sorted.distancesKm);
      }
      return SearchResultPage(items: matched, nextCursor: cur, hasMore: !exhausted);
    } on FirebaseException catch (e) {
      // `failed-precondition` = missing composite index; the message contains the creation link.
      debugPrint('Search query failed [${e.code}]: ${e.message}');
      throw DiscoveryFailure(switch (e.code) {
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' => DiscoveryFailureType.network,
        'permission-denied' => DiscoveryFailureType.permissionDenied,
        _ => DiscoveryFailureType.unknown,
      });
    } on DiscoveryFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('Unexpected search error: $e\n$st');
      throw const DiscoveryFailure(DiscoveryFailureType.unknown);
    }
  }
}
