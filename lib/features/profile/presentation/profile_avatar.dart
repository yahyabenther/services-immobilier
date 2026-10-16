import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/cloudinary_url.dart';
import '../data/profile_repository.dart';

/// Profile picture with a camera button: pick from the gallery, upload to Cloudinary,
/// then store the returned URL in `users/{uid}.photoUrl`.
class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key, required this.photoUrl, required this.repository});

  final String photoUrl;
  final ProfileRepository repository;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  static const _blue = Color(0xFF1769F4);

  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _uploading = false;

  Future<void> _changePhoto() async {
    if (_uploading) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // resize on the device: smaller upload, faster
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return; // user cancelled

      setState(() => _uploading = true);

      final uid = widget.repository.currentUser?.uid;
      final url = await _cloudinary.uploadImage(
        await picked.readAsBytes(),
        filename: picked.name,
        folder: 'users',
        publicId: uid, // one photo per user, replaced on every upload
      );
      await widget.repository.updatePhotoUrl(url);

      messenger.showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } on CloudinaryUploadException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not update your photo. Please try again.')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl.isNotEmpty;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFFE1EAFF),
            backgroundImage:
                hasPhoto ? NetworkImage(CloudinaryUrl.optimized(widget.photoUrl, width: 240, height: 240)) : null,
            child: _uploading
                ? const CircularProgressIndicator(strokeWidth: 3)
                : (hasPhoto ? null : const Icon(Icons.person, color: _blue, size: 54)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: _blue,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Change photo',
                visualDensity: VisualDensity.compact,
                onPressed: _uploading ? null : _changePhoto,
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
