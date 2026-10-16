import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/auth_failure.dart';
import '../data/datasources/firebase_auth_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/login.dart';
import '../domain/usecases/logout.dart';
import '../domain/usecases/observe_auth_state.dart';
import '../domain/usecases/register.dart';
import '../domain/usecases/reset_password.dart';
import '../domain/usecases/send_email_verification.dart';
import '../domain/usecases/sign_in_with_google.dart';
import 'auth_state.dart';

// ---- infrastructure -------------------------------------------------------
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final googleSignInProvider = Provider<GoogleSignIn>((_) => GoogleSignIn());

final authDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) => FirebaseAuthDatasource(
      ref.watch(firebaseAuthProvider),
      ref.watch(firestoreProvider),
      ref.watch(googleSignInProvider),
    ));

/// Override this in tests with a fake repository.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDatasourceProvider)),
);

// ---- use cases ------------------------------------------------------------
final loginProvider = Provider((ref) => Login(ref.watch(authRepositoryProvider)));
final registerProvider = Provider((ref) => Register(ref.watch(authRepositoryProvider)));
final logoutProvider = Provider((ref) => Logout(ref.watch(authRepositoryProvider)));
final resetPasswordProvider = Provider((ref) => ResetPassword(ref.watch(authRepositoryProvider)));
final confirmPasswordResetProvider =
    Provider((ref) => ConfirmPasswordReset(ref.watch(authRepositoryProvider)));
final sendEmailVerificationProvider =
    Provider((ref) => SendEmailVerification(ref.watch(authRepositoryProvider)));
final refreshVerificationProvider =
    Provider((ref) => RefreshVerificationStatus(ref.watch(authRepositoryProvider)));
final signInWithGoogleProvider =
    Provider((ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)));
final getCurrentUserProvider = Provider((ref) => GetCurrentUser(ref.watch(authRepositoryProvider)));
final observeAuthStateProvider =
    Provider((ref) => ObserveAuthState(ref.watch(authRepositoryProvider)));

// ---- state ----------------------------------------------------------------
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in user (verified or not), or null.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final s = ref.watch(authControllerProvider);
  return switch (s) {
    AuthAuthenticated(:final user) => user,
    AuthEmailVerificationRequired(:final user) => user,
    _ => null,
  };
});

class AuthController extends Notifier<AuthState> {
  StreamSubscription<AuthUser?>? _sub;

  @override
  AuthState build() {
    _sub = ref.read(observeAuthStateProvider)().listen(
          _onUser,
          onError: (_) => state = const AuthState.unauthenticated(),
        );
    ref.onDispose(() => _sub?.cancel());
    return const AuthState.initializing();
  }

  void _onUser(AuthUser? user) {
    if (user == null) {
      // A null emission must not cancel an in-flight sign-in.
      if (state is AuthAuthenticating) return;
      state = const AuthState.unauthenticated();
      return;
    }
    state = user.emailVerified
        ? AuthState.authenticated(user)
        : AuthState.emailVerificationRequired(user);
  }

  /// Runs a sign-in / sign-up action. Duplicate submissions are ignored (spec §39).
  Future<void> _run(Future<AuthUser> Function() action) async {
    if (state is AuthAuthenticating) return;
    state = const AuthState.authenticating();
    try {
      final user = await action();
      // Normally the auth stream has already moved us on; this is a safety net so
      // the UI can never be stuck on "authenticating".
      if (state is AuthAuthenticating) _onUser(user);
    } on AuthFailure catch (e) {
      state = e.type == AuthFailureType.googleCancelled
          ? const AuthState.unauthenticated()
          : AuthState.error(e.message);
    }
  }

  Future<void> login(String email, String password) =>
      _run(() => ref.read(loginProvider)(email: email, password: password));

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) =>
      _run(() => ref.read(registerProvider)(
            name: name,
            email: email,
            phone: phone,
            password: password,
          ));

  Future<void> signInWithGoogle() => _run(() => ref.read(signInWithGoogleProvider)());

  Future<void> logout() async {
    try {
      await ref.read(logoutProvider)();
    } finally {
      state = const AuthState.unauthenticated();
      // User-scoped providers (search state, selected location, ...) watch
      // `currentUserProvider` and reset themselves. Modules that add per-user data
      // (favorites, messages) must do the same.
    }
  }

  /// Re-checks email verification (button + polling on the verify page).
  Future<void> refreshVerification() async {
    try {
      final user = await ref.read(refreshVerificationProvider)();
      if (user != null) _onUser(user);
    } on AuthFailure {
      // Transient (offline): polling will retry.
    }
  }

  void clearError() {
    if (state is AuthError) state = const AuthState.unauthenticated();
  }

  // Actions that do not change the session: callers catch AuthFailure.
  Future<void> sendVerificationEmail() => ref.read(sendEmailVerificationProvider)();
  Future<void> sendPasswordReset(String email) => ref.read(resetPasswordProvider)(email);
  Future<void> confirmPasswordReset({required String code, required String newPassword}) =>
      ref.read(confirmPasswordResetProvider)(code: code, newPassword: newPassword);
}
