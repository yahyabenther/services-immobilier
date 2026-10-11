import '../../../search/domain/entities/search_enums.dart';

class Property {
  final String id;
  final String ownerId;
  final String? ownerName;
  final String ownerRole; // owner | agent | agency
  final String? agentId;
  final String title;
  final String description;
  final TransactionType transactionType;
  final PropertyType propertyType;
  final double price;
  final String currency;
  final double surface;
  final int bedrooms;
  final int bathrooms;
  final String governorate;
  final String city;
  final String? area;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final Set<Amenity> amenities;
  final String status; // published, pending_review...
  final String verificationStatus; // verified, pending, none
  final int views;
  final int favoritesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Property({
    required this.id,
    required this.ownerId,
    this.ownerName,
    this.ownerRole = 'owner',
    this.agentId,
    required this.title,
    this.description = '',
    required this.transactionType,
    required this.propertyType,
    required this.price,
    this.currency = 'TND',
    this.surface = 0,
    this.bedrooms = 0,
    this.bathrooms = 0,
    required this.governorate,
    required this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.imageUrls = const [],
    this.amenities = const {},
    this.status = 'published',
    this.verificationStatus = 'none',
    this.views = 0,
    this.favoritesCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isVerified => verificationStatus == 'verified';
  bool get hasLocation => latitude != null && longitude != null;
}