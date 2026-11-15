import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/property_image.dart';
import '../../../properties/domain/entities/property.dart';

const _cardShadow = [BoxShadow(color: Color(0x140B1F4B), blurRadius: 18, offset: Offset(0, 8))];

String _group(num value) {
  final digits = value.round().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('\u00A0');
    out.write(digits[i]);
  }
  return out.toString();
}

Widget _price(Property p, {required double size}) {
  final currency = p.currency.toUpperCase() == 'TND' ? 'DT' : p.currency;
  final rent = p.transactionType == TransactionType.rent;
  return Text.rich(
    TextSpan(children: [
      TextSpan(
          text: _group(p.price),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: AppColors.accent)),
      TextSpan(
          text: ' $currency',
          style: TextStyle(fontSize: size * 0.6, fontWeight: FontWeight.w700, color: AppColors.accent)),
      if (rent)
        TextSpan(
            text: ' / mois',
            style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w600, color: AppColors.muted)),
    ]),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Missing facts are omitted, never shown as 0.
List<(IconData, String)> _facts(Property p) => [
      if (p.isStudio) (Icons.bed_outlined, 'Studio') else if (p.bedrooms != null) (Icons.bed_outlined, '${p.bedrooms} ch'),
      if (p.bathrooms != null) (Icons.bathtub_outlined, '${p.bathrooms} sdb'),
      if (p.surface != null) (Icons.square_foot_rounded, '${p.surface!.round()} m²'),
    ];

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.filled = false});
  final String label;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.success),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: filled ? Colors.white : AppColors.text)),
        ]),
      );
}

/// Large "Biens en vedette" card.
class FeaturedPropertyCard extends StatelessWidget {
  const FeaturedPropertyCard({super.key, required this.property, required this.onTap, this.width = 290});

  final Property property;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final facts = _facts(p);

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: _cardShadow),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: onTap,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 150,
                  child: Stack(fit: StackFit.expand, children: [
                    PropertyImage(url: p.mainImage),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x99000000)],
                            stops: [0.5, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Wrap(spacing: 6, runSpacing: 6, children: [
                        if (p.isVerified) const _Chip(label: 'Vérifié', icon: Icons.verified_rounded),
                        if (p.isNewBuild) const _Chip(label: 'Neuf'),
                        _Chip(label: p.transactionType == TransactionType.rent ? 'Location' : 'Vente', filled: true),
                      ]),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(p.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    _price(p, size: 22),
                    const SizedBox(height: 3),
                    Text(p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FB), borderRadius: BorderRadius.circular(12)),
                        child: Wrap(spacing: 16, runSpacing: 6, children: [
                          for (final f in facts)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(f.$1, size: 16, color: AppColors.muted),
                              const SizedBox(width: 5),
                              Text(f.$2,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                            ]),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal card for vertical lists.
class PropertyRowCard extends StatelessWidget {
  const PropertyRowCard({super.key, required this.property, required this.onTap});

  final Property property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final facts = _facts(p);
    final tag = p.isNewBuild ? 'Nouveau' : (p.isVerified ? 'Vérifié' : null);

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: _cardShadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 88,
                    height: 92,
                    child: Stack(fit: StackFit.expand, children: [
                      PropertyImage(url: p.mainImage),
                      if (tag != null)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(8)),
                            child: Text(tag,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    _price(p, size: 18),
                    const SizedBox(height: 2),
                    Text(p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
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
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 10, runSpacing: 4, children: [
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
        ),
      ),
    );
  }
}
