import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repo);
  final AuthRepository _repo;

  Future<AuthUser> call({required String email, required String password}) =>
      _repo.login(email: email.trim(), password: password);
}
