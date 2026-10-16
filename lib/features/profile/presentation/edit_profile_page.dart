
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/profile_repository.dart';
import '../data/cloudinary_photo_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ProfileRepository();
  final _photoService = CloudinaryPhotoService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGovernorate;
  String? _existingPhotoUrl;

  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;

  bool _loading = true;
  bool _saving = false;
  bool _choosingPhoto = false;
  String? _error;

  static const Color navy = Color(0xFF10244A);
  static const Color blue = Color(0xFF1769F4);

  static const List<String> tunisianGovernorates = [
    'Ariana',
    'Béja',
    'Ben Arous',
    'Bizerte',
    'Gabès',
    'Gafsa',
    'Jendouba',
    'Kairouan',
    'Kasserine',
    'Kébili',
    'Le Kef',
    'Mahdia',
    'La Manouba',
    'Médenine',
    'Monastir',
    'Nabeul',
    'Sfax',
    'Sidi Bouzid',
    'Siliana',
    'Sousse',
    'Tataouine',
    'Tozeur',
    'Tunis',
    'Zaghouan',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _repository.getProfile();

      if (!mounted) return;

      _nameController.text = (data['name'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();

      final savedCity =
          (data['preferredCity'] ?? '').toString().trim();

      String? matchingGovernorate;

      for (final governorate in tunisianGovernorates) {
        if (governorate.toLowerCase() ==
            savedCity.toLowerCase()) {
          matchingGovernorate = governorate;
          break;
        }
      }

      final photoUrl = (data['photoUrl'] ?? '').toString();

      setState(() {
        _selectedGovernorate = matchingGovernorate;
        _existingPhotoUrl =
            photoUrl.isEmpty ? null : photoUrl;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load your profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _choosePhoto() async {
    if (_saving || _choosingPhoto) return;

    setState(() => _choosingPhoto = true);

    try {
      final photo = await _photoService.pickPhoto();

      if (photo == null) return;

      final size = await photo.length();
      final extension = photo.name.split('.').last.toLowerCase();

      if (size > CloudinaryPhotoService.maxFileSize) {
        _showMessage(
          'Image must be smaller than 2 MB.',
          isError: true,
        );
        return;
      }

      if (!CloudinaryPhotoService.allowedExtensions
          .contains(extension)) {
        _showMessage(
          'Please select JPG, PNG or WebP.',
          isError: true,
        );
        return;
      }

      final bytes = await photo.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage(
          'The selected image is empty.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedPhoto = photo;
        _selectedPhotoBytes = bytes;
      });
    } catch (_) {
      _showMessage(
        'Unable to select the image.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _choosingPhoto = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_saving || _loading || !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGovernorate == null) {
      _showMessage(
        'Please select a governorate.',
        isError: true,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in again.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();

      final updates = <String, dynamic>{
        'name': name,
        'phone': _phoneController.text.trim(),
        'preferredCity': _selectedGovernorate!,
      };

      if (_selectedPhoto != null) {
        final photoUrl =
            await _photoService.uploadPhoto(_selectedPhoto!);

        updates['photoUrl'] = photoUrl;
      }

      // Save profile fields together in Firestore.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      // Firestore is the main source of profile information.
      // Updating Firebase Auth's display name is best-effort.
      try {
        await user.updateDisplayName(name);
      } catch (_) {
        // The profile data has already been saved in Firestore.
      }

      if (!mounted) return;

      _showMessage('Profile updated successfully!');

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.code == 'permission-denied'
            ? 'Permission denied. Check Firestore Rules.'
            : 'Unable to save your profile. Please try again.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Photo upload or profile save failed. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: blue),
        filled: true,
        fillColor: readOnly
            ? const Color(0xFFF0F2F6)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    ImageProvider? avatarImage;

    if (_selectedPhotoBytes != null) {
      avatarImage = MemoryImage(_selectedPhotoBytes!);
    } else if (_existingPhotoUrl != null) {
      avatarImage = NetworkImage(_existingPhotoUrl!);
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: const Color(0xFFE1EAFF),
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? const Icon(
                  Icons.person,
                  size: 52,
                  color: blue,
                )
              : null,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: (_saving || _choosingPhoto)
              ? null
              : _choosePhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(
            _choosingPhoto ? 'Opening...' : 'Change Photo',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'JPG, PNG or WebP · Maximum 2 MB',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        if (_selectedPhoto != null) ...[
          const SizedBox(height: 8),
          const Text(
            'New photo selected. Save Changes to upload it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: blue,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      _selectedPhoto = null;
                      _selectedPhotoBytes = null;
                    });
                  },
            child: const Text('Cancel Photo Change'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _buildPhotoPicker(),

                            const SizedBox(height: 28),

                            _input(
                              label: 'Full Name',
                              controller: _nameController,
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _input(
                              label: 'Email Address',
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              readOnly: true,
                            ),

                            const SizedBox(height: 16),

                            _input(
                              label: 'Phone Number',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              initialValue: _selectedGovernorate,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Preferred Governorate',
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: blue,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              hint: const Text(
                                'Select your governorate',
                              ),
                              items: tunisianGovernorates
                                  .map(
                                    (governorate) =>
                                        DropdownMenuItem<String>(
                                      value: governorate,
                                      child: Text(governorate),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _saving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedGovernorate = value;
                                      });
                                    },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a governorate';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 30),

                            FilledButton.icon(
                              onPressed: _saving ? null : _saveProfile,
                              style: FilledButton.styleFrom(
                                backgroundColor: blue,
                                padding: const EdgeInsets.all(16),
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_outlined,
                                    ),
                              label: Text(
                                _saving
                                    ? 'Uploading and Saving...'
                                    : 'Save Changes',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
