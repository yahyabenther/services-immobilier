import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../providers/property_discovery_providers.dart';

class TransactionShortcuts extends ConsumerWidget {
  const TransactionShortcuts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(TransactionType type) => context.go(
          Routes.searchWith(transactionType: type, location: ref.read(selectedLocationProvider)),
        );

    return Row(children: [
      Expanded(
        child: _Tile(
          icon: Icons.home_rounded,
          title: 'Buy',
          subtitle: 'Find your dream home',
          filled: true,
          onTap: () => open(TransactionType.buy),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _Tile(
          icon: Icons.key_rounded,
          title: 'Rent',
          subtitle: 'Flexible. Easy. Fast.',
          filled: false,
          onTap: () => open(TransactionType.rent),
        ),
      ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.text;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: filled ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(minHeight: 104),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: filled ? null : Border.all(color: AppColors.line),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: filled ? Colors.white : AppColors.primary, size: 28),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: filled ? Colors.white70 : AppColors.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}
