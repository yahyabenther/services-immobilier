import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/providers/auth_provider.dart';

/// First name for the greeting, or null (generic greeting). Never hardcoded.
String? greetingName(AuthUser? user) {
  final name = user?.name?.trim();
  if (name == null || name.isEmpty) return null;
  return name.split(RegExp(r'\s+')).first;
}

String _initials(AuthUser? user) {
  final source = (user?.name?.trim().isNotEmpty ?? false) ? user!.name!.trim() : (user?.email ?? '');
  return source.isEmpty ? '?' : String.fromCharCode(source.runes.first).toUpperCase();
}

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = greetingName(user);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('DARNA',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.navy)),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: name == null
                  ? const SizedBox.shrink()
                  : Text('Bonjour, $name 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ),
          ),
        ),
        if (user == null)
          // Guest: browsing is free, the account is only needed to go further.
          Semantics(
            button: true,
            label: 'Se connecter',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push(Routes.login),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Connexion',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          )
        else
          Semantics(
            button: true,
            label: 'Ouvrir le profil',
            child: InkResponse(
              onTap: () => context.go(Routes.profile),
              radius: 26,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy,
                child: Text(_initials(user),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      const Text("Trouvez votre lieu d'exception.",
          style: TextStyle(fontSize: 24, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.navy)),
      const SizedBox(height: 3),
      const Text("L'immobilier de prestige et de caractère en Tunisie.",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
    ]);
  }
}
