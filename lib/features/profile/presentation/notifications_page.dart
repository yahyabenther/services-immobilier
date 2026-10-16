
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const Color navy = Color(0xFF10244A);
  static const Color blue = Color(0xFF1769F4);

  bool newMessages = true;
  bool favoriteUpdates = true;
  bool propertyAlerts = true;
  bool emailNotifications = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  DocumentReference<Map<String, dynamic>>? get _userDocument {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final document = _userDocument;

    if (document == null) {
      setState(() {
        _error = 'Please log in again.';
        _loading = false;
      });
      return;
    }

    try {
      final snapshot = await document.get();

      if (!snapshot.exists) {
        throw StateError('User profile not found.');
      }

      final data = snapshot.data() ?? {};

      final preferences =
          data['notificationPreferences'] is Map
              ? Map<String, dynamic>.from(
                  data['notificationPreferences'] as Map,
                )
              : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        newMessages =
            preferences['newMessages'] == true ||
            preferences['newMessages'] == null;

        favoriteUpdates =
            preferences['favoriteUpdates'] == true ||
            preferences['favoriteUpdates'] == null;

        propertyAlerts =
            preferences['propertyAlerts'] == true ||
            preferences['propertyAlerts'] == null;

        emailNotifications =
            preferences['emailNotifications'] == true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load notification preferences.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_saving || _loading) return;

    final document = _userDocument;

    if (document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await document.update({
        'notificationPreferences': {
          'newMessages': newMessages,
          'favoriteUpdates': favoriteUpdates,
          'propertyAlerts': propertyAlerts,
          'emailNotifications': emailNotifications,
        },
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      final message = e.code == 'permission-denied'
          ? 'Saving is not authorized yet. Contact the project administrator.'
          : 'Unable to save preferences. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save preferences.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _notificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        secondary: Icon(icon, color: blue),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: blue,
        onChanged: _saving ? null : onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
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
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 600),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 12),

                        const Text(
                          'Notification Preferences',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Choose which notifications you would like to receive.',
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 24),

                        _notificationTile(
                          icon: Icons.message_outlined,
                          title: 'New Messages',
                          subtitle:
                              'Updates about messages from other users.',
                          value: newMessages,
                          onChanged: (value) {
                            setState(() => newMessages = value);
                          },
                        ),

                        _notificationTile(
                          icon: Icons.favorite_outline,
                          title: 'Favorite Properties',
                          subtitle:
                              'Updates about properties you saved.',
                          value: favoriteUpdates,
                          onChanged: (value) {
                            setState(() => favoriteUpdates = value);
                          },
                        ),

                        _notificationTile(
                          icon: Icons.home_outlined,
                          title: 'New Property Alerts',
                          subtitle:
                              'Be informed about newly listed properties.',
                          value: propertyAlerts,
                          onChanged: (value) {
                            setState(() => propertyAlerts = value);
                          },
                        ),

                        _notificationTile(
                          icon: Icons.email_outlined,
                          title: 'Email Notifications',
                          subtitle: 'Receive updates by email.',
                          value: emailNotifications,
                          onChanged: (value) {
                            setState(() => emailNotifications = value);
                          },
                        ),

                        const SizedBox(height: 18),

                        FilledButton.icon(
                          onPressed:
                              _saving ? null : _savePreferences,
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            padding: const EdgeInsets.all(16),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving
                                ? 'Saving...'
                                : 'Save Preferences',
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'These settings save your preferences. '
                          'Actual push notifications and emails '
                          'require notification services to be configured.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
