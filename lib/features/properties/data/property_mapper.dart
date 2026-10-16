import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/tunisia_governorates.dart';
import '../domain/entities/property.dart';

/// Firestore map -> [Property]. Returns null for documents that are too
/// malformed to display (missing title / price / location / owner /
/// transaction type) so one bad document can never break a list.
/// Nothing is ever invented: unknown optional facts stay null.
class PropertyMapper {
  PropertyMapper._();

  static Property? tryFromMap(String id, Map<String, dynamic> d) {
    final title = _string(d['title']);
    final price = _num(d['price']);
    final owner = _string(d['ownerId']);
    final tx = TransactionType.parse(_string(d['transactionType']));
    final city = _string(d['city']);
    final governorate = _string(d['governorate']) ??
        // Legacy documents (first Home seeder) stored the governorate in `city`.
        (city != null && tunisiaGovernorates.contains(city) ? city : null);
    if (title == null || price == null || price < 0 || governorate == null || owner == null || tx == null) {
      return null;
    }

    final lat = _num(d['latitude'])?.toDouble();
    final lng = _num(d['longitude'])?.toDouble();
    final validCoords = lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180;

    return Property(
      id: id,
      ownerId: owner,
      agentId: _string(d['agentId']),
      ownerName: _string(d['ownerName']),
      ownerRole: _string(d['ownerRole']),
      title: title,
      description: _string(d['description']) ?? '',
      transactionType: tx,
      propertyType: PropertyType.parse(_string(d['propertyType'])),
      price: price,
      currency: _string(d['currency']) ?? 'TND',
      surface: _positive(d['surface']),
      bedrooms: _positive(d['bedrooms'])?.toInt(),
      bathrooms: _positive(d['bathrooms'])?.toInt(),
      isStudio: d['isStudio'] == true,
      isNewBuild: d['isNewBuild'] == true,
      governorate: governorate,
      city: city == governorate ? null : city,
      area: _string(d['area']),
      latitude: validCoords ? lat : null,
      longitude: validCoords ? lng : null,
      images: _stringList(d['images']),
      amenities: _stringList(d['amenities']),
      status: PropertyStatus.parse(_string(d['status'])),
      verificationStatus: VerificationStatus.parse(_string(d['verificationStatus'])),
      views: _num(d['views'])?.toInt() ?? 0,
      favoritesCount: _num(d['favoritesCount'])?.toInt() ?? 0,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
      publishedAt: _date(d['publishedAt']),
    );
  }

  static String? _string(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static num? _num(Object? v) => v is num ? v : null;

  /// Zero / negative facts are treated as "unknown" so cards never show "0 beds".
  static num? _positive(Object? v) {
    final n = _num(v);
    return (n != null && n > 0) ? n : null;
  }

  static List<String> _stringList(Object? v) =>
      v is List ? v.whereType<String>().where((s) => s.trim().isNotEmpty).toList() : const [];

  static DateTime? _date(Object? v) => switch (v) {
        Timestamp t => t.toDate(),
        DateTime d => d,
        _ => null,
      };
}
