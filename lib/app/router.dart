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
import 'placeholder_pages.dart';
import 'router_guard.dart';
import 'routes.dart';
import '../pages/main/main_shell.dart';

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
      // Placeholders until the next modules exist.
      GoRoute(path: Routes.home, builder: (_, __) => const MainShell()),
      GoRoute(path: Routes.adminDashboard, builder: (_, __) => const AdminPlaceholderPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
