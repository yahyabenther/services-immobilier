import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/property_summary.dart';
import '../../domain/entities/search_enums.dart';

class PropertySummaryModel {
  const PropertySummaryModel._();

  static T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }

  static PropertySummary fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final created = d['createdAt'];
    return PropertySummary(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      price: (d['price'] as num?)?.toDouble() ?? 0,
      transactionType:
          _enum(TransactionType.values, d['transactionType'], TransactionType.buy),
      propertyType:
          _enum(PropertyType.values, d['propertyType'], PropertyType.apartment),
      governorate: (d['governorate'] ?? '') as String,
      city: (d['city'] ?? '') as String,
      area: d['area'] as String?,
      bedrooms: (d['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (d['bathrooms'] as num?)?.toInt() ?? 0,
      surface: (d['surface'] as num?)?.toDouble() ?? 0,
      amenities: {
        for (final a in (d['amenities'] as List? ?? const []))
          for (final v in Amenity.values)
            if (v.name == a) v,
      },
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? const []),
      createdAt: created is Timestamp ? created.toDate() : null,
      lat: (d['latitude'] as num?)?.toDouble(),
      lng: (d['longitude'] as num?)?.toDouble(),
    );
  }
}