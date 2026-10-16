import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/property.dart';

typedef RawPropertyDoc = ({String id, Map<String, dynamic> data});

class PropertyRemoteDataSource {
  PropertyRemoteDataSource(this._db);
  final FirebaseFirestore _db;

  /// Null when the document does not exist.
  Future<RawPropertyDoc?> getById(String id) async {
    final snap = await _db.collection('properties').doc(id).get();
    final data = snap.data();
    return (!snap.exists || data == null) ? null : (id: snap.id, data: data);
  }

  /// Recent published listings of one governorate
  /// (index: status ASC, governorate ASC, publishedAt DESC).
  Future<List<RawPropertyDoc>> fetchRecentInGovernorate(String governorate, {required int limit}) async {
    final snap = await _db
        .collection('properties')
        .where('status', isEqualTo: PropertyStatus.published.wire)
        .where('governorate', isEqualTo: governorate)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .get();
    return [for (final d in snap.docs) (id: d.id, data: d.data())];
  }
}
