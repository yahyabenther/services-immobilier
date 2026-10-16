
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const Color navy = Color(0xFF10244A);
  static const Color blue = Color(0xFF1769F4);

  bool _saving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool get _hasPasswordProvider {
    final user = FirebaseAuth.instance.currentUser;

    return user?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
  }

  Future<void> _changePassword() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.isEmpty) {
      _showMessage('Please log in again.', isError: true);
      return;
    }

    if (!_hasPasswordProvider) {
      _showMessage(
        'Password change is unavailable for this sign-in method.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );

      // Confirm the user's current password.
      await user.reauthenticateWithCredential(credential);

      // Change the password in Firebase Authentication.
      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;

      _showMessage('Password changed successfully!');

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Current password is incorrect.';
          break;
        case 'weak-password':
          message = 'The new password is too weak.';
          break;
        case 'requires-recent-login':
          message = 'Please log in again and retry.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Unable to change password. Please try again.';
      }

      _showMessage(message, isError: true);
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
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

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: blue),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFFE1EAFF),
                child: Icon(
                  Icons.shield_outlined,
                  color: blue,
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account Security',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your password and account security.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 28),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.email_outlined,
                    color: blue,
                  ),
                  title: const Text('Account Email'),
                  subtitle: Text(user?.email ?? 'Not available'),
                ),
              ),
              const SizedBox(height: 24),

              if (_hasPasswordProvider) ...[
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 16),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _passwordField(
                        label: 'Current Password',
                        controller: _currentPasswordController,
                        visible: _showCurrentPassword,
                        onToggle: () {
                          setState(() {
                            _showCurrentPassword =
                                !_showCurrentPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _passwordField(
                        label: 'New Password',
                        controller: _newPasswordController,
                        visible: _showNewPassword,
                        onToggle: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Use at least 8 characters';
                          }
                          if (value ==
                              _currentPasswordController.text) {
                            return 'Choose a different password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _passwordField(
                        label: 'Confirm New Password',
                        controller: _confirmPasswordController,
                        visible: _showConfirmPassword,
                        onToggle: () {
                          setState(() {
                            _showConfirmPassword =
                                !_showConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      FilledButton.icon(
                        onPressed: _saving ? null : _changePassword,
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
                            : const Icon(Icons.lock_reset),
                        label: Text(
                          _saving
                              ? 'Updating...'
                              : 'Change Password',
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: blue,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Password Management',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your account does not currently use an '
                          'email and password sign-in method. '
                          'If you signed in with Google, manage '
                          'your Google password through Google.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
