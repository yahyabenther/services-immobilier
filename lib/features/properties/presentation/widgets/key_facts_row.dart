import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../search/presentation/widgets/search_labels.dart';
import '../../domain/entities/property.dart';

/// Structured facts. A fact that is unknown is OMITTED: it is never shown as
/// "0" (spec §8.7). Studio is its own value, not "0 bedrooms".
class KeyFactsRow extends StatelessWidget {
  const KeyFactsRow({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final facts = <(IconData, String, String)>[
      (Icons.home_work_outlined, p.propertyType.label, 'Type'),
      if (p.isStudio)
        (Icons.bed_outlined, 'Studio', 'Bedrooms')
      else if (p.bedrooms != null)
        (Icons.bed_outlined, '${p.bedrooms}', 'Bedrooms'),
      if (p.bathrooms != null) (Icons.bathtub_outlined, '${p.bathrooms}', 'Bathrooms'),
      if (p.surface != null) (Icons.square_foot_rounded, '${p.surface!.round()} m²', 'Surface'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final f in facts) _Fact(icon: f.$1, value: f.$2, label: f.$3)],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    );
  }
}
