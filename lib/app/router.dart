import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/account_status_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/profile/presentation/profile_page.dart'; // Module 02
import '../features/properties/presentation/property_details_stub_page.dart'; // replaced by Module 05
import '../features/property_discovery/presentation/screens/home_discovery_screen.dart';
import '../features/search/presentation/pages/search_page.dart'; // Module 04
import '../features/favorites/presentation/pages/favorites_page.dart'; // Module 07
import 'app_shell.dart';
import 'placeholder_pages.dart';
import 'router_guard.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      // ---- Module 01 -------------------------------------------------------
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomePage()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: Routes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, state) => ResetPasswordPage(code: state.uri.queryParameters['oobCode']),
      ),
      GoRoute(path: Routes.verifyEmail, builder: (_, __) => const VerifyEmailPage()),
      GoRoute(path: Routes.accountStatus, builder: (_, __) => const AccountStatusPage()),
      GoRoute(path: Routes.adminDashboard, builder: (_, __) => const AdminPlaceholderPage()),

      // ---- Main app: bottom navigation ------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, __) => const HomeDiscoveryScreen()), // Module 03
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.search,
              builder: (_, state) => SearchPage(params: state.uri.queryParameters),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.map,
              builder: (_, state) =>
                  ComingSoonPage(title: 'Map', module: 'Module 06', params: state.uri.queryParameters),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.favorites,
              builder: (_, __) => const FavoritesPage(), // Module 07
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, builder: (_, __) => const UserProfilePage()), // Module 02
          ]),
        ],
      ),

      // ---- Full-screen pages pushed on top of the shell --------------------
      GoRoute(
        path: '/property/:id',
        builder: (_, state) => PropertyDetailsStubPage(propertyId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.publish,
        builder: (_, __) => const ComingSoonPage(title: 'Publish property', module: 'Module 08'),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
