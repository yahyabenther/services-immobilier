import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/auth_failure.dart';

/// The only class that touches Firebase Auth / Firestore / Google Sign-In.
class FirebaseAuthDatasource {
  FirebaseAuthDatasource(this._auth, this._db, this._google);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _db.collection('users').doc(uid);

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> userChanges() => _auth.userChanges();

  Stream<Map<String, dynamic>?> profileStream(String uid) =>
      _profileRef(uid).snapshots().map((s) => s.data());

  Future<Map<String, dynamic>?> getProfile(String uid) async =>
      (await _profileRef(uid).get()).data();

  /// Creates `users/{uid}` once (role=user, status=active). Never overwrites an
  /// existing profile, so it is safe to call after every login (spec §44).
  Future<void> createProfileIfMissing(User user, {String? name, String? phone}) async {
    final ref = _profileRef(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'id': user.uid,
      'name': (name ?? user.displayName ?? '').trim(),
      'email': user.email ?? '',
      'phone': phone ?? '',
      'role': 'user',
      'status': 'active',
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<User> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    await _safeEnsureProfile(user);
    return user;
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;

    // The account now exists, so nothing below may make `register` throw: a
    // failure here would show an error while the user is already signed in, and
    // a retry would answer "email already in use". Each step is best-effort and
    // has its own recovery path.
    try {
      await user.updateDisplayName(name);
    } on FirebaseException {/* display name is also stored in the profile */}

    // Profile: one retry, then the login path creates it (without the phone,
    // which the user can add from Edit profile).
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await createProfileIfMissing(user, name: name, phone: phone);
        break;
      } on FirebaseException {/* retried once, then on next login */}
    }

    // Verification mail: the verify page offers "Resend".
    try {
      await user.sendEmailVerification();
    } on FirebaseException {/* user can resend from the verify page */}
    return user;
  }

  Future<User> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) throw const AuthFailure(AuthFailureType.googleCancelled);
    final tokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: tokens.accessToken,
      idToken: tokens.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user!;
    await _safeEnsureProfile(user);
    return user;
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {/* not signed in with Google */}
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  Future<void> confirmPasswordReset(String code, String newPassword) =>
      _auth.confirmPasswordReset(code: code, newPassword: newPassword);

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure(AuthFailureType.unknown);
    await user.sendEmailVerification();
  }

  Future<User?> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _auth.currentUser;
  }

  /// Profile creation must not make a successful sign-in fail: if it errors
  /// (e.g. offline), the profile is created on the next login.
  Future<void> _safeEnsureProfile(User user) async {
    try {
      await createProfileIfMissing(user);
    } on FirebaseException {/* retried on next login */}
  }
}
