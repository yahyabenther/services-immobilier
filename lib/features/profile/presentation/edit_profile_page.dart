
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/tunisia_governorates.dart';
import '../../../core/utils/validators.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGovernorate;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const navy = Color(0xFF10244A);
  static const blue = Color(0xFF1769F4);

  // Single source of truth shared with Home and Search (core/constants).
  static const List<String> tunisianGovernorates = tunisiaGovernorates;

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

      var savedCity =
          (data['preferredCity'] ?? '').toString().trim();
      // Older profiles used the spelling "La Manouba"; the canonical one is "Manouba".
      if (savedCity.toLowerCase() == 'la manouba') savedCity = 'Manouba';

      // Accept the saved value even if its capitalization differs.
      String? matchingGovernorate;

      for (final governorate in tunisianGovernorates) {
        if (governorate.toLowerCase() ==
            savedCity.toLowerCase()) {
          matchingGovernorate = governorate;
          break;
        }
      }

      setState(() {
        _selectedGovernorate = matchingGovernorate;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'Unable to load your profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();

      await _repository.updateProfile(
        name: name,
        // Same normalisation as registration (+216XXXXXXXX).
        phone: Validators.normalizePhone(_phoneController.text),
        preferredCity: _selectedGovernorate!,
      );

      // Keep the Firebase Auth display name in sync (best effort: the profile
      // document is the source of truth and is already saved).
      try {
        await ref.read(firebaseAuthProvider).currentUser?.updateDisplayName(name);
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save your changes. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
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
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _loading = true;
                            });
                            _loadProfile();
                          },
                          child: const Text('Try again'),
                        ),
                      ],
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
                            const CircleAvatar(
                              radius: 44,
                              backgroundColor:
                                  Color(0xFFE1EAFF),
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: blue,
                              ),
                            ),

                            const SizedBox(height: 28),

                            _input(
                              label: 'Full Name',
                              controller: _nameController,
                              icon: Icons.person_outline,
                              validator: Validators.fullName,
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
                              validator: Validators.phone,
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
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select a governorate';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 30),

                            FilledButton.icon(
                              onPressed:
                                  _saving ? null : _saveProfile,
                              style: FilledButton.styleFrom(
                                backgroundColor: blue,
                                padding:
                                    const EdgeInsets.all(16),
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_outlined,
                                    ),
                              label: Text(
                                _saving
                                    ? 'Saving...'
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