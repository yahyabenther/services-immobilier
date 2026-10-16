import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/providers/auth_state.dart';
import 'routes.dart';

/// Pure redirect logic for go_router (spec §31). Returns the location to
/// redirect to, or null to allow [location]. Unit-tested.
String? authRedirect(AuthState state, String location) {
  // The reset link must work whatever the session looks like.
  if (location == Routes.resetPassword) return null;

  String? go(String target) => location == target ? null : target;

  switch (state) {
    case AuthInitializing():
      return go(Routes.splash);

    case AuthUnauthenticated() || AuthAuthenticating() || AuthError():
      return Routes.publicRoutes.contains(location) ? null : Routes.welcome;

    case AuthEmailVerificationRequired(:final user):
      if (user.isBlocked) return go(Routes.accountStatus);
      return go(Routes.verifyEmail);

    case AuthAuthenticated(:final user):
      if (user.isBlocked) return go(Routes.accountStatus);

      const authOnly = {
        Routes.splash,
        Routes.welcome,
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
        Routes.verifyEmail,
        Routes.accountStatus,
      };
      if (authOnly.contains(location)) return homeFor(user);

      if (location.startsWith('/admin') && !user.isAdmin) return Routes.home;
      return null;
  }
}

String homeFor(AuthUser user) => user.isAdmin ? Routes.adminDashboard : Routes.home;
