import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  /// verified | pending | none
  final String status;

  @override
  Widget build(BuildContext context) {
    if (status != 'verified' && status != 'pending') {
      return const SizedBox.shrink();
    }
    final verified = status == 'verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: verified ? const Color(0xFFEAF4FA) : const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            size: 15,
            color: verified ? C.secondary : C.muted,
          ),
          const SizedBox(width: 5),
          Text(
            verified ? 'ImmoFind Certifié' : 'Vérification en cours',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: verified ? C.secondary : C.muted,
            ),
          ),
        ],
      ),
    );
  }
}