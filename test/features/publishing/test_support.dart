import 'dart:typed_data';

import 'package:team_app/features/auth/domain/entities/auth_user.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/publishing/domain/entities/listing_draft.dart';
import 'package:team_app/features/publishing/domain/publishing_failure.dart';
import 'package:team_app/features/publishing/domain/repositories/listing_repository.dart';

const owner = AuthUser(id: 'u1', email: 'o@x.tn', name: 'Karim', role: UserRole.owner, emailVerified: true);
const agent = AuthUser(id: 'a1', email: 'a@x.tn', name: 'Sana', role: UserRole.agent, emailVerified: true);
const plainUser = AuthUser(id: 'u2', email: 'u@x.tn', role: UserRole.user, emailVerified: true);

ListingPhoto photo(String id) => ListingPhoto(id: id, name: '$id.jpg', bytes: Uint8List.fromList([1, 2, 3]));

/// A draft that passes every rule: tests change one field at a time.
ListingDraft validDraft({List<ListingPhoto>? photos}) => ListingDraft(
      propertyType: PropertyType.apartment,
      transactionType: TransactionType.rent,
      governorate: 'Tunis',
      city: 'La Marsa',
      area: 'Centre',
      coordinates: const ListingCoordinates(36.88, 10.32),
      priceText: '1800',
      surfaceText: '110',
      bedrooms: 2,
      bathrooms: 1,
      amenities: const {'parking', 'balcony'},
      photos: photos ?? [photo('p1'), photo('p2')],
      title: 'Bright S+2 apartment in La Marsa',
      description: 'Apartment with balcony and parking, close to the beach.',
    );

class FakeListingRepository implements ListingRepository {
  final failUploads = <String>{};
  final uploadCalls = <String>[];
  final created = <Map<String, Object?>>[];
  var createFails = false;

  @override
  String newListingId() => 'listing-1';

  @override
  Future<String> uploadPhoto({required String listingId, required ListingPhoto photo}) async {
    uploadCalls.add(photo.id);
    if (failUploads.contains(photo.id)) throw const PublishingFailure(PublishingFailureType.uploadFailed);
    return 'https://res.cloudinary.com/demo/image/upload/${photo.id}.jpg';
  }

  @override
  Future<void> createListing({
    required String listingId,
    required ListingDraft draft,
    required AuthUser user,
    required List<String> imageUrls,
  }) async {
    if (createFails) throw const PublishingFailure(PublishingFailureType.network);
    created.add({'id': listingId, 'user': user.id, 'urls': imageUrls});
  }
}
