import 'package:cloud_firestore/cloud_firestore.dart';

import '../../properties/data/property_mapper.dart';
import '../../properties/domain/entities/property.dart';

/// Owner-side access to the `properties` collection (Module 09).
class MyListingsRepository {
  MyListingsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('properties');

  /// Every listing of [ownerId], any status, newest first.
  /// No orderBy -> no composite index needed; sorted on the client.
  Stream<List<Property>> watchMine(String ownerId) {
    return _col.where('ownerId', isEqualTo: ownerId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => PropertyMapper.tryFromMap(d.id, d.data()))
          .whereType<Property>()
          .toList();
      DateTime key(Property p) => p.updatedAt ?? p.createdAt ?? DateTime(2000);
      list.sort((a, b) => key(b).compareTo(key(a)));
      return list;
    });
  }

  Future<void> setStatus(String id, PropertyStatus status) => _col.doc(id).update({
        'status': status.wire,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) => _col.doc(id).delete();
}