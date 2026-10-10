import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../domain/entities/property_summary.dart';
import '../../domain/entities/search_enums.dart';
import 'search_labels.dart';

String formatPrice(double v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

class PropertyResultCard extends StatelessWidget {
  const PropertyResultCard({super.key, required this.property, this.onTap});

  final PropertySummary property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final isRent = p.transactionType == TransactionType.rent;
    final location = [if (p.area != null) p.area, p.city, p.governorate]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: p.imageUrls.isEmpty
                  ? const _ImagePlaceholder()
                  : Image.network(
                      p.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatPrice(p.price)} TND${isRent ? ' / mois' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: C.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: C.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.propertyType.label} • $location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: C.muted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Info(Icons.bed_outlined,
                          p.bedrooms == 0 ? 'Studio' : 'S+${p.bedrooms}'),
                      const SizedBox(width: 14),
                      _Info(Icons.bathtub_outlined, '${p.bathrooms}'),
                      const SizedBox(width: 14),
                      _Info(Icons.square_foot_rounded, '${p.surface.round()} m²'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: C.secondary),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: C.text)),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF1F5),
      alignment: Alignment.center,
      child: const Icon(Icons.home_work_outlined, size: 36, color: C.muted),
    );
  }
}