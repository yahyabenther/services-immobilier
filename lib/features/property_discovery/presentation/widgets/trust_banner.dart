import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Static trust strip (no data behind it).
class TrustBanner extends StatelessWidget {
  const TrustBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
          child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Biens vérifiés en Tunisie',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.workspace_premium_outlined, size: 16, color: AppColors.accent),
        const SizedBox(width: 4),
        const Text('Garantie DARNA',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
      ]),
    );
  }
}
