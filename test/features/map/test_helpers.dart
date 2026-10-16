import '../../../lib/features/properties/domain/entities/property.dart';

Property prop(
  String id, {
  double? lat,
  double? lng,
  PropertyStatus status = PropertyStatus.published,
  TransactionType tx = TransactionType.rent,
  String governorate = 'Tunis',
}) =>
    Property(
      id: id,
      ownerId: 'owner',
      title: 'Listing $id',
      transactionType: tx,
      propertyType: PropertyType.apartment,
      price: 1000,
      currency: 'TND',
      governorate: governorate,
      status: status,
      verificationStatus: VerificationStatus.notSubmitted,
      latitude: lat,
      longitude: lng,
    );

Map<String, dynamic> doc({
  String status = 'published',
  Object? lat = 36.8,
  Object? lng = 10.18,
  String tx = 'rent',
  String governorate = 'Tunis',
}) =>
    {
      'title': 'Apartment',
      'price': 1200,
      'ownerId': 'owner',
      'transactionType': tx,
      'governorate': governorate,
      'status': status,
      'latitude': lat,
      'longitude': lng,
    };
