import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SendEmailVerification {
  const SendEmailVerification(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.sendEmailVerification();
}

/// Reloads the Firebase user and returns the up-to-date verification state.
class RefreshVerificationStatus {
  const RefreshVerificationStatus(this._repo);
  final AuthRepository _repo;

  Future<AuthUser?> call() => _repo.refreshCurrentUser();
}
