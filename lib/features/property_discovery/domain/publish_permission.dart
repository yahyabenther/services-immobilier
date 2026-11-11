import '../../auth/domain/entities/auth_user.dart';

/// UX-level permission for the Publish CTA. NOT security: Firestore rules /
/// backend (Module 08) must enforce who can really publish.
bool canPublishProperty(AuthUser? user) {
  if (user == null || user.isBlocked || !user.emailVerified) return false;
  return user.role == UserRole.owner || user.role == UserRole.agent || user.role == UserRole.admin;
}

/// A verified, active plain user may ask to publish as an owner (callable
/// `becomeOwner`). UX only: the backend decides.
bool canBecomeOwner(AuthUser? user) =>
    user != null && !user.isBlocked && user.emailVerified && user.role == UserRole.user;