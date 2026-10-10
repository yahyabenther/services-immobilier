import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../search/domain/entities/search_enums.dart';
import '../../domain/entities/property.dart';

class PropertyModel {
  const PropertyModel._();

  static T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

  static Property fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Property(
      id: doc.id,
      ownerId: (d['ownerId'] ?? '') as String,
      agentId: d['agentId'] as String?,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      transactionType:
          _enum(TransactionType.values, d['transactionType'], TransactionType.buy),
      propertyType:
          _enum(PropertyType.values, d['propertyType'], PropertyType.apartment),
      price: (d['price'] as num?)?.toDouble() ?? 0,
      currency: (d['currency'] ?? 'TND') as String,
      surface: (d['surface'] as num?)?.toDouble() ?? 0,
      bedrooms: (d['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (d['bathrooms'] as num?)?.toInt() ?? 0,
      governorate: (d['governorate'] ?? '') as String,
      city: (d['city'] ?? '') as String,
      area: d['area'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? const []),
      amenities: {
        for (final a in (d['amenities'] as List? ?? const []))
          for (final v in Amenity.values)
            if (v.name == a) v,
      },
      status: (d['status'] ?? 'published') as String,
      verificationStatus: (d['verificationStatus'] ?? 'none') as String,
      views: (d['views'] as num?)?.toInt() ?? 0,
      favoritesCount: (d['favoritesCount'] as num?)?.toInt() ?? 0,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }
}