import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/property_image.dart';
import '../../../properties/domain/entities/property.dart';

/// Reusable property card (Home lists now; Search / Favorites later).
/// Never shows invented data: missing facts are simply omitted.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.width = 250,
    this.distanceKm,
  });

  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final double width;

  /// Shown only when a real reference location exists (search "Closest").
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final facts = <(IconData, String)>[
      if (p.isStudio) (Icons.bed_outlined, 'Studio') else if (p.bedrooms != null) (Icons.bed_outlined, '${p.bedrooms}'),
      if (p.bathrooms != null) (Icons.bathtub_outlined, '${p.bathrooms}'),
      if (p.surface != null) (Icons.square_foot_rounded, '${p.surface!.round()} m²'),
    ];

    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 1.5,
        shadowColor: Colors.black26,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PropertyImage(url: p.mainImage),
                    if (p.isVerified)
                      const Positioned(left: 8, top: 8, child: _Badge(icon: Icons.verified_rounded, label: 'Verified')),
                    if (p.isNewBuild)
                      Positioned(
                        left: 8,
                        top: p.isVerified ? 36 : 8,
                        child: const _Badge(label: 'New build'),
                      ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _Badge(
                        label: p.transactionType == TransactionType.rent ? 'For rent' : 'For sale',
                        dark: true,
                      ),
                    ),
                    if (onFavoriteTap != null)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Semantics(
                          button: true,
                          label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                          child: IconButton(
                            onPressed: onFavoriteTap,
                            style: IconButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(40, 40)),
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isFavorite ? AppColors.error : AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      PriceFormatter.format(p.price, p.currency, p.transactionType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                            distanceKm == null ? p.locationLabel : '${p.locationLabel} · ${_km(distanceKm!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                    ]),
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          for (final f in facts)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(f.$1, size: 15, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(f.$2, style: const TextStyle(fontSize: 12, color: AppColors.text)),
                            ]),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon, this.dark = false});
  final String label;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: dark ? AppColors.navy.withValues(alpha: 0.82) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.success),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: dark ? Colors.white : AppColors.text)),
        ]),
      );
}

String _km(double km) => km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
