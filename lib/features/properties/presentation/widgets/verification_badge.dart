import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property.dart';

/// Shown ONLY for an approved verification (spec §8.10). Every other status
/// (not submitted, pending, rejected, expired) renders nothing.
/// Icon + text, never colour alone.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    if (status != VerificationStatus.approved) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFE6F6EE), borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_rounded, size: 15, color: AppColors.success),
        SizedBox(width: 5),
        Text('Verified listing',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
      ]),
    );
  }
}
