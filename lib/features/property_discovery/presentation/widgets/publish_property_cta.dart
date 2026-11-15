import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Shown only when [canPublishProperty] allows it (UX only — Module 08 and the
/// Firestore rules enforce the real permission).
class PublishPropertyCta extends StatelessWidget {
  const PublishPropertyCta({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ESPACE PROPRIÉTAIRES',
            style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        const Text('Vous avez un bien à vendre ou à louer ?',
            style: TextStyle(color: Colors.white, fontSize: 18, height: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text("Touchez des milliers d'acheteurs et de locataires.",
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push(Routes.publish),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          icon: const Icon(Icons.add_home_work_outlined, size: 20),
          label: const Text('Publier un bien'),
        ),
      ]),
    );
  }
}
