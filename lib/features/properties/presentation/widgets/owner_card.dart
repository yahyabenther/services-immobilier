import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Public advertiser summary: display name + role label ONLY. No phone, no
/// email, nothing read from the private user profile (spec §8.9).
class OwnerCard extends StatelessWidget {
  const OwnerCard({super.key, required this.name, this.role});

  final String name;
  final String? role;

  String get _roleLabel => switch (role) {
        'agent' => 'Real-estate agent',
        'agency' => 'Real-estate agency',
        _ => 'Owner',
      };

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.navy,
          child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 2),
            Text(_roleLabel, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ]),
    );
  }
}
