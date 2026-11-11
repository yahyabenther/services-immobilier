/// Single place for every publishing limit (spec §8.2: limits are defined by the
/// team and centralised in configuration). The same numbers are enforced by the
/// Firestore rules (`validNewListing` in firestore.rules): change both together.
class PublishingConfig {
  PublishingConfig._();

  // ---- photos ---------------------------------------------------------------
  static const minPhotos = 1;
  static const maxPhotos = 10;

  /// Must stay <= CloudinaryService.maxBytes (5 MB), the upload service limit.
  static const maxPhotoBytes = 5 * 1024 * 1024;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  /// Passed to image_picker so photos are resized + re-encoded BEFORE upload
  /// (this is the compression step: no extra package needed).
  static const pickMaxDimension = 1600.0;
  static const pickQuality = 80;

  // ---- text -----------------------------------------------------------------
  static const titleMin = 5;
  static const titleMax = 100;
  static const descriptionMin = 20;
  static const descriptionMax = 2000;
  static const areaMax = 80;
  static const cityMax = 80;

  // ---- numbers --------------------------------------------------------------
  static const maxPrice = 1000000000; // sanity ceiling, in TND
  static const maxSurface = 1000000; // m²
  static const maxRooms = 20;

  static const currency = 'TND';

  // Rough bounding box of Tunisia, only to reject obviously wrong coordinates.
  static const minLat = 30.0;
  static const maxLat = 37.6;
  static const minLng = 7.4;
  static const maxLng = 11.7;
}
