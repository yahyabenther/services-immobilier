import 'dart:async';

import 'package:team_app/core/errors/auth_failure.dart';
import 'package:team_app/features/auth/domain/entities/auth_user.dart';
import 'package:team_app/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failLoginWith});

  final AuthFailure? failLoginWith;
  final _ctrl = StreamController<AuthUser?>.broadcast();
  int loginCalls = 0;

  void emit(AuthUser? u) => _ctrl.add(u);

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield null;
    yield* _ctrl.stream;
  }

  @override
  Future<AuthUser> login({required String email, required String password}) async {
    loginCalls++;
    if (failLoginWith != null) throw failLoginWith!;
    final u = AuthUser(id: '1', email: email, emailVerified: true);
    emit(u);
    return u;
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final u = AuthUser(id: '1', email: email, name: name, phone: phone);
    emit(u);
    return u;
  }

  @override
  Future<void> logout() async => emit(null);
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> confirmPasswordReset({required String code, required String newPassword}) async {}
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<AuthUser> signInWithGoogle() async => throw const AuthFailure(AuthFailureType.googleCancelled);
  @override
  Future<AuthUser?> refreshCurrentUser() async => null;
  @override
  Future<AuthUser?> getCurrentUser() async => null;
}
