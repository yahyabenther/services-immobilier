import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Bubble with the number of listings grouped at this spot.
class PropertyClusterMarker extends StatelessWidget {
  const PropertyClusterMarker({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$count properties. Double tap to zoom in.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.92),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
