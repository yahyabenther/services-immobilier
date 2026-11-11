import '../../../../core/constants/tunisia_governorates.dart';
import '../../../properties/domain/entities/amenity.dart';
import '../entities/listing_draft.dart';
import '../entities/property_type_rules.dart';
import '../publishing_config.dart';

enum ListingField {
  propertyType,
  transactionType,
  governorate,
  city,
  area,
  coordinates,
  price,
  surface,
  bedrooms,
  bathrooms,
  amenities,
  photos,
  title,
  description,
}

/// The wizard screens. The spec's 11 steps are grouped into 7 screens; every
/// field of the reference journey is still collected.
enum PublishStep {
  type('Property type', {ListingField.propertyType, ListingField.transactionType}),
  location('Location', {ListingField.governorate, ListingField.city, ListingField.area, ListingField.coordinates}),
  details('Price & details', {ListingField.price, ListingField.surface, ListingField.bedrooms, ListingField.bathrooms}),
  amenities('Amenities', {ListingField.amenities}),
  photos('Photos', {ListingField.photos}),
  description('Title & description', {ListingField.title, ListingField.description}),
  preview('Preview', {});

  const PublishStep(this.label, this.fields);
  final String label;
  final Set<ListingField> fields;

  PublishStep? get next => index + 1 < PublishStep.values.length ? PublishStep.values[index + 1] : null;
  PublishStep? get previous => index > 0 ? PublishStep.values[index - 1] : null;
}

/// Pure validation (unit-tested). The UI uses it to guide the user; the Firestore
/// rules repeat the essential checks because the client is never trusted.
class ListingValidator {
  ListingValidator._();

  static final _digits = RegExp(r'^\d+$');
  static final _decimal = RegExp(r'^\d+([.,]\d+)?$');
  static final _spaces = RegExp(r'[\s\u00A0\u202F]');

  /// Whole TND amount, or null when [raw] is not a plain whole number.
  static int? parsePrice(String? raw) {
    final s = (raw ?? '').replaceAll(_spaces, '');
    return _digits.hasMatch(s) ? int.tryParse(s) : null;
  }

  /// `120`, `120.5` or `120,5`. Anything ambiguous ("1,200.5", "12a") is rejected.
  static double? parseSurface(String? raw) {
    final s = (raw ?? '').replaceAll(_spaces, '');
    if (!_decimal.hasMatch(s)) return null;
    final v = double.tryParse(s.replaceAll(',', '.'));
    return (v == null || v.isNaN || v.isInfinite) ? null : v;
  }

  static Map<ListingField, String> validate(ListingDraft d) {
    final e = <ListingField, String>{};
    final type = d.propertyType;

    if (type == null || !publishablePropertyTypes.contains(type)) {
      e[ListingField.propertyType] = 'Choose a property type.';
    }
    if (d.transactionType == null) {
      e[ListingField.transactionType] = 'Choose whether the property is for sale or for rent.';
    }

    final gov = d.governorate;
    if (gov == null || !tunisiaGovernorates.contains(gov)) {
      e[ListingField.governorate] = 'Select the governorate of the property.';
    }
    final city = d.city.trim();
    if (city.isEmpty) {
      e[ListingField.city] = 'Please enter the city.';
    } else if (city.length > PublishingConfig.cityMax) {
      e[ListingField.city] = 'The city name is too long.';
    }
    if (d.area.trim().length > PublishingConfig.areaMax) {
      e[ListingField.area] = 'The area name is too long.';
    }
    final c = d.coordinates;
    if (c != null &&
        !(c.latitude >= PublishingConfig.minLat &&
            c.latitude <= PublishingConfig.maxLat &&
            c.longitude >= PublishingConfig.minLng &&
            c.longitude <= PublishingConfig.maxLng)) {
      e[ListingField.coordinates] = 'The pinned position is outside Tunisia. Move the pin.';
    }

    final price = parsePrice(d.priceText);
    if (price == null) {
      e[ListingField.price] = d.priceText.trim().isEmpty
          ? 'Enter the price in TND.'
          : 'Enter the price as a whole number (digits only).';
    } else if (price <= 0) {
      e[ListingField.price] = 'The price must be greater than zero.';
    } else if (price > PublishingConfig.maxPrice) {
      e[ListingField.price] = 'This price looks too high. Please check it.';
    }

    final surface = parseSurface(d.surfaceText);
    if (surface == null) {
      e[ListingField.surface] = 'Please enter a valid surface in m².';
    } else if (surface <= 0) {
      e[ListingField.surface] = 'The surface must be greater than zero.';
    } else if (surface > PublishingConfig.maxSurface) {
      e[ListingField.surface] = 'This surface looks too large. Please check it.';
    }

    if (type != null) {
      if (type.usesBedrooms && !(type.allowsStudio && d.isStudio)) {
        if (d.bedrooms < 1) {
          e[ListingField.bedrooms] = type.allowsStudio
              ? 'Enter the number of bedrooms, or mark the apartment as a studio.'
              : 'Enter the number of bedrooms.';
        } else if (d.bedrooms > PublishingConfig.maxRooms) {
          e[ListingField.bedrooms] = 'That number of bedrooms looks too high.';
        }
      }
      if (type.usesBathrooms) {
        if (type.requiresBathroom && d.bathrooms < 1) {
          e[ListingField.bathrooms] = 'Enter at least one bathroom.';
        } else if (d.bathrooms < 0 || d.bathrooms > PublishingConfig.maxRooms) {
          e[ListingField.bathrooms] = 'That number of bathrooms looks wrong.';
        }
      }
    }

    if (d.amenities.any((a) => Amenity.tryParse(a) == null)) {
      e[ListingField.amenities] = 'One of the selected amenities is not supported.';
    }

    if (d.photos.length < PublishingConfig.minPhotos) {
      e[ListingField.photos] = 'Add at least one photo of the property.';
    } else if (d.photos.length > PublishingConfig.maxPhotos) {
      e[ListingField.photos] = 'You can add up to ${PublishingConfig.maxPhotos} photos.';
    }

    final title = d.title.trim();
    if (title.isEmpty) {
      e[ListingField.title] = 'Please enter a title for your listing.';
    } else if (title.length < PublishingConfig.titleMin) {
      e[ListingField.title] = 'The title is too short (at least ${PublishingConfig.titleMin} characters).';
    } else if (title.length > PublishingConfig.titleMax) {
      e[ListingField.title] = 'The title is too long (max ${PublishingConfig.titleMax} characters).';
    }

    final description = d.description.trim();
    if (description.isEmpty) {
      e[ListingField.description] = 'Please add a description.';
    } else if (description.length < PublishingConfig.descriptionMin) {
      e[ListingField.description] =
          'The description is too short (at least ${PublishingConfig.descriptionMin} characters).';
    } else if (description.length > PublishingConfig.descriptionMax) {
      e[ListingField.description] = 'The description is too long (max ${PublishingConfig.descriptionMax} characters).';
    }

    return e;
  }

  /// Errors of one wizard screen. The preview screen checks everything.
  static Map<ListingField, String> validateStep(PublishStep step, ListingDraft d) {
    final all = validate(d);
    if (step == PublishStep.preview) return all;
    return {for (final e in all.entries) if (step.fields.contains(e.key)) e.key: e.value};
  }
}
