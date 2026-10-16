import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/auth_failure.dart';
import 'package:team_app/features/auth/providers/auth_provider.dart';
import 'package:team_app/features/auth/providers/auth_state.dart';

import 'fake_auth_repository.dart';

ProviderContainer make(FakeAuthRepository repo) {
  final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('starts initializing, then unauthenticated after first auth event', () async {
    final c = make(FakeAuthRepository());
    expect(c.read(authControllerProvider), isA<AuthInitializing>());
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('successful login -> authenticated', () async {
    final c = make(FakeAuthRepository());
    await Future<void>.delayed(Duration.zero);
    await c.read(authControllerProvider.notifier).login('a@b.co', 'Passw0rd');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authControllerProvider), isA<AuthAuthenticated>());
  });

  test('failed login -> friendly error, no raw exception', () async {
    final c = make(FakeAuthRepository(failLoginWith: const AuthFailure(AuthFailureType.invalidCredentials)));
    await Future<void>.delayed(Duration.zero);
    await c.read(authControllerProvider.notifier).login('a@b.co', 'bad');
    final s = c.read(authControllerProvider);
    expect(s, isA<AuthError>());
    expect((s as AuthError).message, 'The email or password is incorrect.');
  });

  test('unverified account -> emailVerificationRequired', () async {
    final repo = FakeAuthRepository();
    final c = make(repo);
    await Future<void>.delayed(Duration.zero);
    await c.read(authControllerProvider.notifier).register(
        name: 'Yahya', email: 'a@b.co', phone: '+21622123456', password: 'Passw0rd');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authControllerProvider), isA<AuthEmailVerificationRequired>());
  });

  test('logout -> unauthenticated', () async {
    final c = make(FakeAuthRepository());
    await Future<void>.delayed(Duration.zero);
    final n = c.read(authControllerProvider.notifier);
    await n.login('a@b.co', 'Passw0rd');
    await n.logout();
    expect(c.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('duplicate submissions are ignored while authenticating', () async {
    final repo = FakeAuthRepository();
    final c = make(repo);
    await Future<void>.delayed(Duration.zero);
    final n = c.read(authControllerProvider.notifier);
    final f1 = n.login('a@b.co', 'Passw0rd');
    final f2 = n.login('a@b.co', 'Passw0rd');
    await Future.wait([f1, f2]);
    expect(repo.loginCalls, 1);
  });
}
