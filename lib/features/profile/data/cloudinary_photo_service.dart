
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryPhotoService {
  static const String _cloudName = 'rlx9j8l2';
  static const String _uploadPreset = 'immofind_profile';

  static const int maxFileSize = 2 * 1024 * 1024;

  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickPhoto() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
  }

  Future<String> uploadPhoto(XFile image) async {
    final fileSize = await image.length();

    if (fileSize > maxFileSize) {
      throw Exception('Image must be smaller than 2 MB.');
    }

    final extension = image.name.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      throw Exception('Only JPG, PNG and WebP images are allowed.');
    }

    final bytes = await image.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): '
        '$responseBody',
      );
    }

    final decoded = jsonDecode(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid Cloudinary response.');
    }

    final secureUrl = decoded['secure_url'];

    if (secureUrl is! String ||
        !secureUrl.startsWith(
          'https://res.cloudinary.com/$_cloudName/',
        )) {
      throw Exception('Invalid photo URL.');
    }

    return secureUrl;
  }

  Future<String?> pickAndUploadPhoto() async {
    final image = await pickPhoto();

    if (image == null) {
      return null;
    }

    return uploadPhoto(image);
  }
}
