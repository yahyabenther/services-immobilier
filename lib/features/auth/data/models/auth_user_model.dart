import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    super.name,
    super.phone,
    super.role,
    super.status,
    super.emailVerified,
  });

  /// Identity comes from Firebase Auth; role/status come ONLY from the Firestore
  /// profile (spec §22, §29). If the profile does not exist yet (race right after
  /// sign-up) we fall back to the least-privileged defaults.
  factory AuthUserModel.fromFirebase(User user, Map<String, dynamic>? profile) {
    return AuthUserModel(
      id: user.uid,
      email: (profile?['email'] as String?) ?? user.email ?? '',
      name: (profile?['name'] as String?) ?? user.displayName,
      phone: (profile?['phone'] as String?) ?? user.phoneNumber,
      role: UserRole.parse(profile?['role'] as String?),
      status: AccountStatus.parse(profile?['status'] as String?),
      emailVerified: user.emailVerified,
    );
  }
}
