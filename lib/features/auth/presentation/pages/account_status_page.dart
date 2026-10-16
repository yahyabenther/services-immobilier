import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_user.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_layout.dart';

/// Shown for suspended / banned / deleted accounts (spec §37).
class AccountStatusPage extends ConsumerWidget {
  const AccountStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(currentUserProvider)?.status;
    final (title, text) = switch (status) {
      AccountStatus.suspended => (
          'Account Suspended',
          'Your account is currently suspended. Please contact support for more information.'
        ),
      AccountStatus.banned => (
          'Access Denied',
          'This account is no longer allowed to access ImmoFind.'
        ),
      _ => ('Account Unavailable', 'This account is no longer available.'),
    };

    return AuthScaffold(
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.block_rounded, size: 88, color: AppColors.error),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 32),
          AuthButton(
            label: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
