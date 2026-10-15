import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/amenity.dart';

/// Amenity ids are stored normalised; labels are resolved here. Unknown ids
/// are ignored instead of being shown as raw strings.
class AmenitiesSection extends StatelessWidget {
  const AmenitiesSection({super.key, required this.amenityIds});

  final List<String> amenityIds;

  @override
  Widget build(BuildContext context) {
    final amenities = <Amenity>{
      for (final id in amenityIds)
        if (Amenity.tryParse(id) case final a?) a,
    };
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final a in amenities)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
            const SizedBox(width: 5),
            Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
          ]),
        ),
    ]);
  }
}
