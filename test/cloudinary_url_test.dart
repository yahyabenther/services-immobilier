import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/utils/cloudinary_url.dart';

void main() {
  const base = 'https://res.cloudinary.com/demo/image/upload';

  test('inserts a transformation after /upload/ (versioned URL)', () {
    expect(
      CloudinaryUrl.optimized('$base/v1730000000/properties/abc.jpg', width: 600, height: 375),
      '$base/f_auto,q_auto,c_fill,w_600,h_375/v1730000000/properties/abc.jpg',
    );
  });

  test('works for an unversioned single-segment public id', () {
    expect(CloudinaryUrl.card('$base/sample.jpg'), '$base/f_auto,q_auto,c_fill,w_600,h_375/sample.jpg');
  });

  test('a public id containing an underscore is NOT mistaken for a transformation', () {
    expect(CloudinaryUrl.optimized('$base/my_photo.jpg', width: 300), '$base/f_auto,q_auto,c_fill,w_300/my_photo.jpg');
  });

  test('already-transformed URLs are left alone', () {
    const u = '$base/w_200,h_100,c_fill/v123/a.jpg';
    expect(CloudinaryUrl.card(u), u);
  });

  test('non-Cloudinary and invalid URLs are returned unchanged', () {
    expect(CloudinaryUrl.card('https://example.com/a.jpg'), 'https://example.com/a.jpg');
    expect(CloudinaryUrl.card('not a url'), 'not a url');
  });

  test('presets', () {
    expect(CloudinaryUrl.gallery('$base/v1/a.jpg'), contains('w_1200'));
    expect(CloudinaryUrl.thumb('$base/v1/a.jpg'), contains('w_240,h_160'));
  });
}
