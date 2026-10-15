import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class OwnerCard extends StatelessWidget {
  const OwnerCard({super.key, required this.name, required this.role});

  final String name;
  final String role; // owner | agent | agency

  String get _roleLabel => switch (role) {
        'agent' => 'Agent immobilier',
        'agency' => 'Agence immobilière',
        _ => 'Propriétaire',
      };

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: C.navy,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _roleLabel,
                  style: const TextStyle(fontSize: 11, color: C.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}