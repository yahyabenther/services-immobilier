import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/discovery_failure.dart';
import '../../../../core/utils/geo.dart';
import '../../../properties/data/property_mapper.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/discovery_location.dart';
import '../../domain/repositories/property_discovery_repository.dart';
import '../../domain/services/recommendation_ranker.dart';
import '../datasources/property_discovery_remote_data_source.dart';

class PropertyDiscoveryRepositoryImpl implements PropertyDiscoveryRepository {
  PropertyDiscoveryRepositoryImpl(this._ds, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final PropertyDiscoveryRemoteDataSource _ds;
  final DateTime Function() _now;

  /// Home recommendations are ranked inside the N most recent published listings
  /// (so "popular" means popular among recent ones). Implementation decision.
  static const recommendationWindow = 30;

  /// Nearby radius when the device position is used. Implementation decision.
  static const nearbyRadiusKm = 10.0;
  static const _bandFetchLimit = 60;
  static const _governorateFetchLimit = 30;

  List<Property> _parse(List<RawProperty> raw) {
    final out = <Property>[];
    for (final r in raw) {
      final p = PropertyMapper.tryFromMap(r.id, r.data);
      if (p == null) {
        debugPrint('Skipping malformed property ${r.id}');
        continue;
      }
      // Defence in depth: the query already filters, never trust it alone.
      if (p.isPublic) out.add(p);
    }
    return out;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FirebaseException catch (e) {
      // `failed-precondition` = missing composite index; the message holds the creation link.
      debugPrint('Discovery query failed [${e.code}]: ${e.message}');
      throw DiscoveryFailure(switch (e.code) {
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' => DiscoveryFailureType.network,
        'permission-denied' => DiscoveryFailureType.permissionDenied,
        _ => DiscoveryFailureType.unknown,
      });
    } catch (e, st) {
      debugPrint('Discovery unexpected error: $e\n$st');
      throw const DiscoveryFailure(DiscoveryFailureType.unknown);
    }
  }

  @override
  Future<List<Property>> getRecommendedProperties({int limit = 10}) => _guard(() async {
        final recent = _parse(await _ds.fetchRecent(limit: recommendationWindow));
        return RecommendationRanker.rank(recent, now: _now(), limit: limit);
      });

  @override
  Future<List<Property>> getNearbyProperties({
    required DiscoveryLocation location,
    int limit = 10,
  }) =>
      _guard(() async {
        if (location.hasCoordinates) {
          final lat = location.latitude!;
          final lng = location.longitude!;
          final box = boundingBox(lat, lng, nearbyRadiusKm);
          final candidates = _parse(await _ds.fetchInLatitudeBand(box.minLat, box.maxLat, limit: _bandFetchLimit))
              .where((p) => p.hasCoordinates)
              .map((p) => (p: p, d: distanceKm(lat, lng, p.latitude!, p.longitude!)))
              .where((e) => e.d <= nearbyRadiusKm)
              .toList()
            ..sort((a, b) => a.d.compareTo(b.d));
          return [for (final e in candidates.take(limit)) e.p];
        }
        final governorate = location.governorate;
        if (governorate == null) return const [];
        return _parse(await _ds.fetchRecentInGovernorate(governorate, limit: _governorateFetchLimit))
            .take(limit)
            .toList();
      });
}
