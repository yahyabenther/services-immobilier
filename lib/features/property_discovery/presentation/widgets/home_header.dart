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

    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name == null ? 'Hello 👋' : 'Hello, $name 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 2),
          const Text('Find your perfect property in Tunisia', style: TextStyle(color: AppColors.muted)),
        ]),
      ),
      // No notification bell: it appears only once Module 12 exists.
      Semantics(
        button: true,
        label: 'Open profile',
        child: InkResponse(
          onTap: () => context.go(Routes.profile),
          radius: 28,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(_initials(user),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
        ),
      ),
    ]);
  }
}
