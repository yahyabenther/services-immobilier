import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/property_image.dart';
import '../../../properties/presentation/widgets/verification_badge.dart';
import '../../domain/entities/agent_profile.dart';

/// Circular photo / logo with an initial fallback.
class AgentAvatar extends StatelessWidget {
  const AgentAvatar({super.key, required this.name, this.imageUrl, this.radius = 32});

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first).toUpperCase();
    final url = imageUrl?.trim();
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: Text(initial,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: radius * 0.7)),
    );
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: PropertyImage(url: url, size: PropertyImageSize.thumb),
      ),
    );
  }
}

/// Profile header (spec §5.3): photo, name, verification badge, kind, city.
class AgentHeader extends StatelessWidget {
  const AgentHeader({super.key, required this.profile});

  final AgentProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final meta = <String>[
      p.isAgency ? 'Real-estate agency' : 'Real-estate agent',
      p.city,
      if (p.yearsOfExperience != null && p.yearsOfExperience! > 0) '${p.yearsOfExperience} yrs experience',
    ];
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      AgentAvatar(name: p.displayName, imageUrl: p.profileImageUrl, radius: 36),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
          if (p.isAgency && p.professionalName.isNotEmpty)
            Text(p.professionalName, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(meta.join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
          // Only an APPROVED verification shows the badge (spec §5.3).
          VerificationBadge(status: p.verificationStatus, label: 'Verified professional'),
        ]),
      ),
    ]);
  }
}
