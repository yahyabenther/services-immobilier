import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class Register {
  const Register(this._repo);
  final AuthRepository _repo;

  Future<AuthUser> call({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) =>
      _repo.register(name: name.trim(), email: email.trim(), password: password, phone: phone);
}
