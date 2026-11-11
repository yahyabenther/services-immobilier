import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BecomeOwnerException implements Exception {
  const BecomeOwnerException(this.message);
  final String message;

  @override
  String toString() => 'BecomeOwnerException($message)';
}

class OwnerRoleService {
  OwnerRoleService(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Sets `users/{uid}.role = 'owner'`. The Firestore rules only allow this for a
  /// verified, active user whose current role is 'user', and only the `role`
  /// field may change. The app then receives the new role through the live
  /// profile stream; nothing to refresh by hand.
  Future<void> becomeOwner() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const BecomeOwnerException('Please sign in first.');
    try {
      await _db.collection('users').doc(uid).update({'role': 'owner'});
    } on FirebaseException catch (e) {
      throw BecomeOwnerException(switch (e.code) {
        'permission-denied' =>
          'Your account cannot be switched to owner. Make sure your email is verified, then try again.',
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
          'Network problem. Check your connection and try again.',
        _ => 'Could not enable publishing. Please try again.',
      });
    } catch (_) {
      throw const BecomeOwnerException('Could not enable publishing. Please try again.');
    }
  }
}