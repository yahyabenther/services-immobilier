
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';
import 'edit_profile_page.dart';
import 'security_page.dart';
import 'notifications_page.dart';
import 'profile_avatar.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  // Created once (a new stream on every build would re-subscribe each time).
  Stream<Map<String, dynamic>?>? _profileStream;

  static const Color navy = Color(0xFF10244A);
  static const Color blue = Color(0xFF1769F4);
  static const Color background = Color(0xFFF8FAFC);

  bool _loggingOut = false;

  Future<void> _openEditProfile() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const EditProfilePage(),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _openSecurity() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const SecurityPage(),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of ImmoFind?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      await ref.read(authControllerProvider.notifier).logout();
      // The router guard redirects to Welcome once the session is gone.
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to log out. Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: navy,
        ),
      ),
    );
  }

  Widget _profileItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool unavailable = false,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE8EDF5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        enabled: !unavailable,
        leading: Icon(icon, color: unavailable ? Colors.grey : blue),
        title: Text(title),
        subtitle: unavailable
            ? const Text('Coming soon')
            : subtitle == null
            ? null
            : Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: (onTap == null || unavailable)
            ? null
            : const Icon(Icons.chevron_right),
        onTap: unavailable ? null : onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);

    if (authUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view your profile.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _profileStream ??= _repository.watchProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load profile information.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _profileStream = null), // re-subscribes
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return const Center(
              child: Text('Profile not found.'),
            );
          }

          final name = (data['name'] ??
                  authUser.name ??
                  'ImmoFind User')
              .toString();

          final email = (data['email'] ??
                  authUser.email ??
                  '')
              .toString();

          final phone =
              (data['phone'] ?? '').toString();

          final governorate =
              (data['preferredCity'] ?? '').toString();

          return Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 650),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ProfileAvatar(
                    photoUrl: (data['photoUrl'] ?? '').toString(),
                    repository: _repository,
                  ),

                  const SizedBox(height: 14),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Only indicators backed by real account data.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        authUser.emailVerified ? Icons.verified_outlined : Icons.mail_outline,
                        size: 16,
                        color: authUser.emailVerified ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        authUser.emailVerified ? 'Email verified' : 'Email not verified',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: _openEditProfile,
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label: const Text('Edit Profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      padding: const EdgeInsets.all(15),
                    ),
                  ),

                  _sectionTitle('Personal Information'),

                  _profileItem(
                    icon: Icons.person_outline,
                    title: 'Full Name',
                    subtitle: name,
                    onTap: _openEditProfile,
                  ),

                  _profileItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: email,
                  ),

                  _profileItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    subtitle: phone.isEmpty
                        ? 'Not provided'
                        : phone,
                    onTap: _openEditProfile,
                  ),

                  _profileItem(
                    icon: Icons.location_on_outlined,
                    title: 'Preferred Governorate',
                    subtitle: governorate.isEmpty
                        ? 'Not provided'
                        : governorate,
                    onTap: _openEditProfile,
                  ),

                  _sectionTitle('Account'),

                  _profileItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: _openNotifications,
                  ),

                  _profileItem(
                    icon: Icons.security_outlined,
                    title: 'Security',
                    onTap: _openSecurity,
                  ),

                  _profileItem(
                    icon: Icons.logout_outlined,
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    onTap: _loggingOut ? null : _logout,
                  ),

                  _sectionTitle('Activity'),

                  // Destinations that do not exist yet are shown as unavailable
                  // instead of routing to a blank screen or pretending to work.
                  _profileItem(
                    icon: Icons.favorite_outline,
                    title: 'Favorites',
                    unavailable: true, // TODO(Module 07): onTap -> Routes.favorites
                  ),

                  _profileItem(
                    icon: Icons.search,
                    title: 'Saved searches',
                    unavailable: true,
                  ),

                  _profileItem(
                    icon: Icons.message_outlined,
                    title: 'Messages',
                    unavailable: true, // TODO(Module 09)
                  ),

                  _profileItem(
                    icon: Icons.flag_outlined,
                    title: 'Reports',
                    unavailable: true, // TODO(Module 13)
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}