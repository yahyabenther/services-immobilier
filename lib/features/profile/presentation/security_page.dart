
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _sending = false;

  static const Color navy = Color(0xFF10244A);
  static const Color blue = Color(0xFF1769F4);

  Future<void> _sendPasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email is associated with your account.'),
        ),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. Please check your inbox.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'too-many-requests'
                ? 'Too many attempts. Please try again later.'
                : 'Unable to send password reset email.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
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
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFFE1EAFF),
                child: Icon(
                  Icons.shield_outlined,
                  color: blue,
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Security',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Manage your account security settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.email_outlined, color: blue),
                  title: const Text('Account Email'),
                  subtitle: Text(user?.email ?? 'Not available'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.lock_reset, color: blue),
                  title: const Text('Reset Password'),
                  subtitle: const Text(
                    'Receive a password reset link by email.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _sending ? null : _sendPasswordReset,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _sending ? null : _sendPasswordReset,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.all(16),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _sending ? 'Sending...' : 'Send Password Reset Email',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'If you signed in with Google, password management may '
                'be handled by your Google account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
