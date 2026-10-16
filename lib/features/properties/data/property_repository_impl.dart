import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/property_failure.dart';
import '../domain/entities/property.dart';
import '../domain/repositories/property_repository.dart';
import '../domain/services/similar_property_ranker.dart';
import 'property_mapper.dart';
import 'property_remote_data_source.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  PropertyRepositoryImpl(this._ds);
  final PropertyRemoteDataSource _ds;

  static const _similarWindow = 30;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PropertyFailure {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Property query failed [${e.code}]: ${e.message}');
      throw PropertyFailure(switch (e.code) {
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' => PropertyFailureType.network,
        // Rules deny reads of non-public documents: to the user that is "unavailable".
        'permission-denied' => PropertyFailureType.unavailable,
        _ => PropertyFailureType.unknown,
      });
    } catch (e, st) {
      debugPrint('Unexpected property error: $e\n$st');
      throw const PropertyFailure(PropertyFailureType.unknown);
    }
  }

  @override
  Future<Property> getPropertyById(String id) => _guard(() async {
        if (id.trim().isEmpty) throw const PropertyFailure(PropertyFailureType.notFound);
        final raw = await _ds.getById(id);
        if (raw == null) throw const PropertyFailure(PropertyFailureType.notFound);
        final p = PropertyMapper.tryFromMap(raw.id, raw.data);
        if (p == null || !p.isPublic) throw const PropertyFailure(PropertyFailureType.unavailable);
        return p;
      });

  @override
  Future<List<Property>> getSimilarProperties(Property property, {int limit = 6}) => _guard(() async {
        final raw = await _ds.fetchRecentInGovernorate(property.governorate, limit: _similarWindow);
        final parsed = <Property>[
          for (final r in raw)
            ?PropertyMapper.tryFromMap(r.id, r.data),
        ];
        return SimilarPropertyRanker.rank(property, parsed, limit: limit);
      });
}
