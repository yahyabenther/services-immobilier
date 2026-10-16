import '../../../../core/utils/text_normalizer.dart';
import '../../../properties/domain/entities/amenity.dart';
import '../../../properties/domain/entities/property.dart';
import '../entities/property_search_filter.dart';
import '../entities/search_enums.dart';

/// Decides whether ONE property satisfies a filter. Pure and unit-tested.
///
/// Rules worth knowing:
/// - A property with an UNKNOWN value never matches a filter on that value
///   (no bedrooms info -> excluded by a bedroom filter; no surface -> excluded by a
///   surface filter). Nothing is invented.
/// - Amenities use AND semantics.
/// - City / area / text query are accent- and case-insensitive.
class SearchMatcher {
  const SearchMatcher._();

  static bool matches(Property p, PropertySearchFilter f) {
    if (f.transactionType != null && p.transactionType != f.transactionType) return false;
    if (f.newBuildOnly && !p.isNewBuild) return false;
    if (f.propertyType != null && p.propertyType != f.propertyType) return false;

    if (!_sameText(p.governorate, f.governorate)) return false;
    if (!_containsText(p.city, f.city)) return false;
    if (!_containsText(p.area, f.area)) return false;

    if (f.minPrice != null && p.price < f.minPrice!) return false;
    if (f.maxPrice != null && p.price > f.maxPrice!) return false;

    if (f.minSurface != null || f.maxSurface != null) {
      final s = p.surface;
      if (s == null) return false;
      if (f.minSurface != null && s < f.minSurface!) return false;
      if (f.maxSurface != null && s > f.maxSurface!) return false;
    }

    if (f.bedrooms != null && !_bedroomsMatch(p, f.bedrooms!)) return false;
    if (f.bathrooms != null && !_bathroomsMatch(p, f.bathrooms!)) return false;

    if (f.amenities.isNotEmpty) {
      final have = {for (final a in p.amenities) a};
      for (final Amenity a in f.amenities) {
        if (!have.contains(a.id)) return false;
      }
    }

    if (f.hasQuery && !_queryMatches(p, f.queryText!)) return false;
    return true;
  }

  static bool _bedroomsMatch(Property p, BedroomChoice c) {
    if (c == BedroomChoice.studio) return p.isStudio;
    if (p.isStudio) return false;
    final n = p.bedrooms;
    if (n == null) return false;
    return switch (c) {
      BedroomChoice.one => n == 1,
      BedroomChoice.two => n == 2,
      BedroomChoice.three => n == 3,
      BedroomChoice.fourPlus => n >= 4,
      BedroomChoice.studio => false,
    };
  }

  static bool _bathroomsMatch(Property p, BathroomChoice c) {
    final n = p.bathrooms;
    if (n == null) return false;
    return switch (c) {
      BathroomChoice.one => n == 1,
      BathroomChoice.two => n == 2,
      BathroomChoice.threePlus => n >= 3,
    };
  }

  static bool _sameText(String? value, String? wanted) {
    if (wanted == null || wanted.trim().isEmpty) return true;
    return TextNormalizer.normalize(value) == TextNormalizer.normalize(wanted);
  }

  static bool _containsText(String? value, String? wanted) {
    if (wanted == null || wanted.trim().isEmpty) return true;
    return TextNormalizer.normalize(value).contains(TextNormalizer.normalize(wanted));
  }

  /// Every word of the query must appear somewhere in title / location / type.
  /// (Firestore has no full-text search; this matches inside the scanned results.)
  static bool _queryMatches(Property p, String query) {
    final hay = TextNormalizer.normalize(
      '${p.title} ${p.governorate} ${p.city ?? ''} ${p.area ?? ''} ${p.propertyType.name}',
    );
    return TextNormalizer.tokens(query).every(hay.contains);
  }
}
