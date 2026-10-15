/// Shared property entity used by every module (discovery, search, details,
/// map, favorites, publishing). Do not create module-specific copies.
enum TransactionType {
  buy,
  rent;

  /// Accepts `buy`/`sale` and `rent`; anything else is rejected (null).
  static TransactionType? parse(String? v) => switch (v?.toLowerCase()) {
        'buy' || 'sale' => TransactionType.buy,
        'rent' => TransactionType.rent,
        _ => null,
      };
}

enum PropertyType {
  apartment,
  villa,
  house,
  duplex,
  triplex,
  land,
  office,
  commercial,
  industrial,
  other;

  static PropertyType parse(String? v) =>
      PropertyType.values.firstWhere((t) => t.name == v, orElse: () => PropertyType.other);
}

/// Listing lifecycle (distinct from [VerificationStatus]).
enum PropertyStatus {
  draft,
  pendingReview,
  published,
  rejected,
  suspended,
  removed,
  expired;

  /// Firestore value, e.g. `pending_review`.
  String get wire => switch (this) {
        PropertyStatus.pendingReview => 'pending_review',
        _ => name,
      };

  /// Unknown values map to [draft]: never public by accident.
  static PropertyStatus parse(String? v) =>
      PropertyStatus.values.firstWhere((s) => s.wire == v, orElse: () => PropertyStatus.draft);
}

/// Source study values: not_submitted, pending, approved, rejected, expired.
/// Only [approved] shows a badge. (`verified` is accepted as a legacy alias.)
enum VerificationStatus {
  notSubmitted,
  pending,
  approved,
  rejected,
  expired;

  static VerificationStatus parse(String? v) => switch (v) {
        'approved' || 'verified' => VerificationStatus.approved,
        'pending' => VerificationStatus.pending,
        'rejected' => VerificationStatus.rejected,
        'expired' => VerificationStatus.expired,
        _ => VerificationStatus.notSubmitted, // includes 'not_submitted', 'unverified', unknown
      };
}

class Property {
  const Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.transactionType,
    required this.propertyType,
    required this.price,
    required this.currency,
    required this.governorate,
    required this.status,
    required this.verificationStatus,
    this.agentId,
    this.ownerName,
    this.ownerRole,
    this.description = '',
    this.surface,
    this.bedrooms,
    this.bathrooms,
    this.isStudio = false,
    this.isNewBuild = false,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.images = const [],
    this.amenities = const [],
    this.views = 0,
    this.favoritesCount = 0,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  final String id;
  final String ownerId;
  final String? agentId;

  /// PUBLIC display fields copied onto the listing by the publisher (Module 08).
  /// Never read from the private `users/{uid}` document.
  final String? ownerName;

  /// `owner` | `agent` | `agency` (display label only).
  final String? ownerRole;
  final String title;
  final String description;
  final TransactionType transactionType;
  final PropertyType propertyType;
  final num price;
  final String currency;
  final num? surface;

  /// Bedroom count when known and > 0. A studio is NOT "0 bedrooms": it is [isStudio].
  final int? bedrooms;
  final int? bathrooms;
  final bool isStudio;

  /// "New" in the search tabs = new-build property (product decision, see README).
  final bool isNewBuild;

  /// Location hierarchy: governorate (required) > city > area.
  final String governorate;
  final String? city;
  final String? area;
  final double? latitude;
  final double? longitude;

  /// Cloudinary `secure_url` strings (Module 08 uploads; this app only reads them).
  final List<String> images;

  /// Amenity ids, see [Amenity].
  final List<String> amenities;
  final PropertyStatus status;
  final VerificationStatus verificationStatus;
  final int views;
  final int favoritesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  /// Only an approved verification shows the badge (spec §8.9).
  bool get isVerified => verificationStatus == VerificationStatus.approved;
  bool get isPublic => status == PropertyStatus.published;
  bool get hasCoordinates => latitude != null && longitude != null;
  String? get mainImage => images.isEmpty ? null : images.first;

  /// Most specific place + governorate: "La Marsa, Tunis" / "Sfax".
  String get locationLabel {
    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final specific = clean(area) ?? clean(city);
    if (specific == null || specific.toLowerCase() == governorate.toLowerCase()) return governorate;
    return '$specific, $governorate';
  }
}
