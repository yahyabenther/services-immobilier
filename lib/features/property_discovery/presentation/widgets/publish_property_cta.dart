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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Have a property to sell or rent?',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Reach thousands of buyers and renters.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => context.push(Routes.publish),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
          child: const Text('Publish'),
        ),
      ]),
    );
  }
}
