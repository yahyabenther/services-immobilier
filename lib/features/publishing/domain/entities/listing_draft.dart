import 'dart:typed_data';

import '../../../properties/domain/entities/property.dart';

/// One photo picked by the user and not yet uploaded. Pure Dart (no XFile) so the
/// whole module stays unit-testable.
class ListingPhoto {
  const ListingPhoto({required this.id, required this.name, required this.bytes});
  final String id;
  final String name;
  final Uint8List bytes;
}

/// A coordinate the USER confirmed (map tap or device position). Never invented.
class ListingCoordinates {
  const ListingCoordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is ListingCoordinates && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Everything the form collects. Numbers are kept as the TEXT the user typed and
/// parsed by [ListingValidator], so the field can show exactly what was entered.
class ListingDraft {
  const ListingDraft({
    this.propertyType,
    this.transactionType,
    this.governorate,
    this.city = '',
    this.area = '',
    this.coordinates,
    this.priceText = '',
    this.surfaceText = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.isStudio = false,
    this.isNewBuild = false,
    this.amenities = const {},
    this.photos = const [],
    this.title = '',
    this.description = '',
  });

  final PropertyType? propertyType;
  final TransactionType? transactionType;
  final String? governorate;
  final String city;
  final String area;
  final ListingCoordinates? coordinates;
  final String priceText;
  final String surfaceText;
  final int bedrooms;
  final int bathrooms;
  final bool isStudio;
  final bool isNewBuild;

  /// Amenity ids (see [Amenity]); stored in Firestore as a list.
  final Set<String> amenities;
  final List<ListingPhoto> photos;
  final String title;
  final String description;

  /// True once the user has typed / chosen anything (used for "discard?" prompts).
  bool get hasContent =>
      propertyType != null ||
      transactionType != null ||
      governorate != null ||
      city.trim().isNotEmpty ||
      area.trim().isNotEmpty ||
      coordinates != null ||
      priceText.trim().isNotEmpty ||
      surfaceText.trim().isNotEmpty ||
      amenities.isNotEmpty ||
      photos.isNotEmpty ||
      title.trim().isNotEmpty ||
      description.trim().isNotEmpty;

  ListingDraft copyWith({
    PropertyType? propertyType,
    TransactionType? transactionType,
    String? governorate,
    String? city,
    String? area,
    ListingCoordinates? coordinates,
    bool clearCoordinates = false,
    String? priceText,
    String? surfaceText,
    int? bedrooms,
    int? bathrooms,
    bool? isStudio,
    bool? isNewBuild,
    Set<String>? amenities,
    List<ListingPhoto>? photos,
    String? title,
    String? description,
  }) =>
      ListingDraft(
        propertyType: propertyType ?? this.propertyType,
        transactionType: transactionType ?? this.transactionType,
        governorate: governorate ?? this.governorate,
        city: city ?? this.city,
        area: area ?? this.area,
        coordinates: clearCoordinates ? null : (coordinates ?? this.coordinates),
        priceText: priceText ?? this.priceText,
        surfaceText: surfaceText ?? this.surfaceText,
        bedrooms: bedrooms ?? this.bedrooms,
        bathrooms: bathrooms ?? this.bathrooms,
        isStudio: isStudio ?? this.isStudio,
        isNewBuild: isNewBuild ?? this.isNewBuild,
        amenities: amenities ?? this.amenities,
        photos: photos ?? this.photos,
        title: title ?? this.title,
        description: description ?? this.description,
      );
}
