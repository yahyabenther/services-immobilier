import '../../../properties/domain/entities/property.dart';

/// Types offered in the form (`other` exists only for legacy documents).
const publishablePropertyTypes = [
  PropertyType.apartment,
  PropertyType.villa,
  PropertyType.house,
  PropertyType.duplex,
  PropertyType.triplex,
  PropertyType.land,
  PropertyType.office,
  PropertyType.commercial,
  PropertyType.industrial,
];

extension PublishPropertyType on PropertyType {
  String get label => switch (this) {
        PropertyType.apartment => 'Apartment',
        PropertyType.villa => 'Villa',
        PropertyType.house => 'House',
        PropertyType.duplex => 'Duplex',
        PropertyType.triplex => 'Triplex',
        PropertyType.land => 'Land',
        PropertyType.office => 'Office',
        PropertyType.commercial => 'Commercial space',
        PropertyType.industrial => 'Industrial property',
        PropertyType.other => 'Other',
      };

  /// Residential types have bedrooms; land / office / shops do not (spec §3 step 6:
  /// "the interface must handle a non-applicable field clearly").
  bool get usesBedrooms => switch (this) {
        PropertyType.apartment ||
        PropertyType.villa ||
        PropertyType.house ||
        PropertyType.duplex ||
        PropertyType.triplex =>
          true,
        _ => false,
      };

  bool get usesBathrooms => usesBedrooms || this == PropertyType.office || this == PropertyType.commercial;

  /// Bathrooms are mandatory (>= 1) only for residential types.
  bool get requiresBathroom => usesBedrooms;

  /// A studio is an apartment flagged `isStudio`, NOT "0 bedrooms" (see Property).
  bool get allowsStudio => this == PropertyType.apartment;
}

extension PublishTransactionType on TransactionType {
  String get label => this == TransactionType.buy ? 'For sale' : 'For rent';
}
