/// Helpers for images hosted on Cloudinary.
///
/// Storage convention (Module 08 uploads, this app only reads):
///   Firestore `properties/{id}.images` = list of Cloudinary `secure_url`s, main photo first,
///   e.g. https://res.cloudinary.com/CLOUD/image/upload/v1730000000/properties/abc.jpg
///
/// Cloudinary can resize/compress on the fly by inserting a transformation right
/// after `/upload/`. Lists use small thumbnails, the gallery uses larger ones, so
/// the app never downloads a 5 MB original into a card.
class CloudinaryUrl {
  CloudinaryUrl._();

  static const _marker = '/upload/';

  // A path segment such as `w_600,h_400,c_fill,f_auto` (every part is `xx_value`).
  static final _transformationSegment =
      RegExp(r'^[a-z]{1,3}_[\w.:@-]+(?:,[a-z]{1,3}_[\w.:@-]+)*$');

  static bool isCloudinary(String url) => url.contains('res.cloudinary.com') && url.contains(_marker);

  /// Returns [url] with `f_auto,q_auto,c_fill,w_<width>[,h_<height>]` inserted.
  /// Non-Cloudinary URLs, and URLs that already contain a transformation, are
  /// returned unchanged.
  static String optimized(String url, {required int width, int? height}) {
    if (!isCloudinary(url)) return url;
    final i = url.indexOf(_marker);
    final head = url.substring(0, i + _marker.length);
    final rest = url.substring(i + _marker.length);

    final segments = rest.split('/');
    if (segments.length > 1 && _transformationSegment.hasMatch(segments.first)) {
      return url; // already transformed
    }
    final t = ['f_auto', 'q_auto', 'c_fill', 'w_$width', if (height != null) 'h_$height'].join(',');
    return '$head$t/$rest';
  }

  /// List / card thumbnail (16:10).
  static String card(String url) => optimized(url, width: 600, height: 375);

  /// Details gallery image.
  static String gallery(String url) => optimized(url, width: 1200);

  /// Tiny preview (map preview, similar properties).
  static String thumb(String url) => optimized(url, width: 240, height: 160);
}
