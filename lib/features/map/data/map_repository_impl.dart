import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/discovery_failure.dart';
import '../../properties/data/property_mapper.dart';
import '../../properties/domain/entities/property.dart';
import '../../search/domain/entities/property_search_filter.dart';
import '../../search/domain/services/search_matcher.dart';
import '../domain/entities/map_query_result.dart';
import '../domain/entities/map_viewport.dart';
import '../domain/repositories/map_repository.dart';
import 'map_property_data_source.dart';

/// Scans the latitude band in batches, keeps what is inside the viewport AND matches
/// every filter (same [SearchMatcher] as Module 04), and stops at [limit] / [maxScan].
/// One request therefore never reads the whole collection.
///
/// Known limit: inside a dense latitude band the scan is capped, so [MapQueryResult.truncated]
/// becomes true and the UI asks the user to zoom in. For a much larger catalogue, move to
/// geohash ranges or a backend endpoint behind this same interface.
class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(this._ds);
  final MapDataSource _ds;

  static const batchSize = 100;
  static const maxScan = 300;

  @override
  Future<MapQueryResult> getPropertiesInViewport({
    required MapViewport viewport,
    PropertySearchFilter? filter,
    int limit = 150,
  }) async {
    try {
      if (!viewport.isValid) return const MapQueryResult(items: []);

      Object? cursor;
      var scanned = 0;
      var exhausted = false;
      final matched = <Property>[];
      final seen = <String>{};

      // limit + 1 matches prove that something was left out.
      while (matched.length <= limit && scanned < maxScan && !exhausted) {
        final batch = await _ds.fetchLatitudeBand(
          south: viewport.south,
          north: viewport.north,
          cursor: cursor,
          batchSize: batchSize,
        );
        scanned += batch.docs.length;
        cursor = batch.lastCursor;
        exhausted = batch.exhausted;

        for (final raw in batch.docs) {
          final p = PropertyMapper.tryFromMap(raw.id, raw.data);
          if (p == null) {
            debugPrint('Skipping malformed property ${raw.id}');
            continue;
          }
          // Defence in depth: never trust the query alone for visibility.
          if (!p.isPublic || !seen.add(p.id)) continue;
          if (!p.hasCoordinates) continue; // the mapper already nulls invalid coordinates
          if (!viewport.contains(p.latitude!, p.longitude!)) continue;
          if (filter != null && !SearchMatcher.matches(p, filter)) continue;
          matched.add(p);
        }
      }

      final truncated = matched.length > limit || (!exhausted && scanned >= maxScan);
      return MapQueryResult(items: matched.take(limit).toList(), truncated: truncated);
    } on FirebaseException catch (e) {
      // `failed-precondition` = missing composite index; the message holds the creation link.
      debugPrint('Map query failed [${e.code}]: ${e.message}');
      throw DiscoveryFailure(switch (e.code) {
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' => DiscoveryFailureType.network,
        'permission-denied' => DiscoveryFailureType.permissionDenied,
        _ => DiscoveryFailureType.unknown,
      });
    } on DiscoveryFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('Unexpected map error: $e\n$st');
      throw const DiscoveryFailure(DiscoveryFailureType.unknown);
    }
  }
}
