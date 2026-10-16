import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  const GetCurrentUser(this._repo);
  final AuthRepository _repo;

  Future<AuthUser?> call() => _repo.getCurrentUser();
}
