import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../properties/domain/entities/property.dart';

/// Pin for ONE listing. The tip of the pin is the bottom-centre of the widget.
/// Appearance says nothing about verification (spec §10.4): that lives in the preview.
class PropertyMarkerPin extends StatelessWidget {
  const PropertyMarkerPin({super.key, required this.property, required this.selected, required this.onTap});

  final Property property;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Semantics(
      button: true,
      selected: selected,
      label: '${p.title}, ${PriceFormatter.format(p.price, p.currency, p.transactionType)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Icon(
            Icons.location_on,
            size: selected ? 54 : 42,
            color: selected ? AppColors.navy : AppColors.primary,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black38)],
          ),
        ),
      ),
    );
  }
}
