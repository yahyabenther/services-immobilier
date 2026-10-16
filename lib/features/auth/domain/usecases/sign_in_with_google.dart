import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repo);
  final AuthRepository _repo;

  Future<AuthUser> call() => _repo.signInWithGoogle();
}
