import '../../../core/services/cloudinary_service.dart';
import '../domain/entities/listing_draft.dart';

/// Seam over the media service so tests / a future Firebase Storage
/// implementation can replace Cloudinary without touching anything else.
abstract interface class PhotoUploader {
  /// Returns the HTTPS URL. Throws [CloudinaryUploadException] (or any error) on failure.
  Future<String> upload(ListingPhoto photo, {required String folder});
}

class CloudinaryPhotoUploader implements PhotoUploader {
  CloudinaryPhotoUploader(this._cloudinary);
  final CloudinaryService _cloudinary;

  @override
  Future<String> upload(ListingPhoto photo, {required String folder}) =>
      _cloudinary.uploadImage(photo.bytes, filename: photo.name, folder: folder);
}
