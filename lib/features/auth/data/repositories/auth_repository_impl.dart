import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth_error_mapper.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/auth_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._ds);

  final FirebaseAuthDatasource _ds;

  /// Converts every backend exception into an [AuthFailure].
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    } catch (e, st) {
      debugPrint('Unexpected auth error: $e\n$st');
      throw const AuthFailure(AuthFailureType.unknown);
    }
  }

  Future<AuthUser> _withProfile(User user) async =>
      AuthUserModel.fromFirebase(user, await _ds.getProfile(user.uid));

  @override
  Future<AuthUser> login({required String email, required String password}) =>
      _guard(() async => _withProfile(await _ds.signIn(email, password)));

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) =>
      _guard(() async => _withProfile(
            await _ds.register(name: name, email: email, password: password, phone: phone),
          ));

  @override
  Future<AuthUser> signInWithGoogle() => _guard(() async {
        try {
          return await _withProfile(await _ds.signInWithGoogle());
        } on FirebaseAuthException {
          rethrow; // mapped by _guard
        } on AuthFailure {
          rethrow;
        } catch (_) {
          throw const AuthFailure(AuthFailureType.googleSignInFailed);
        }
      });

  @override
  Future<void> logout() => _guard(_ds.signOut);

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() => _ds.sendPasswordReset(email));

  @override
  Future<void> confirmPasswordReset({required String code, required String newPassword}) =>
      _guard(() => _ds.confirmPasswordReset(code, newPassword));

  @override
  Future<void> sendEmailVerification() => _guard(_ds.sendEmailVerification);

  @override
  Future<AuthUser?> refreshCurrentUser() => _guard(() async {
        final user = await _ds.reloadUser();
        return user == null ? null : _withProfile(user);
      });

  @override
  Future<AuthUser?> getCurrentUser() => _guard(() async {
        final user = _ds.currentFirebaseUser;
        return user == null ? null : _withProfile(user);
      });

  /// Firebase identity + live Firestore profile, merged into one stream.
  /// Profile changes (e.g. an admin suspends the account) propagate immediately.
  @override
  Stream<AuthUser?> authStateChanges() {
    late final StreamController<AuthUser?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<Map<String, dynamic>?>? profileSub;

    controller = StreamController<AuthUser?>(
      onListen: () {
        authSub = _ds.userChanges().listen(
          (fbUser) {
            profileSub?.cancel();
            if (fbUser == null) {
              controller.add(null);
              return;
            }
            profileSub = _ds.profileStream(fbUser.uid).listen(
                  (data) => controller.add(AuthUserModel.fromFirebase(fbUser, data)),
                  // Profile unreadable (offline/rules): keep the session with safe defaults.
                  onError: (_) => controller.add(AuthUserModel.fromFirebase(fbUser, null)),
                );
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await profileSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }
}
