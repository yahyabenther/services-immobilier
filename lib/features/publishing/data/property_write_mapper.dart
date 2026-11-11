import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/entities/auth_user.dart';
import '../domain/entities/listing_draft.dart';
import '../domain/entities/property_type_rules.dart';
import '../domain/publishing_config.dart';
import '../domain/services/listing_validator.dart';
import '../../properties/domain/entities/property.dart';

/// [ListingDraft] -> the Firestore document of a NEW listing. The key set is
/// exactly the one allowed by `validNewListing` in firestore.rules: when you add a
/// field here, add it there too (or creation is denied).
///
/// Call only after [ListingValidator.validate] passed (the use case guarantees it).
class PropertyWriteMapper {
  PropertyWriteMapper._();

  static Map<String, dynamic> newListing({
    required ListingDraft draft,
    required AuthUser user,
    required List<String> imageUrls,
  }) {
    final type = draft.propertyType!;
    final isAgent = user.role == UserRole.agent;
    final studio = type.allowsStudio && draft.isStudio;
    final rawName = user.name?.trim();
    // Same cap as the rules (ownerName <= 120): a very long profile name must not block publishing.
    final name = (rawName != null && rawName.length > 120) ? rawName.substring(0, 120) : rawName;
    final city = draft.city.trim();
    final area = draft.area.trim();
    final coords = draft.coordinates;
    final now = FieldValue.serverTimestamp();

    return {
      // ---- who ----------------------------------------------------------------
      'ownerId': user.id,
      // An agent publishes on their own account: the agent rules (Module 10) and
      // the chat recipient logic both key on `agentId`.
      'agentId': isAgent ? user.id : null,
      if (name != null && name.isNotEmpty) 'ownerName': name,
      'ownerRole': isAgent ? 'agent' : 'owner',
      // ---- what ---------------------------------------------------------------
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'transactionType': draft.transactionType!.name, // `buy` | `rent`
      'propertyType': type.name,
      'price': ListingValidator.parsePrice(draft.priceText)!, // number, never "250 000 TND"
      'currency': PublishingConfig.currency,
      'surface': ListingValidator.parseSurface(draft.surfaceText)!,
      if (type.usesBedrooms && !studio) 'bedrooms': draft.bedrooms,
      if (type.usesBathrooms) 'bathrooms': draft.bathrooms,
      'isStudio': studio,
      'isNewBuild': draft.isNewBuild,
      // ---- where --------------------------------------------------------------
      'governorate': draft.governorate!,
      'city': city,
      if (area.isNotEmpty) 'area': area,
      if (coords != null) ...{'latitude': coords.latitude, 'longitude': coords.longitude},
      // ---- media / features ---------------------------------------------------
      'images': imageUrls,
      'amenities': draft.amenities.toList()..sort(),
      // ---- lifecycle: always starts in moderation, never published ------------
      'status': PropertyStatus.pendingReview.wire,
      'verificationStatus': 'not_submitted',
      'views': 0,
      'favoritesCount': 0,
      'createdAt': now,
      'updatedAt': now,
      'publishedAt': null, // set by the admin approval (Module 15)
    };
  }
}
