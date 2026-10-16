import '../../../../core/errors/auth_failure.dart';
import '../repositories/auth_repository.dart';

/// Sends the reset email. "User not found" is swallowed on purpose so the app
/// never reveals which emails are registered.
class ResetPassword {
  const ResetPassword(this._repo);
  final AuthRepository _repo;

  Future<void> call(String email) async {
    try {
      await _repo.sendPasswordResetEmail(email.trim());
    } on AuthFailure catch (e) {
      if (e.type == AuthFailureType.userNotFound) return;
      rethrow;
    }
  }
}

/// Completes the reset with the `oobCode` from the email link.
class ConfirmPasswordReset {
  const ConfirmPasswordReset(this._repo);
  final AuthRepository _repo;

  Future<void> call({required String code, required String newPassword}) =>
      _repo.confirmPasswordReset(code: code, newPassword: newPassword);
}
