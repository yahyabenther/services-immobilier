import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../properties/domain/entities/property.dart';

typedef RawProperty = ({String id, Map<String, dynamic> data});

/// The only discovery class that talks to Firestore. All queries are limited
/// and filtered server-side on `status == published`.
class PropertyDiscoveryRemoteDataSource {
  PropertyDiscoveryRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  Query<Map<String, dynamic>> get _published => _db
      .collection('properties')
      .where('status', isEqualTo: PropertyStatus.published.wire);

  List<RawProperty> _raw(QuerySnapshot<Map<String, dynamic>> s) =>
      [for (final d in s.docs) (id: d.id, data: d.data())];

  /// Most recently published listings (index: status ASC, publishedAt DESC).
  Future<List<RawProperty>> fetchRecent({required int limit}) async =>
      _raw(await _published.orderBy('publishedAt', descending: true).limit(limit).get());

  /// Recent listings of one governorate (index: status ASC, governorate ASC, publishedAt DESC).
  Future<List<RawProperty>> fetchRecentInGovernorate(String governorate, {required int limit}) async => _raw(await _published
      .where('governorate', isEqualTo: governorate)
      .orderBy('publishedAt', descending: true)
      .limit(limit)
      .get());

  /// Latitude band (index: status ASC, latitude ASC). Longitude and exact
  /// distance are filtered by the repository.
  Future<List<RawProperty>> fetchInLatitudeBand(double minLat, double maxLat, {required int limit}) async =>
      _raw(await _published
          .where('latitude', isGreaterThanOrEqualTo: minLat)
          .where('latitude', isLessThanOrEqualTo: maxLat)
          .limit(limit)
          .get());
}
