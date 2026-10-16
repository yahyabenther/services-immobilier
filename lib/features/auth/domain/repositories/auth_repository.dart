import '../entities/auth_user.dart';

/// The UI never talks to Firebase directly: everything goes through this contract.
/// Every method throws [AuthFailure] (never raw Firebase exceptions).
abstract class AuthRepository {
  Future<AuthUser> login({required String email, required String password});

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  });

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> confirmPasswordReset({required String code, required String newPassword});

  Future<void> sendEmailVerification();

  Future<AuthUser> signInWithGoogle();

  /// Current user with a freshly reloaded verification state, or null.
  Future<AuthUser?> refreshCurrentUser();

  Future<AuthUser?> getCurrentUser();

  /// Emits the signed-in user (identity + Firestore profile) or null.
  Stream<AuthUser?> authStateChanges();
}
