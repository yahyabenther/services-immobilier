import 'services/listing_validator.dart';

enum PublishingFailureType {
  notAuthenticated,
  notAllowed,
  invalidData,
  uploadFailed,
  network,
  permissionDenied,
  unknown,
}

/// The only exception the publishing module throws to the UI (same convention as
/// PropertyFailure / FavoriteFailure): technical errors never reach the screen.
class PublishingFailure implements Exception {
  const PublishingFailure(
    this.type, {
    this.fieldErrors = const {},
    this.failedPhotoIds = const {},
  });

  final PublishingFailureType type;

  /// Set for [PublishingFailureType.invalidData].
  final Map<ListingField, String> fieldErrors;

  /// Set for [PublishingFailureType.uploadFailed]: which photos to retry.
  final Set<String> failedPhotoIds;

  String get message => switch (type) {
        PublishingFailureType.notAuthenticated => 'Please sign in to publish a property.',
        PublishingFailureType.notAllowed => 'Your account is not allowed to publish listings.',
        PublishingFailureType.invalidData => 'Some information needs to be corrected before you can submit.',
        PublishingFailureType.uploadFailed =>
          failedPhotoIds.length > 1
              ? '${failedPhotoIds.length} photos could not be uploaded. Please try again.'
              : 'A photo could not be uploaded. Please try again.',
        PublishingFailureType.network => 'Something went wrong. Check your connection and try again.',
        PublishingFailureType.permissionDenied => "You don't have permission to publish this listing.",
        PublishingFailureType.unknown => 'Something went wrong while publishing. Please try again.',
      };

  @override
  String toString() => 'PublishingFailure($type)';
}
