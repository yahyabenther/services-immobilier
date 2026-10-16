import '../domain/entities/auth_user.dart';

/// Central authentication state (spec §24).
sealed class AuthState {
  const AuthState();

  const factory AuthState.initializing() = AuthInitializing;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.authenticating() = AuthAuthenticating;
  const factory AuthState.authenticated(AuthUser user) = AuthAuthenticated;
  const factory AuthState.emailVerificationRequired(AuthUser user) = AuthEmailVerificationRequired;
  const factory AuthState.error(String message) = AuthError;
}

class AuthInitializing extends AuthState {
  const AuthInitializing();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthEmailVerificationRequired extends AuthState {
  const AuthEmailVerificationRequired(this.user);
  final AuthUser user;
}

/// A failed sign-in / sign-up attempt. The user is still signed out.
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
