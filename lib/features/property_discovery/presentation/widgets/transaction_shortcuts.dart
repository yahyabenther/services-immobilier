import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../properties/domain/entities/property.dart';

/// Acheter / Louer pill toggle. The chosen type is passed on to Search.
class TransactionToggle extends StatelessWidget {
  const TransactionToggle({super.key, required this.value, required this.onChanged});

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: _Segment(
            label: 'Acheter',
            selected: value == TransactionType.buy,
            onTap: () => onChanged(TransactionType.buy),
          ),
        ),
        Expanded(
          child: _Segment(
            label: 'Louer',
            selected: value == TransactionType.rent,
            onTap: () => onChanged(TransactionType.rent),
          ),
        ),
      ]),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.muted)),
          ),
        ),
      ),
    );
  }
}
