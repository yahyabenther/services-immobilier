import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../core/errors/agent_failure.dart';
import '../../../core/services/cloudinary_service.dart';
import '../domain/services/agent_profile_validator.dart';

class PickedAgentImage {
  const PickedAgentImage({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

/// Profile photo / logo (public, Cloudinary) and verification document photos
/// (picked here, sent to Cloudinary as PRIVATE `authenticated` files by the repository).
///
/// Flow (spec §10.3): select -> validate format and size -> compress
/// (image_picker resize + quality) -> upload -> save the URL in Firestore.
class AgentMediaService {
  AgentMediaService({ImagePicker? picker, CloudinaryService? cloudinary})
      : _picker = picker ?? ImagePicker(),
        _cloudinary = cloudinary ?? CloudinaryService();

  final ImagePicker _picker;
  final CloudinaryService _cloudinary;

  /// Null when the user cancelled the picker. Throws a validation [AgentFailure]
  /// with `fieldErrors['image']` for a wrong format or size.
  Future<PickedAgentImage?> pickProfileImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final error = AgentProfileValidator.image(fileName: file.name, bytes: bytes.length);
    if (error != null) throw AgentFailure(AgentFailureType.validation, fieldErrors: {'image': error});
    return PickedAgentImage(name: file.name, bytes: bytes);
  }

  /// Verification document photo (camera or gallery), up to 5 MB.
  Future<PickedAgentImage?> pickDocument(ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    String? error;
    if (!AgentProfileValidator.allowedImageExtensions.contains(ext)) {
      error = 'Only JPG, PNG and WebP images are allowed.';
    } else if (bytes.isEmpty) {
      error = 'The selected image is empty.';
    } else if (bytes.length > 5 * 1024 * 1024) {
      error = 'Document must be smaller than 5 MB.';
    }
    if (error != null) throw AgentFailure(AgentFailureType.validation, fieldErrors: {'document': error});
    return PickedAgentImage(name: file.name, bytes: bytes);
  }

  /// Returns the Cloudinary `secure_url`. Any failure -> `imageUploadFailed`.
  Future<String> uploadProfileImage(PickedAgentImage image, {required String uid}) async {
    try {
      return await _cloudinary.uploadImage(image.bytes, filename: image.name, folder: 'agents/$uid');
    } on CloudinaryUploadException {
      throw const AgentFailure(AgentFailureType.imageUploadFailed);
    }
  }
}
