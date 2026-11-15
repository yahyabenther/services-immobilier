import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/app/router_guard.dart';
import 'package:team_app/app/routes.dart';
import 'package:team_app/features/auth/domain/entities/auth_user.dart';
import 'package:team_app/features/auth/providers/auth_state.dart';

AuthUser u({
  UserRole role = UserRole.user,
  AccountStatus status = AccountStatus.active,
  bool verified = true,
}) =>
    AuthUser(id: '1', email: 'a@b.co', role: role, status: status, emailVerified: verified);

void main() {
  test('initializing -> splash', () {
    expect(authRedirect(const AuthState.initializing(), Routes.login), Routes.splash);
    expect(authRedirect(const AuthState.initializing(), Routes.splash), isNull);
  });

  test('signed out (guest): can browse, only publish/admin ask for login', () {
    const s = AuthState.unauthenticated();
    expect(authRedirect(s, Routes.login), isNull);
    expect(authRedirect(s, Routes.splash), welcomeFirst ? Routes.welcome : Routes.home);
    expect(authRedirect(s, Routes.home), isNull);
    expect(authRedirect(s, Routes.search), isNull);
    expect(authRedirect(s, Routes.map), isNull);
    expect(authRedirect(s, Routes.propertyDetails('abc')), isNull);
    // Account tabs show an in-place "Se connecter" panel instead of redirecting.
    expect(authRedirect(s, Routes.favorites), isNull);
    expect(authRedirect(s, Routes.messages), isNull);
    expect(authRedirect(s, Routes.profile), isNull);
    expect(authRedirect(s, Routes.publish), Routes.login);
    expect(authRedirect(s, Routes.adminDashboard), Routes.login);
  });

  test('reset-password link always allowed', () {
    expect(authRedirect(const AuthState.initializing(), Routes.resetPassword), isNull);
    expect(authRedirect(AuthState.authenticated(u()), Routes.resetPassword), isNull);
  });

  test('unverified email -> verify page', () {
    final s = AuthState.emailVerificationRequired(u(verified: false));
    expect(authRedirect(s, Routes.home), Routes.verifyEmail);
    expect(authRedirect(s, Routes.verifyEmail), isNull);
  });

  test('authenticated user leaves auth pages', () {
    final s = AuthState.authenticated(u());
    expect(authRedirect(s, Routes.login), Routes.home);
    expect(authRedirect(s, Routes.home), isNull);
  });

  test('admin lands on dashboard; non-admin cannot enter /admin', () {
    expect(authRedirect(AuthState.authenticated(u(role: UserRole.admin)), Routes.login),
        Routes.adminDashboard);
    expect(authRedirect(AuthState.authenticated(u()), Routes.adminDashboard), Routes.home);
    expect(authRedirect(AuthState.authenticated(u(role: UserRole.admin)), Routes.adminDashboard),
        isNull);
  });

  test('blocked accounts are held on the status page', () {
    for (final st in [AccountStatus.suspended, AccountStatus.banned, AccountStatus.deleted]) {
      final s = AuthState.authenticated(u(status: st));
      expect(authRedirect(s, Routes.home), Routes.accountStatus);
      expect(authRedirect(s, Routes.accountStatus), isNull);
    }
  });
}
