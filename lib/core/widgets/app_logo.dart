import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.light = false, this.size = 56, this.showTagline = true});

  /// `true` on dark backgrounds (welcome screen).
  final bool light;
  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final immo = light ? Colors.white : AppColors.navy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.home_rounded, size: size, color: light ? Colors.white : AppColors.primary),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Immo', style: TextStyle(color: immo)),
            const TextSpan(text: 'Find', style: TextStyle(color: AppColors.primary)),
          ]),
          style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w800),
        ),
        if (showTagline)
          Text(
            'Find Your Next Home',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: light ? Colors.white70 : AppColors.muted,
            ),
          ),
      ],
    );
  }
}
