import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../domain/entities/property.dart';

class KeyFactsRow extends StatelessWidget {
  const KeyFactsRow({super.key, required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Row(
      children: [
        Expanded(
          child: _Fact(
            Icons.bed_outlined,
            p.bedrooms == 0 ? 'Studio' : 'S+${p.bedrooms}',
            'Chambres',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Fact(Icons.bathtub_outlined, '${p.bathrooms}', 'Salles de bain'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Fact(
            Icons.square_foot_rounded,
            '${p.surface.round()} m²',
            'Surface',
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: C.secondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: C.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: C.muted)),
        ],
      ),
    );
  }
}