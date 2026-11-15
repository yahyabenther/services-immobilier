import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/providers/auth_state.dart';
import 'routes.dart';

/// true  = a signed-out visitor first sees the welcome page (it has an
///         "Explorer les biens" button that enters the app without an account)
/// false = a signed-out visitor lands directly on the Accueil
const bool welcomeFirst = false;

/// Guests can browse without an account. The Favoris / Messages / Profil tabs
/// are reachable too (they show a "Se connecter" panel, see GuestGate).
/// Only publishing and admin ask for a login.
bool _guestCanOpen(String location) =>
    Routes.publicRoutes.contains(location) ||
    location == Routes.home ||
    location == Routes.search ||
    location == Routes.map ||
    location == Routes.favorites ||
    location == Routes.messages ||
    location == Routes.profile ||
    location.startsWith('/property/');

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
      if (location == Routes.splash) return welcomeFirst ? Routes.welcome : Routes.home;
      return _guestCanOpen(location) ? null : Routes.login;

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
