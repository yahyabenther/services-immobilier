import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../search/data/models/property_summary_model.dart';
import '../../../search/domain/entities/property_summary.dart';
import '../../domain/entities/property.dart';
import '../models/property_model.dart';

class FirestorePropertyDatasource {
  FirestorePropertyDatasource(this._db);
  final FirebaseFirestore _db;

  Future<Property?> getById(String id) async {
    final doc = await _db.collection('properties').doc(id).get();
    if (!doc.exists) return null;
    return PropertyModel.fromDoc(doc);
  }

  Future<List<PropertySummary>> getSimilar(Property p, {int limit = 6}) async {
    // Que des filtres d'égalité: pas besoin d'index composite.
    final snap = await _db
        .collection('properties')
        .where('status', isEqualTo: 'published')
        .where('propertyType', isEqualTo: p.propertyType.name)
        .where('city', isEqualTo: p.city)
        .limit(limit + 1)
        .get();

    return snap.docs
        .where((d) => d.id != p.id)
        .take(limit)
        .map(PropertySummaryModel.fromDoc)
        .toList();
  }
}