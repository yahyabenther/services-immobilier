import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_colors.dart';

/// Shows [child] to signed-in users. A guest sees an in-place panel with
/// Connexion / Créer un compte, so the bottom navigation stays usable and the
/// visitor can always get back to the Accueil.
class GuestGate extends ConsumerWidget {
  const GuestGate({
    super.key,
    required this.child,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
  });

  const GuestGate.favorites({super.key, required this.child})
      : title = 'Vos favoris',
        message = 'Connectez-vous pour enregistrer et retrouver vos biens préférés.',
        icon = Icons.favorite_border_rounded;

  const GuestGate.messages({super.key, required this.child})
      : title = 'Vos messages',
        message = 'Connectez-vous pour échanger avec les annonceurs.',
        icon = Icons.chat_bubble_outline_rounded;

  const GuestGate.profile({super.key, required this.child})
      : title = 'Votre profil',
        message = 'Connectez-vous ou créez un compte pour gérer votre profil.',
        icon = Icons.person_outline_rounded;

  final Widget child;
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserProvider) != null) return child;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
                      child: Icon(icon, size: 32, color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push(Routes.login),
                    child: const Text('Se connecter'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.push(Routes.register),
                    child: const Text('Créer un compte'),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => context.go(Routes.home),
                    child: const Text("Retour à l'accueil"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
