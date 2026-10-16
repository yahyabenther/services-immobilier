import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/property_image.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../search/presentation/widgets/search_labels.dart';

/// Compact summary between a marker and the full Property Details page (spec §12).
/// Never reproduces the details page: only price, title, place, a few facts.
class SelectedPropertyPreview extends StatelessWidget {
  const SelectedPropertyPreview({super.key, required this.property, required this.onOpen, required this.onClose});

  final Property property;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final facts = <(IconData, String)>[
      if (p.isStudio) (Icons.bed_outlined, 'Studio') else if (p.bedrooms != null) (Icons.bed_outlined, '${p.bedrooms}'),
      if (p.bathrooms != null) (Icons.bathtub_outlined, '${p.bathrooms}'),
      if (p.surface != null) (Icons.square_foot_rounded, '${p.surface!.round()} m²'),
    ];
    final tx = p.transactionType == TransactionType.rent ? 'For rent' : 'For sale';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(width: 104, height: 92, child: PropertyImage(url: p.mainImage, size: PropertyImageSize.thumb)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        PriceFormatter.format(p.price, p.currency, p.transactionType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      Text(p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(p.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('$tx · ${p.propertyType.label}',
                          style: const TextStyle(fontSize: 12, color: AppColors.text)),
                      if (facts.isNotEmpty || p.isVerified) ...[
                        const SizedBox(height: 4),
                        Wrap(spacing: 10, children: [
                          if (p.isVerified)
                            const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                              SizedBox(width: 2),
                              Text('Verified', style: TextStyle(fontSize: 12, color: AppColors.success)),
                            ]),
                          for (final f in facts)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(f.$1, size: 14, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(f.$2, style: const TextStyle(fontSize: 12, color: AppColors.text)),
                            ]),
                        ]),
                      ],
                    ]),
                  ),
                ]),
              ),
            ),
            IconButton(tooltip: 'Close preview', onPressed: onClose, icon: const Icon(Icons.close, size: 20)),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onOpen, child: const Text('View details')),
            ),
          ),
        ]),
      ),
    );
  }
}
