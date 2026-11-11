import 'publishing_config.dart';

/// Pure check of one picked file (unit-tested). Returns a user-facing problem or null.
class PhotoRules {
  PhotoRules._();

  static String? check({required String name, String? mimeType, required int length}) {
    final dot = name.lastIndexOf('.');
    final ext = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
    final okType = PublishingConfig.allowedExtensions.contains(ext) ||
        (mimeType != null && PublishingConfig.allowedMimeTypes.contains(mimeType.toLowerCase()));
    if (!okType) return '"$name" is not supported. Use JPG, PNG or WebP.';
    if (length <= 0) return '"$name" is empty.';
    if (length > PublishingConfig.maxPhotoBytes) {
      final mb = PublishingConfig.maxPhotoBytes ~/ (1024 * 1024);
      return '"$name" is too large (max $mb MB). Choose another photo.';
    }
    return null;
  }
}
