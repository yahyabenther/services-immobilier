import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../search/domain/entities/search_enums.dart';
import '../../../search/presentation/widgets/search_labels.dart';

class AmenitiesSection extends StatelessWidget {
  const AmenitiesSection({super.key, required this.amenities});
  final Set<Amenity> amenities;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in amenities)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, size: 15, color: C.secondary),
                const SizedBox(width: 5),
                Text(
                  a.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}